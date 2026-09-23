const { ApiError } = require('./api-error');
const { store } = require('../data/store');

function requireSession(req, _res, next) {
  const authorization = req.get('authorization');
  if (!authorization?.startsWith('Bearer ')) {
    return next(
      new ApiError(401, 'UNAUTHENTICATED', 'Sign in again to continue.'),
    );
  }

  const token = authorization.substring('Bearer '.length).trim();
  const session = store.sessions.get(token);
  if (!session) {
    return next(
      new ApiError(401, 'UNAUTHENTICATED', 'Sign in again to continue.'),
    );
  }

  req.session = session;
  return next();
}

module.exports = { requireSession };
