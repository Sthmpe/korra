import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0"; 

// =======================================================================
// 1. GLOBAL CONFIG & CORS
// =======================================================================
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-timestamp, x-korra-signature', 
};

const KORRA_SECRET = Deno.env.get('KORRA_HMAC_SECRET') || "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";
const PAYSTACK_SECRET = Deno.env.get('PAYSTACK_SECRET_KEY')!;
const PAYSTACK_BASE_URL = 'https://api.paystack.co';

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

// =======================================================================
// 🧠 HELPER: DYNAMIC FUZZY NAME MATCHER
// =======================================================================
// This strips out generic words and checks if the UNIQUE words from Monnify 
// exist anywhere in the Paystack name.
const doNamesMatch = (name1: string, name2: string): boolean => {
    const normalizeAndSplit = (n: string) => 
        n.toLowerCase().replace(/[^a-z0-9\s]/g, ' ').split(/\s+/).filter(w => w.length > 2);

    const genericWords = ['bank', 'limited', 'ltd', 'plc', 'microfinance', 'mfb', 'the', 'and'];
    
    const words1 = normalizeAndSplit(name1).filter(w => !genericWords.includes(w));
    const words2 = normalizeAndSplit(name2).filter(w => !genericWords.includes(w));

    // If any significant word matches, return true!
    return words1.some(w => words2.includes(w)) || words2.some(w => words1.includes(w));
};

serve(async (req) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

    try {
        if (req.method !== "POST") throw new Error("Only POST allowed");

        // --- HMAC & FIREBASE AUTH ---
        const clientTimestamp = req.headers.get('x-korra-timestamp');
        const clientSignature = req.headers.get('x-korra-signature');
        if (!clientTimestamp || !clientSignature) throw new Error("Unauthorized: Missing security signatures.");

        const now = Date.now();
        if (Math.abs(now - parseInt(clientTimestamp, 10)) > 120000) throw new Error("Unauthorized: Request expired.");

        const encoder = new TextEncoder();
        const key = await crypto.subtle.importKey("raw", encoder.encode(KORRA_SECRET), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
        const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(clientTimestamp));
        const expectedServerSignature = Array.from(new Uint8Array(signatureBuffer)).map(b => b.toString(16).padStart(2, '0')).join('');

        if (clientSignature !== expectedServerSignature) throw new Error("Unauthorized: Cryptographic signature mismatch.");
    
        const authHeader = req.headers.get('firebase-token');
        if (!authHeader || !authHeader.startsWith('Bearer ')) throw new Error("Unauthorized: Missing VIP pass.");
        await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
        
        // --- PAYLOAD ---
        if (!PAYSTACK_SECRET) throw new Error("Missing Paystack Secret Key");
        const { accountName, accountNumber, monnifyBankCode, monnifyBankName } = await req.json();
        if (!accountName || !accountNumber || !monnifyBankCode) throw new Error("Missing required payload data");

        console.log(`🏦 Incoming Monnify Bank: ${monnifyBankName} (Code: ${monnifyBankCode})`);

        // =======================================================================
        // 🚀 1. FETCH ALL PAYSTACK BANKS & LOG THEM
        // =======================================================================
        let paystackBanks: any[] = [];
        let hasNext = true;
        let fetchUrl = `${PAYSTACK_BASE_URL}/bank?country=nigeria&perPage=100&use_cursor=true`;

        while (hasNext) {
            const bankRes = await fetch(fetchUrl, { headers: { "Authorization": `Bearer ${PAYSTACK_SECRET}` } });
            const bankData = await bankRes.json();
            
            if (bankData.status && bankData.data) {
                paystackBanks.push(...bankData.data);
                if (bankData.meta && bankData.meta.next) {
                    fetchUrl = `${PAYSTACK_BASE_URL}/bank?country=nigeria&perPage=100&use_cursor=true&next=${bankData.meta.next}`;
                } else {
                    hasNext = false;
                }
            } else {
                hasNext = false;
            }
        }

        // 🚨 LOGGING AS REQUESTED: This prints the entire Paystack list to your Supabase Logs
        console.log(`📊 Fetched ${paystackBanks.length} banks from Paystack. Full List below:`);
        console.log(JSON.stringify(paystackBanks.map(b => ({ name: b.name, code: b.code })), null, 2));

        // =======================================================================
        // 🚀 2. THE DYNAMIC MATCHING LOGIC
        // =======================================================================
        let finalPaystackBankCode = null;

        // STRATEGY A: Check if code exists AND name matches
        const exactCodeMatch = paystackBanks.find(b => b.code === monnifyBankCode);
        
        if (exactCodeMatch && doNamesMatch(monnifyBankName, exactCodeMatch.name)) {
            finalPaystackBankCode = exactCodeMatch.code;
            console.log(`✅ Strategy A Success: Code matched and verified name -> ${exactCodeMatch.name}`);
        } 
        // STRATEGY B: Code failed or name verification failed. Do a fuzzy search on all names.
        else {
            console.log(`⚠️ Strategy A Failed. Attempting dynamic name matching...`);
            
            const fuzzyNameMatch = paystackBanks.find(b => doNamesMatch(monnifyBankName, b.name));

            if (fuzzyNameMatch) {
                finalPaystackBankCode = fuzzyNameMatch.code;
                console.log(`✅ Strategy B Success: Mapped "${monnifyBankName}" to Paystack's "${fuzzyNameMatch.name}" (New Code: ${fuzzyNameMatch.code})`);
            } else {
                throw new Error(`Could not dynamically map bank '${monnifyBankName}' to any Paystack bank.`);
            }
        }

        // =======================================================================
        // 🚀 3. CREATE PAYSTACK RECIPIENT
        // =======================================================================
        console.log(`👤 Creating Paystack Recipient for ${accountName} using code ${finalPaystackBankCode}...`);
        
        const recipientRes = await fetch(`${PAYSTACK_BASE_URL}/transferrecipient`, {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${PAYSTACK_SECRET}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                type: "nuban",
                name: accountName,
                account_number: accountNumber,
                bank_code: finalPaystackBankCode,
                currency: "NGN"
            })
        });

        const recipientData = await recipientRes.json();

        if (!recipientData.status) {
            console.error("❌ Paystack Recipient Error:", JSON.stringify(recipientData));
            throw new Error(recipientData.message || "Failed to create transfer recipient on Paystack.");
        }

        const recipientCode = recipientData.data.recipient_code;
        console.log(`🎉 SUCCESS: Recipient Code Generated -> ${recipientCode}`);

        return new Response(JSON.stringify({ 
            success: true, 
            recipientCode: recipientCode,
            mappedBankCode: finalPaystackBankCode
        }), {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

    } catch (error) {
        const msg = error instanceof Error ? error.message : String(error);
        console.error("🔥 Edge Function Error:", msg);
        
        return new Response(JSON.stringify({ success: false, message: msg }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    }
});