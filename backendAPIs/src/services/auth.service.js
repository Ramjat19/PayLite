const { randomBytes, randomUUID, timingSafeEqual } = require('node:crypto');
const { hashLoginPin, store } = require('../data/store');
const { ApiError } = require('../middleware/api-error');
const { requireBodyObject, requireString } = require('./validation');

function hasMatchingLoginPin(pin, expectedHash) {
  const actualHash = Buffer.from(hashLoginPin(pin), 'hex');
  const expected = Buffer.from(expectedHash, 'hex');
  return actualHash.length === expected.length && timingSafeEqual(actualHash, expected);
}

function login(payload) {
  const body = requireBodyObject(payload);
  const customerId = requireString(body.customerId, 'customerId').toUpperCase();
  const pin = requireString(body.pin, 'pin');
  const suppliedDeviceId = body.deviceId === undefined
    ? null
    : requireString(body.deviceId, 'deviceId');
  const customer = store.customers.get(customerId);

  if (!customer || !hasMatchingLoginPin(pin, customer.loginPinHash)) {
    throw new ApiError(401, 'INVALID_CREDENTIALS', 'Your customer ID or PIN is incorrect.');
  }

  if (customer.boundDeviceId && customer.boundDeviceId !== suppliedDeviceId) {
    throw new ApiError(
      423,
      'DEVICE_BOUND',
      'This account is already bound to another device.',
    );
  }

  const deviceId = customer.boundDeviceId || randomUUID();
  customer.boundDeviceId = deviceId;

  const token = randomBytes(32).toString('base64url');
  store.sessions.set(token, {
    customerId: customer.id,
    accountId: customer.accountId,
    deviceId,
  });

  return { token, deviceId };
}

module.exports = { login };
