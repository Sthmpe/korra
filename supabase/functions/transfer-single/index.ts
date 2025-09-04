// This file is a Supabase Edge Function that handles single, synchronous transfers using the Monnify API.
// It is designed to be deployed to Supabase Edge Functions and uses the Deno runtime.

import { serve } from "https://deno.land/std/http/server.ts";

// Define the shape of the request body for type safety
interface TransferPayload {
  amount: number;
  reference: string;
  narration: string;
  destinationBankCode: string;
  destinationAccountNumber: string;
  currency: "NGN";
  sourceAccountNumber: string;
}

// Environment variables are securely managed by Supabase and available via Deno.env
const BASE_URL = Deno.env.get("MONNIFY_BASE_URL")!;
const API_KEY = Deno.env.get("MONNIFY_API_KEY")!;
const SECRET_KEY = Deno.env.get("MONNIFY_SECRET_KEY")!;

// Use a simple in-memory cache for the access token to avoid repeated authentication
let cachedToken: { value: string; exp: number } | null = null;

/**
 * Creates a consistent JSON response object for both success and error cases.
 * @param success - A boolean indicating the request's success status.
 * @param payload - The data or error message to include in the response body.
 * @param status - The HTTP status code.
 */
function createJsonResponse(
  success: boolean,
  payload: any,
  status: number,
): Response {
  return new Response(
    JSON.stringify({ success, ...(success ? { data: payload } : { error: payload }) }),
    { status, headers: { "Content-Type": "application/json" } },
  );
}

/**
 * Fetches and caches a Monnify access token using Basic Authentication.
 * This function will reuse a valid cached token to reduce API calls.
 */
async function getAccessToken(): Promise<string> {
  // Return the cached token if it's not expired
  if (cachedToken && cachedToken.exp > Date.now()) {
    return cachedToken.value;
  }

  const basic = btoa(`${API_KEY}:${SECRET_KEY}`);
  const res = await fetch(`${BASE_URL}/api/v1/auth/login`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/json",
    },
  });
  const data = await res.json();

  if (!data.requestSuccessful) {
    throw new Error("Failed to authenticate with Monnify.");
  }

  const token = data.responseBody.accessToken;
  // Cache the new token. We subtract a 5-second buffer to account for network latency.
  cachedToken = {
    value: token,
    exp: Date.now() + (data.responseBody.expiresIn * 1000 - 5000),
  };
  return token;
}

/**
 * Handles the single, synchronous transfer to a recipient's bank account.
 * It validates the request body, authenticates with Monnify, and makes the transfer request.
 */
async function transferSingle(body: TransferPayload): Promise<Response> {
  // Validate all required fields from the request body
  const requiredFields = [
    "amount",
    "reference",
    "narration",
    "destinationBankCode",
    "destinationAccountNumber",
    "currency",
    "sourceAccountNumber",
  ];
  const missingFields = requiredFields.filter((field) =>
    !body[field as keyof TransferPayload]
  );

  if (missingFields.length > 0) {
    return createJsonResponse(
      false,
      `Missing required fields: ${missingFields.join(", ")}`,
      400,
    );
  }

  try {
    const token = await getAccessToken();

    const res = await fetch(`${BASE_URL}/api/v2/disbursements/single`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    const data = await res.json();

    if (!data.requestSuccessful) {
      return createJsonResponse(
        false,
        data.responseMessage || "Monnify API transfer failed.",
        400,
      );
    }

    // Return the successful response from Monnify
    return createJsonResponse(true, data.responseBody, 200);
  } catch (e) {
    // Handle any errors during authentication or the fetch call
    return createJsonResponse(false, e.message, 500);
  }
}

// The main handler for the Supabase Edge Function
serve(async (req) => {
  // Only accept POST requests for this function
  if (req.method !== "POST") {
    return createJsonResponse(false, "Only POST requests are allowed.", 405);
  }

  try {
    const body: TransferPayload = await req.json();
    return await transferSingle(body);
  } catch (e) {
    // Handle cases where the request body is not valid JSON
    return createJsonResponse(false, "Invalid JSON in request body.", 400);
  }
});
