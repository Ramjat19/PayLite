const express = require('express');
const { getByAddress } = require('../controllers/vpa.controller');
const { requireSession } = require('../middleware/auth');

const router = express.Router();
router.get('/:address', requireSession, getByAddress);

module.exports = router;
