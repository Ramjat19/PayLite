const { getVpa } = require('../services/vpa.service');

function getByAddress(req, res, next) {
  try {
    return res.json(getVpa(req.params.address));
  } catch (error) {
    return next(error);
  }
}

module.exports = { getByAddress };
