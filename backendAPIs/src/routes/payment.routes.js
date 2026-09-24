const express = require('express');
const {
  getById,
  getHistory,
  postPayment,
} = require('../controllers/payment.controller');
const { requireSession } = require('../middleware/auth');

const router = express.Router();
router.post('/', requireSession, postPayment);
router.get('/:id', requireSession, getById);
router.get('/', requireSession, getHistory);

module.exports = router;
