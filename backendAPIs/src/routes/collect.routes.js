const express = require('express');
const { requireSession } = require('../middleware/auth');
const {
	create,
	decline,
	getAll,
	pay,
} = require('../controllers/collect.controller');

const router = express.Router();
router.use(requireSession);
router.get('/', getAll);
router.post('/', create);
router.post('/:id/pay', pay);
router.post('/:id/decline', decline);

module.exports = router;
