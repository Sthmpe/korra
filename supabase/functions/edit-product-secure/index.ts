import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// --- 1. FIREBASE INIT ---
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}
const db = admin.firestore();

// --- 2. MAIN LOGIC ---
serve(async (req) => {
  try {
    const { vendorId, productCode, updateData } = await req.json();

    if (!vendorId || !productCode || !updateData) {
      return new Response(JSON.stringify({ error: "Missing data" }), { status: 400 });
    }

    // 1. Validate Inputs
    const newPrice = Number(updateData.price);
    const newStock = Number(updateData.availableStock);

    if (newPrice > 100000) {
      return new Response(JSON.stringify({ success: false, error: "Price cannot exceed ₦100,000" }), { status: 400 });
    }

    // 2. RUN TRANSACTION
    const result = await db.runTransaction(async (t) => {
      // References
      const statsRef = db.collection('vendor_stats').doc(vendorId);
      const productQuery = db.collection('products')
                             .where('vendorId', '==', vendorId)
                             .where('code', '==', productCode)
                             .limit(1);
      
      const productSnap = await t.get(productQuery);
      if (productSnap.empty) throw "Product not found";
      
      const productDoc = productSnap.docs[0];
      const oldData = productDoc.data();
      const statsDoc = await t.get(statsRef);

      if (!statsDoc.exists) throw "Vendor stats not found";
      const stats = statsDoc.data();

      // 3. Calculate Financial Delta
      const oldTotal = (Number(oldData.price) || 0) * (Number(oldData.availableStock) || 0);
      const newTotal = newPrice * newStock;
      const difference = newTotal - oldTotal; // Positive if value increased

      // 4. Check Limit (Only if value increased)
      if (difference > 0) {
        const maxLimit = Number(stats.maxReservationLimit) || 250000.0;
        const currentUsed = (Number(stats.totalLiability) || 0) + (Number(stats.currentActivePlanValue) || 0);
        const available = maxLimit - currentUsed;

        if (difference > available) {
          throw `Limit Exceeded. This update requires ₦${difference.toLocaleString()} more limit, but you only have ₦${available.toLocaleString()}.`;
        }
      }

      // 5. Determine New Status
      // If rejected, reset to pending. If approved, keep approved.
      let newStatus = oldData.status;
      if (oldData.status === 'rejected') {
        newStatus = 'pending';
      } else if (oldData.status === 'outOfStock' && newStock > 0) {
        // If it was OOS but now has stock, check if it was previously approved
        // For simplicity, we assume OOS products were once approved.
        newStatus = 'approved';
      }

      // 6. Update Stats
      const currentActive = Number(stats.currentActivePlanValue) || 0;
      t.update(statsRef, {
        currentActivePlanValue: currentActive + difference, // Add delta (works for negative too)
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });

      // 7. Update Product
      t.update(productDoc.ref, {
        ...updateData, // Apply all new fields (Timeline, Policy, etc.)
        status: newStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return { code: productCode, status: newStatus };
    });

    return new Response(JSON.stringify({ success: true, data: result }), { 
      headers: { "Content-Type": "application/json" } 
    });

  } catch (error) {
    const msg = error.toString().replace("Error: ", "");
    return new Response(JSON.stringify({ success: false, error: msg }), { 
      status: 400, 
      headers: { "Content-Type": "application/json" } 
    });
  }
});