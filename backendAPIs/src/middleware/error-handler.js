const { randomUUID } = require('node:crypto');
const { ApiError } = require('./api-error');

function assignTraceId(req, _res, next) {
  req.traceId = randomUUID();
  next();
}

function notFound(req, _res, next) {
  next(
    new ApiError(
      404,
      'ROUTE_NOT_FOUND',
      `No endpoint exists for ${req.method} ${req.path}.`,
    ),
  );
}

function errorHandler(error, req, res, _next) {
  let apiError = error;

  if (error instanceof SyntaxError && error.status === 400 && 'body' in error) {
    apiError = new ApiError(400, 'INVALID_JSON', 'The request body is not valid JSON.');
  }

  if (!(apiError instanceof ApiError)) {
    console.error(`[${req.traceId}] Unexpected API error`, error);
    apiError = new ApiError(
      500,
      'INTERNAL_ERROR',
      'Something went wrong. Please try again.',
    );
  }

  return res.status(apiError.status).json({
    error: {
      code: apiError.code,
      message: apiError.message,
      details: apiError.details,
      traceId: req.traceId,
    },
  });
}

module.exports = { assignTraceId, errorHandler, notFound };
