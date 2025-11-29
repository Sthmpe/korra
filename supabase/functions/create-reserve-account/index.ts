// supabase/functions/create-reserve-account/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { uid, email, firstName, lastName, bvn, nin } = await req.json()

    // 1. AUTHENTICATE (Basic Auth -> Access Token)
    const BASE_URL = Deno.env.get("MONNIFY_BASE_URL")
    const apiKey = Deno.env.get("MONNIFY_API_KEY")
    const secretKey = Deno.env.get("MONNIFY_SECRET_KEY")
    const contractCode = Deno.env.get("MONNIFY_CONTRACT_CODE")

    // Encode "API_KEY:SECRET_KEY" to Base64
    const base64Auth = btoa(`${apiKey}:${secretKey}`)

    const authResponse = await fetch(`${BASE_URL}/api/v1/auth/login`, {
      method: "POST",
      headers: { "Authorization": `Basic ${base64Auth}` }
    })

    const authData = await authResponse.json()
    if (!authData.requestSuccessful) {
      throw new Error("Monnify Auth Failed")
    }
    const accessToken = authData.responseBody.accessToken

    // 2. CREATE RESERVED ACCOUNT (Using verified V2 Body)
    const requestBody = {
      accountReference: uid, // Links to your user
      accountName: `Korra - ${firstName} ${lastName}`,
      currencyCode: "NGN",
      contractCode: contractCode,
      customerEmail: email,
      customerName: `${firstName} ${lastName}`,
      bvn: bvn,             // CORRECTED: 'bvn' not 'customerBvn'
      nin: nin,             // ADDED: Matches your example
      getAllAvailableBanks: false, // Gets Wema, Moniepoint, etc.
      preferredBanks: [
        "50515"
      ]
      // restrictPaymentSource: false // Optional: Defaults to false
    }

    const createResponse = await fetch(`${BASE_URL}/api/v2/bank-transfer/reserved-accounts`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(requestBody)
    })

    const responseJson = await createResponse.json()

    if (!responseJson.requestSuccessful) {
      console.error("Monnify Error:", responseJson)
      throw new Error(responseJson.responseMessage || "Failed to create account")
    }

    // 3. PARSE RESPONSE
    // Monnify returns an array of accounts. We usually pick index 0.
    const mainAccount = responseJson.responseBody.accounts[0]

    return new Response(JSON.stringify({
      success: true,
      data: {
        bankName: mainAccount.bankName,
        accountNumber: mainAccount.accountNumber,
        accountName: mainAccount.accountName,
        accountReference: responseJson.responseBody.accountReference,
        bankCode: mainAccount.bankCode
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})