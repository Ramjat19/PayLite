const express = require('express');
const { getPrimary } = require('../controllers/account.controller');
const { requireSession } = require('../middleware/auth');

const router = express.Router();
router.get('/primary', requireSession, getPrimary);

module.exports = router;
