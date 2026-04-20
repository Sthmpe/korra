# Korra Database Schema Documentation
*Last Updated: March 2026*

This document tracks the JSON structures and possible values for all Firestore collections in the Korra platform. Always refer to this before manually updating the database or adding new fields in the code.

---

## Collection: `vendor_compliance`
**Document ID:** `merchantUid`
**Purpose:** Controls the security and operational status of a merchant account. This overrides the standard profile.

| Field | Type | Description |
| :--- | :--- | :--- |
| `uid` | String | The unique identifier of the merchant. |
| `status` | String | The current operational state of the merchant. (See ENUMS below) |
| `reason` | String | Hidden note for Korra admins on the account's current status or restriction reason. |
| `publicMessage` | String | The user-friendly message shown to the merchant in the app. |
| `blockPayments` | Boolean | If true, customers are strictly blocked from making new payments or reservations. |
| `livenessCheckPassed` | Boolean | True if the merchant has successfully passed identity verification. |
| `livenessBypass` | Boolean | True if the liveness check requirement is currently bypassed for this account. |
| `livenessMatchPercentage` | Number | The confidence score of the identity match. |
| `lastCheckDate` | Timestamp | When the last identity or liveness check was performed. |
| `metrics` | Map | Admin tracking metrics containing `restrictionCount`, `resolutionCount`, and `falseComplaintCount`. |
| `complaints` | Array<Map> | History logs of customer complaints. Expected format: `{ date, type, customerId, resolved }`. |
| `reviews` | Array<Map> | History logs of merchant reviews. Expected format: `{ date, rating, customerId, isGood }`. |
| `updatedAt` | Timestamp | When this document was last updated. |

**ENUMS for `status`:**
* `active`: Normal operations. Can create and edit products.
* `verification_pending`: New account. Can set up shop but maybe not withdraw.
* `restricted`: Cannot create/edit products. (Usually triggered by bad behavior).
* `suspended`: Account totally frozen.
* `banned`: Permanent removal.

*Example JSON:*
```json
{
  "uid": "merchant_123xyz",
  "status": "restricted",
  "reason": "Customer complaint #4029 - Non-delivery",
  "publicMessage": "Your account has been restricted due to multiple unfulfilled reservations. Please contact support.",
  "blockPayments": true,
  "livenessCheckPassed": true,
  "livenessBypass": false,
  "livenessMatchPercentage": 98.5,
  "lastCheckDate": "2026-03-20T10:00:00Z",
  "metrics": {
    "restrictionCount": 1,
    "resolutionCount": 0,
    "falseComplaintCount": 0
  },
  "complaints": [
    {
      "date": "2026-03-25T14:30:00Z",
      "type": "non_delivery",
      "customerId": "cust_890",
      "resolved": false
    }
  ],
  "reviews": [],
  "updatedAt": "2026-03-26T17:24:39Z"
}