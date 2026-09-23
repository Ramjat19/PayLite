const { normaliseVpa, store } = require('../data/store');
const { ApiError } = require('../middleware/api-error');

function publicVpa(vpa) {
  return {
    address: vpa.address,
    verifiedName: vpa.verifiedName,
    bankName: vpa.bankName,
  };
}

function getVpa(address) {
  if (typeof address !== 'string' || address.trim().length === 0) {
    throw new ApiError(400, 'INVALID_VPA', 'A UPI ID is required.');
  }

  const vpa = store.vpas.get(normaliseVpa(address));
  if (!vpa) {
    throw new ApiError(404, 'VPA_NOT_FOUND', 'No account found for this UPI ID.');
  }
  return publicVpa(vpa);
}

module.exports = { getVpa, publicVpa };
