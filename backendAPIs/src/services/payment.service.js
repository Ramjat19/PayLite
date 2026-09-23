const { randomUUID } = require('node:crypto');
const { normaliseVpa, store } = require('../data/store');
const { ApiError } = require('../middleware/api-error');
const {
  optionalString,
  parseLimit,
  requireBodyObject,
  requirePositivePaise,
  requireString,
} = require('./validation');
const { publicVpa } = require('./vpa.service');

const maximumPaymentPaise = 10000000;
const mockStatuses = new Set(['SUCCESS', 'PENDING', 'FAILED']);

function publicPayment(payment) {
  settlePendingPayment(payment);
  return {
    id: payment.id,
    direction: payment.direction,
    counterparty: publicVpa(payment.counterparty),
    amountPaise: payment.amountPaise,
    note: payment.note,
    status: payment.status,
    upiRef: payment.upiRef,
    createdAt: payment.createdAt,
  };
}

function settlePendingPayment(payment) {
  if (payment.status !== 'PENDING' || !payment.pendingUntil) {
    return;
  }
  if (Date.now() < payment.pendingUntil) {
    return;
  }

  payment.status = 'SUCCESS';
  payment.upiRef = createUpiReference();
  payment.pendingUntil = null;
}

function createUpiReference() {
  return `PL${Date.now()}${Math.floor(Math.random() * 1000)
    .toString()
    .padStart(3, '0')}`;
}

function parseMockControls(headers) {
  const requestedStatus = headers.paymentStatus?.toUpperCase() || 'SUCCESS';
  if (!mockStatuses.has(requestedStatus)) {
    throw new ApiError(400, 'INVALID_MOCK_STATUS', 'The mock payment status is invalid.');
  }

  const pendingDurationText = headers.pendingMs || '15000';
  if (!/^\d+$/.test(pendingDurationText)) {
    throw new ApiError(400, 'INVALID_MOCK_DELAY', 'The mock pending delay must be a whole number.');
  }

  const pendingDurationMs = Number(pendingDurationText);
  if (pendingDurationMs > 120000) {
    throw new ApiError(400, 'INVALID_MOCK_DELAY', 'The mock pending delay cannot exceed two minutes.');
  }

  return { pendingDurationMs, status: requestedStatus };
}

function createPayment({ session, idempotencyKey, payload, mockHeaders = {} }) {
  if (typeof idempotencyKey !== 'string' || idempotencyKey.trim().length === 0) {
    throw new ApiError(
      400,
      'IDEMPOTENCY_KEY_REQUIRED',
      'An Idempotency-Key header is required to make a payment.',
    );
  }

  const body = requireBodyObject(payload);
  const vpaAddress = normaliseVpa(requireString(body.vpa, 'vpa'));
  const amountPaise = requirePositivePaise(body.amountPaise, 'amountPaise');
  const note = optionalString(body.note, 'note', 140);
  requireString(body.upiPinHash, 'upiPinHash');

  if (amountPaise > maximumPaymentPaise) {
    throw new ApiError(
      422,
      'LIMIT_EXCEEDED',
      'Payments above the maximum allowed amount are not allowed.',
      { maximumPaise: maximumPaymentPaise },
    );
  }

  const fingerprint = JSON.stringify({ amountPaise, note, vpa: vpaAddress });
  const recordKey = `${session.accountId}:${idempotencyKey.trim()}`;
  const existingRecord = store.idempotencyRecords.get(recordKey);
  if (existingRecord) {
    if (existingRecord.fingerprint !== fingerprint) {
      throw new ApiError(
        409,
        'KEY_REUSED',
        'This confirmation key was already used for a different payment.',
      );
    }
    return { created: false, payment: publicPayment(existingRecord.payment) };
  }

  const counterparty = store.vpas.get(vpaAddress);
  if (!counterparty) {
    throw new ApiError(404, 'VPA_NOT_FOUND', 'No account found for this UPI ID.');
  }

  const account = store.accounts.get(session.accountId);
  if (!account || account.balancePaise < amountPaise) {
    throw new ApiError(422, 'INSUFFICIENT_FUNDS', 'Your account does not have enough balance.');
  }

  const mock = parseMockControls(mockHeaders);
  const payment = {
    id: `pay_${randomUUID()}`,
    accountId: session.accountId,
    direction: 'SENT',
    counterparty,
    amountPaise,
    note,
    status: mock.status,
    upiRef: mock.status === 'SUCCESS' ? createUpiReference() : null,
    createdAt: new Date().toISOString(),
    pendingUntil:
      mock.status === 'PENDING' ? Date.now() + mock.pendingDurationMs : null,
  };

  if (payment.status !== 'FAILED') {
    account.balancePaise -= amountPaise;
  }

  store.payments.push(payment);
  store.idempotencyRecords.set(recordKey, { fingerprint, payment });
  return { created: true, payment: publicPayment(payment) };
}

function getPayment(session, paymentId) {
  const payment = store.payments.find((item) => item.id === paymentId);
  if (!payment || payment.accountId !== session.accountId) {
    throw new ApiError(404, 'PAYMENT_NOT_FOUND', 'The payment was not found.');
  }
  return publicPayment(payment);
}

function decodeCursor(cursor) {
  if (typeof cursor !== 'string' || cursor.length === 0) {
    throw new ApiError(400, 'INVALID_CURSOR', 'The cursor is invalid.');
  }
  const decoded = Buffer.from(cursor, 'base64url').toString('utf8');
  if (!/^\d+$/.test(decoded)) {
    throw new ApiError(400, 'INVALID_CURSOR', 'The cursor is invalid.');
  }
  return Number(decoded);
}

function encodeCursor(offset) {
  return Buffer.from(String(offset)).toString('base64url');
}

function listPayments(session, query) {
  const limit = parseLimit(query.limit);
  const offset = query.cursor === undefined ? 0 : decodeCursor(query.cursor);
  const allowedFilters = new Set(['sent', 'received', 'failed', 'pending']);

  if (query.filter !== undefined && typeof query.filter !== 'string') {
    throw new ApiError(400, 'INVALID_FILTER', 'The payment filter is invalid.');
  }
  if (query.q !== undefined && typeof query.q !== 'string') {
    throw new ApiError(400, 'INVALID_SEARCH', 'The payment search text is invalid.');
  }

  const filter = query.filter?.toLowerCase();
  const search = query.q?.trim().toLowerCase();
  if (filter && !allowedFilters.has(filter)) {
    throw new ApiError(400, 'INVALID_FILTER', 'The payment filter is invalid.');
  }

  let payments = store.payments.filter((payment) => payment.accountId === session.accountId);
  payments.forEach(settlePendingPayment);

  if (filter === 'sent' || filter === 'received') {
    payments = payments.filter((payment) => payment.direction === filter.toUpperCase());
  } else if (filter === 'failed' || filter === 'pending') {
    payments = payments.filter((payment) => payment.status === filter.toUpperCase());
  }

  if (search) {
    payments = payments.filter((payment) => {
      const name = payment.counterparty.verifiedName.toLowerCase();
      const address = payment.counterparty.address.toLowerCase();
      return name.includes(search) || address.includes(search);
    });
  }

  payments.sort((first, second) => second.createdAt.localeCompare(first.createdAt));
  const page = payments.slice(offset, offset + limit).map(publicPayment);
  const nextOffset = offset + page.length;

  return {
    items: page,
    nextCursor: nextOffset < payments.length ? encodeCursor(nextOffset) : null,
  };
}

module.exports = { createPayment, getPayment, listPayments };
