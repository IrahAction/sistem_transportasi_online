const express = require('express');
const router = express.Router();
const { sequelize } = require('../services/db');

// MERCHANT: Tambah menu baru
router.post('/add', async (req, res) => {
  const { merchant_id, name, price } = req.body;
  try {
    await sequelize.query(
      `INSERT INTO menus (merchant_id, name, price) VALUES (?, ?, ?)`,
      { replacements: [merchant_id, name, price] }
    );
    res.json({ success: true, message: "Menu berhasil ditambahkan" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// MERCHANT: Ambil semua menu milik merchant
router.get('/:merchant_id', async (req, res) => {
  const { merchant_id } = req.params;
  try {
    const [menus] = await sequelize.query(
      `SELECT * FROM menus WHERE merchant_id = ?`,
      { replacements: [merchant_id] }
    );
    res.json({ success: true, data: menus });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
