const { ApiError } = require('../middleware/api-error');

function requireBodyObject(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new ApiError(400, 'INVALID_REQUEST', 'The request body must be a JSON object.');
  }
  return value;
}

function requireString(value, field) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new ApiError(400, 'INVALID_REQUEST', `"${field}" is required.`, { field });
  }
  return value.trim();
}

function optionalString(value, field, maxLength) {
  if (value === undefined || value === null) {
    return null;
  }
  if (typeof value !== 'string') {
    throw new ApiError(400, 'INVALID_REQUEST', `"${field}" must be a string.`, { field });
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLength) {
    throw new ApiError(400, 'INVALID_REQUEST', `"${field}" is too long.`, {
      field,
      maxLength,
    });
  }
  return trimmed || null;
}

function requirePositivePaise(value, field) {
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new ApiError(400, 'INVALID_AMOUNT', `"${field}" must be a positive integer in paise.`, {
      field,
    });
  }
  return value;
}

function parseLimit(value) {
  if (value === undefined) {
    return 20;
  }
  if (typeof value !== 'string' || !/^\d+$/.test(value)) {
    throw new ApiError(400, 'INVALID_LIMIT', '"limit" must be a whole number.');
  }
  const limit = Number(value);
  if (limit < 1 || limit > 100) {
    throw new ApiError(400, 'INVALID_LIMIT', '"limit" must be between 1 and 100.');
  }
  return limit;
}

module.exports = {
  optionalString,
  parseLimit,
  requireBodyObject,
  requirePositivePaise,
  requireString,
};
