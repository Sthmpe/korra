import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log("🚀 [START] Incoming Verification Request");

    // Parse Body
    const { type, payload } = await req.json()
    console.log(`📝 Request Type: ${type}`);
    console.log(`📦 Payload Data:`, JSON.stringify(payload)); // Be careful logging sensitive data in prod

    // 1. GET QOREID ACCESS TOKEN
    console.log("🔐 Requesting QoreID Access Token...");
    
    const clientId = Deno.env.get('QOREID_CLIENT_ID');
    // Log masked Client ID to ensure env var exists without leaking it
    console.log(`🔑 Client ID found: ${clientId ? 'YES (' + clientId.substring(0,4) + '...)' : 'NO'}`);

    const tokenResponse = await fetch('https://api.qoreid.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'text/plain' },
      body: JSON.stringify({
        clientId: clientId,
        secret: Deno.env.get('QOREID_SECRET'),
      }),
    })

    const tokenData = await tokenResponse.json()

    if (!tokenResponse.ok || !tokenData.accessToken) {
      console.error("❌ [AUTH FAIL] Token Response:", JSON.stringify(tokenData));
      throw new Error(`Identity Service Auth Failed: ${tokenData.message || tokenResponse.statusText}`)
    }

    console.log("✅ [AUTH SUCCESS] Access Token Received");
    const accessToken = tokenData.accessToken

    // 2. ROUTE REQUEST & DETERMINE VALIDATION LOGIC
    let apiUrl = ''
    let validationStrategy = 'data_only' 

    switch (type) {
      case 'cac':
        apiUrl = 'https://api.qoreid.com/v1/ng/identities/cac-basic'
        validationStrategy = 'cac_check'
        break

      case 'bvn_face':
        apiUrl = 'https://api.qoreid.com/v1/ng/identities/face-verification/bvn'
        validationStrategy = 'face_match'
        break

      case 'nin_face':
        apiUrl = 'https://api.qoreid.com/v1/ng/identities/face-verification/nin'
        validationStrategy = 'face_match'
        break

      default:
        console.error(`❌ [INVALID TYPE] Unknown type received: ${type}`);
        throw new Error(`Verification type '${type}' is not supported`)
    }

    console.log(`📡 Calling QoreID Endpoint: ${apiUrl}`);

    // 3. CALL QOREID
    const apiResponse = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
      },
      body: JSON.stringify(payload)
    })

    const data = await apiResponse.json()

    // 4. HANDLE API ERRORS
    if (!apiResponse.ok) {
        console.error("❌ [API ERROR] QoreID returned error:", JSON.stringify(data));
        throw new Error(data.message || `${type.toUpperCase()} verification failed`)
    }

    console.log("📥 [API SUCCESS] QoreID Response received. Validating status...");
    console.log("🔍 Raw Response Summary:", JSON.stringify(data.summary));
    console.log("🔍 Raw Response Status:", JSON.stringify(data.status));

    // 5. VALIDATE STATUS DYNAMICALLY
    let isVerified = false;
    let reason = 'Identity verification failed.';

    if (validationStrategy === 'cac_check') {
        // CAC Logic
        isVerified = data?.summary?.cac_check === 'verified' || data?.status?.status === 'verified';
        reason = 'CAC Registration Number not found.';
        console.log(`🧐 Strategy: CAC Check. Result: ${isVerified}`);
    
    } else if (validationStrategy === 'face_match') {
        // Face Logic
        const faceCheck = data?.summary?.face_verification_check;
        const statusCheck = data?.status?.status === 'verified';
        
        console.log(`🧐 Strategy: Face Match. Match Score: ${faceCheck?.match_score}`);
        
        // Ensure face match is true AND status is verified
        if (faceCheck?.match === true && statusCheck) {
            isVerified = true;
        } else {
            reason = 'Face did not match ID photo, or ID is invalid.';
        }
    }

    if (!isVerified) {
        console.warn("⚠️ [VALIDATION FAIL] Logic check failed. Sending error to client.");
        throw new Error(reason);
    }

    console.log("✅ [SUCCESS] Verification Complete.");

    // 6. SUCCESS
    return new Response(JSON.stringify({ 
        success: true, 
        data: data 
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    // CATCH-ALL LOGGING
    console.error("🔥 [CRITICAL ERROR]:", error.message);
    
    return new Response(JSON.stringify({ 
        error: error.message,
        success: false
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})