const {
  createRequest,
  declineRequest,
  listRequests,
  payRequest,
} = require('../services/collect.service');

function getAll(req, res, next) {
  try {
    return res.json({ items: listRequests(req.session) });
  } catch (error) {
    return next(error);
  }
}

function create(req, res, next) {
  try {
    return res.status(201).json(createRequest(req.session, req.body));
  } catch (error) {
    return next(error);
  }
}

function pay(req, res, next) {
  try {
    return res.json(payRequest(req.session, req.params.id, req.body));
  } catch (error) {
    return next(error);
  }
}

function decline(req, res, next) {
  try {
    return res.json(declineRequest(req.session, req.params.id));
  } catch (error) {
    return next(error);
  }
}

module.exports = { create, decline, getAll, pay };