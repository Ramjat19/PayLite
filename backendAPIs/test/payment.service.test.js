const assert = require('node:assert/strict');
const test = require('node:test');
const { login } = require('../src/services/auth.service');
const { createPayment } = require('../src/services/payment.service');
const { store } = require('../src/data/store');

test('one idempotency key produces exactly one debit', () => {
  const { token } = login({ customerId: 'CUST1001', pin: '1234' });
  const session = store.sessions.get(token);
  const account = store.accounts.get(session.accountId);
  const startingBalance = account.balancePaise;
  const request = {
    vpa: 'merchant@paylite',
    amountPaise: 5000,
    note: 'Idempotency test',
    upiPinHash: 'test-only-hash',
  };

  const first = createPayment({
    session,
    idempotencyKey: 'test-confirmation-key',
    payload: request,
  });
  const retry = createPayment({
    session,
    idempotencyKey: 'test-confirmation-key',
    payload: request,
  });

  assert.equal(first.created, true);
  assert.equal(retry.created, false);
  assert.equal(retry.payment.id, first.payment.id);
  assert.equal(account.balancePaise, startingBalance - request.amountPaise);
});
