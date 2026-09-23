# PayLite mock API

An in-memory Node/Express API for the first PayLite backend phase. It implements
only authentication, account, VPA lookup and payment endpoints. Collect-request
endpoints are deliberately deferred.

## Run

Install Node.js 18.17 or newer, then run:

```bash
npm install
npm start
```

The default URL is `http://localhost:3000`. All mock data resets when the
server restarts.

Run the idempotency unit test with `npm test`.

Demo credentials:

```text
customerId: CUST1001
pin: 1234
```

The first login binds a generated `deviceId`. Provide that same ID on later
logins; another device receives `423 DEVICE_BOUND`.

## Implemented APIs

| Method | Path | Authentication |
| --- | --- | --- |
| POST | `/auth/login` | No |
| GET | `/accounts/primary` | Bearer token |
| GET | `/vpa/:address` | Bearer token |
| POST | `/payments` | Bearer token plus Idempotency-Key |
| GET | `/payments/:id` | Bearer token |
| GET | `/payments?cursor=&limit=&filter=&q=` | Bearer token |

The payment request body is:

```json
{
  "vpa": "merchant@paylite",
  "amountPaise": 12500,
  "note": "Groceries",
  "upiPinHash": "hash-created-on-device"
}
```

Money is integer paise. Payments over `10000000` paise are rejected. Repeating
the same request with its original Idempotency-Key returns its original payment;
using that key for different payment data returns `409 KEY_REUSED`.

## Mock payment statuses

Normal payments succeed immediately. Outside production, use these headers to
exercise the Flutter pending and failure states:

```text
X-Mock-Payment-Status: PENDING | FAILED | SUCCESS
X-Mock-Pending-Ms: 15000
```

Pending payments settle to SUCCESS after the selected delay, capped at two
minutes. Failed payments do not debit the account.

## Errors

Every error uses the common API contract:

```json
{
  "error": {
    "code": "VPA_NOT_FOUND",
    "message": "No account found for this UPI ID.",
    "details": {},
    "traceId": "a025cce5-176d-4c03-94f1-56c6bfaed945"
  }
}
```
