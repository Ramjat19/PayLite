const { getPrimaryAccount } = require('../services/account.service');

function getPrimary(req, res, next) {
  try {
    return res.json(getPrimaryAccount(req.session));
  } catch (error) {
    return next(error);
  }
}

module.exports = { getPrimary };
