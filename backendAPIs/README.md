# PayLite mock API

An in-memory Node/Express API for PayLite. It implements authentication,
accounts, VPA lookup, payments, collect requests, server-side expiry, and
payment idempotency.

## Run

Install Node.js 18.17 or newer, then run:

```bash
npm install
npm start
```

The default URL is `http://localhost:3000`. All mock data resets when the
server restarts.

## PostgreSQL deployment

The Prisma schema is in `prisma/schema.prisma` and expects `DATABASE_URL`.
Copy `.env.example` to `.env` for local setup, then run:

```bash
npm install
npm run prisma:generate
npx prisma migrate dev --name init
npm run prisma:seed
```

The current service implementation still uses the legacy in-memory store while
the Prisma service migration is being completed. Do not deploy this intermediate
state as a persistent production API yet. Use `render.yaml` and the end-to-end
guide after the services/controllers have been migrated to Prisma.

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
| GET | `/collect-requests` | Bearer token |
| POST | `/collect-requests` | Bearer token |
| POST | `/collect-requests/:id/pay` | Bearer token |
| POST | `/collect-requests/:id/decline` | Bearer token |

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

## Collect requests

Create a request with:

```json
{
  "vpa": "ramesh@paylite",
  "amountPaise": 50000
}
```

Requests expire after 48 hours according to server time. The backend changes
expired pending requests to `EXPIRED` and rejects pay/decline attempts with
`410 EXPIRED`. Incoming requests can be paid with a hashed payment PIN and an
idempotency key, or declined. The Flutter app also uses this API for split-bill
participants.

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
