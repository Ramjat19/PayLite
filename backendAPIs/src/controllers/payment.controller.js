const { ApiError } = require('../middleware/api-error');
const {
  createPayment,
  getPayment,
  listPayments,
} = require('../services/payment.service');

function mockHeaders(req) {
  const paymentStatus = req.get('x-mock-payment-status');
  const pendingMs = req.get('x-mock-pending-ms');

  if (process.env.NODE_ENV === 'production' && (paymentStatus || pendingMs)) {
    throw new ApiError(403, 'MOCK_CONTROL_DISABLED', 'Mock controls are disabled.');
  }

  return { paymentStatus, pendingMs };
}

function postPayment(req, res, next) {
  try {
    const result = createPayment({
      session: req.session,
      idempotencyKey: req.get('idempotency-key'),
      payload: req.body,
      mockHeaders: mockHeaders(req),
    });
    // An idempotent retry returns the original response, including its 201.
    return res.status(201).json(result.payment);
  } catch (error) {
    return next(error);
  }
}

function getById(req, res, next) {
  try {
    return res.json(getPayment(req.session, req.params.id));
  } catch (error) {
    return next(error);
  }
}

function getHistory(req, res, next) {
  try {
    return res.json(listPayments(req.session, req.query));
  } catch (error) {
    return next(error);
  }
}

module.exports = { getById, getHistory, postPayment };
