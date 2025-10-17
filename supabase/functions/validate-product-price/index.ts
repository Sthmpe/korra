// supabase/functions/validate_product_price/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const categoryRanges: Record<string, { min: number; max: number }> = {
  "mens clothing": { min: 2000, max: 50000 },
  "womens clothing": { min: 2000, max: 60000 },
  "kids & babyclothing": { min: 1000, max: 30000 },
  "shoes & footwear": { min: 3000, max: 60000 },
  "bags & handbags": { min: 2000, max: 50000 },
  "jewelry & watches": { min: 1000, max: 80000 },
  "wigs & humanhair": { min: 5000, max: 100000 },
  "accessories": { min: 500, max: 20000 },
  "undergarments & sleepwear": { min: 1000, max: 20000 },
  "sportswear fitness": { min: 2000, max: 40000 },
  "perfumes": { min: 2000, max: 50000 },
  "deodorants": { min: 1000, max: 10000 },
  "lotions": { min: 1000, max: 20000 },
  "creams": { min: 1000, max: 20000 },
  "skincare": { min: 1500, max: 30000 },
  "makeup & beauty": { min: 1000, max: 30000 },
  "haircare products": { min: 1000, max: 20000 },
  "grooming & personal care": { min: 1000, max: 20000 },
  "gift items": { min: 2000, max: 30000 },
  "student backpacks": { min: 2000, max: 20000 },
  "stationery supplies": { min: 500, max: 10000 },
  "study lamps": { min: 2000, max: 20000 },
  "desk items": { min: 1000, max: 15000 },
  "hostel essentials": { min: 2000, max: 30000 },
  "laptops": { min: 50000, max: 100000 },
  "tablets": { min: 30000, max: 90000 },
  "phones": { min: 20000, max: 100000 },
  "smart devices": { min: 5000, max: 50000 },
  "phone accessories": { min: 1000, max: 20000 },
  "audio devices": { min: 5000, max: 50000 },
  "tvs": { min: 20000, max: 100000 },
  "monitors": { min: 20000, max: 80000 },
  "cameras": { min: 20000, max: 100000 },
  "gadgets": { min: 5000, max: 80000 },
  "powerbanks": { min: 2000, max: 20000 },
  "chargers": { min: 1000, max: 10000 },
  "generators": { min: 20000, max: 100000 },
  "solar panels": { min: 10000, max: 90000 },
  "inverters": { min: 20000, max: 100000 },
  "lamps": { min: 1000, max: 15000 },
  "lighting": { min: 2000, max: 30000 },
  "small appliances": { min: 5000, max: 50000 },
  "large appliances": { min: 20000, max: 100000 },
  "kitchenware": { min: 2000, max: 20000 },
  "beddings": { min: 5000, max: 40000 },
  "mattress": { min: 10000, max: 60000 },
  "furniture": { min: 10000, max: 80000 },
  "home decor": { min: 2000, max: 30000 },
  "tools machines": { min: 5000, max: 70000 },
  "sewing machines": { min: 10000, max: 60000 },
  "health supplements": { min: 2000, max: 30000 },
  "hygiene & sanitation": { min: 1000, max: 15000 },
  "packaged food": { min: 500, max: 20000 },
  "drinks & beverages": { min: 500, max: 15000 },
  "baby clothes": { min: 1000, max: 20000 },
  "baby accessories": { min: 1000, max: 15000 },
  "babycare": { min: 1000, max: 20000 },
  "diapers": { min: 2000, max: 20000 },
  "toys & games": { min: 1000, max: 20000 },
  "travel bags": { min: 2000, max: 40000 },
  "suitcases": { min: 5000, max: 50000 },
  "outdoor camping": { min: 5000, max: 50000 },
  "car accessories": { min: 2000, max: 40000 },
  "motorcycle accessories": { min: 2000, max: 40000 },
  "general electronics": { min: 5000, max: 100000 }
};

serve(async (req) => {
  try {
    const { category, price } = await req.json();

    if (!category || price == null) {
      return new Response(
        JSON.stringify({ success: false, valid: false }),
        { headers: { "Content-Type": "application/json" }, status: 400 }
      );
    }

    const range = categoryRanges[category];
    if (!range) {
      return new Response(
        JSON.stringify({ success: true, valid: false }),
        { headers: { "Content-Type": "application/json" }, status: 200 }
      );
    }

    const valid = price >= range.min && price <= range.max;

    return new Response(
      JSON.stringify({ success: true, valid }),
      { headers: { "Content-Type": "application/json" }, status: 200 }
    );
  } catch (_err) {
    return new Response(
      JSON.stringify({ success: false, valid: false }),
      { headers: { "Content-Type": "application/json" }, status: 500 }
    );
  }
});
