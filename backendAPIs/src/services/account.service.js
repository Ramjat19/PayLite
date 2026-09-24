const { store } = require('../data/store');
const { ApiError } = require('../middleware/api-error');

function getPrimaryAccount(session) {
  const account = store.accounts.get(session.accountId);
  if (!account) {
    throw new ApiError(404, 'ACCOUNT_NOT_FOUND', 'The primary account was not found.');
  }
  return { ...account };
}

module.exports = { getPrimaryAccount };
