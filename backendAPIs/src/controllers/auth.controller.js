const { login } = require('../services/auth.service');

function postLogin(req, res, next) {
  try {
    return res.status(200).json(login(req.body));
  } catch (error) {
    return next(error);
  }
}

module.exports = { postLogin };
