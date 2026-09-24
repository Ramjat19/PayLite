const { randomUUID } = require('node:crypto');
const { createPayment } = require('./payment.service');
const { publicVpa } = require('./vpa.service');
const { store, normaliseVpa } = require('../data/store');
const { ApiError } = require('../middleware/api-error');
const {
  requireBodyObject,
  requirePositivePaise,
  requireString,
} = require('./validation');

const requestLifetimeMs = 48 * 60 * 60 * 1000;

function currentVpa(session) {
  const vpa = [...store.vpas.values()].find(
    (item) => item.accountId === session.accountId,
  );
  if (!vpa) throw new ApiError(404, 'VPA_NOT_FOUND', 'Your payment address was not found.');
  return vpa;
}

function expire(request) {
  if (request.status === 'PENDING' && Date.now() >= request.expiresAt) {
    request.status = 'EXPIRED';
  }
}

function publicRequest(request) {
  expire(request);
  return {
    id: request.id,
    from: publicVpa(request.from),
    to: publicVpa(request.to),
    amountPaise: request.amountPaise,
    status: request.status,
    expiresAt: new Date(request.expiresAt).toISOString(),
  };
}

function findRequest(session, id) {
  const request = store.collectRequests.find((item) => item.id === id);
  if (!request || (request.from.accountId !== session.accountId &&
      request.to.accountId !== session.accountId)) {
    throw new ApiError(404, 'REQUEST_NOT_FOUND', 'The collect request was not found.');
  }
  expire(request);
  return request;
}

function createRequest(session, payload) {
  const body = requireBodyObject(payload);
  const targetAddress = normaliseVpa(requireString(body.vpa, 'vpa'));
  const amountPaise = requirePositivePaise(body.amountPaise, 'amountPaise');
  const from = currentVpa(session);
  const to = store.vpas.get(targetAddress);
  if (!to) throw new ApiError(404, 'VPA_NOT_FOUND', 'No account found for this UPI ID.');
  if (to.accountId === session.accountId) {
    throw new ApiError(400, 'INVALID_REQUEST', 'You cannot request money from yourself.');
  }

  const request = {
    id: `cr_${randomUUID()}`,
    from,
    to,
    amountPaise,
    status: 'PENDING',
    expiresAt: Date.now() + requestLifetimeMs,
  };
  store.collectRequests.push(request);
  return publicRequest(request);
}

function listRequests(session) {
  return store.collectRequests
    .filter((request) => request.from.accountId === session.accountId ||
      request.to.accountId === session.accountId)
    .map(publicRequest);
}

function payRequest(session, id, payload) {
  const request = findRequest(session, id);
  if (request.to.accountId !== session.accountId) {
    throw new ApiError(403, 'REQUEST_FORBIDDEN', 'Only the requested payer can pay this request.');
  }
  if (request.status === 'EXPIRED') {
    throw new ApiError(410, 'EXPIRED', 'This request has expired.');
  }
  if (request.status !== 'PENDING') {
    throw new ApiError(409, 'REQUEST_NOT_PENDING', 'This request is no longer pending.');
  }

  const body = requireBodyObject(payload);
  const result = createPayment({
    session,
    idempotencyKey: requireString(body.idempotencyKey, 'idempotencyKey'),
    payload: {
      vpa: request.from.address,
      amountPaise: request.amountPaise,
      note: 'Collect request payment',
      upiPinHash: requireString(body.upiPinHash, 'upiPinHash'),
    },
  });
  request.status = 'PAID';
  return { request: publicRequest(request), payment: result.payment };
}

function declineRequest(session, id) {
  const request = findRequest(session, id);
  if (request.to.accountId !== session.accountId) {
    throw new ApiError(403, 'REQUEST_FORBIDDEN', 'Only the requested payer can decline this request.');
  }
  if (request.status === 'EXPIRED') {
    throw new ApiError(410, 'EXPIRED', 'This request has expired.');
  }
  if (request.status !== 'PENDING') {
    throw new ApiError(409, 'REQUEST_NOT_PENDING', 'This request is no longer pending.');
  }
  request.status = 'DECLINED';
  return publicRequest(request);
}

module.exports = {
  createRequest,
  declineRequest,
  listRequests,
  payRequest,
};