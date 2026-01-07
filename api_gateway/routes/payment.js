const express = require('express');
const router = express.Router();
const { Payment, Order } = require('../services/db');

// mock payment processing endpoint
router.post('/charge', async (req, res) => {
  try {
    const { order_id, method, amount } = req.body;
    if (!order_id || !method) return res.status(400).json({error:'missing fields'});
    // create payment record -> in real integration call provider API (Midtrans/Xendit)
    const payment = await Payment.create({ order_id, method, amount, status:'success', transaction_id: 'MOCK-'+Date.now() });
    // update order status
    await Order.update({ status: 'in_progress' }, { where: { order_id } });
    res.json({status:'success', payment_id: payment.payment_id});
  } catch(err){ console.error(err); res.status(500).json({error:'server error'}); }
});

module.exports = router;
