const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { sequelize } = require("../services/db");

// LOGIN
router.post("/login", async (req, res) => {
  const { email, password } = req.body;
  console.log("REQ BODY LOGIN:", req.body);
  console.log("Email >", email);
  console.log("Password >", password);

  try {
    const [users] = await sequelize.query(
      "SELECT * FROM users WHERE email = ?",
      { replacements: [email] }
    );

    if (users.length === 0) {
      return res.json({ success: false, message: "Email salah" });
    }

    const user = users[0];

    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.json({ success: false, message: "Password salah" });
    }

    const token = jwt.sign(
      { id: user.user_id, role: user.role },
      "SECRET_KEY",
      { expiresIn: "1d" }
    );

    res.json({
      success: true,
      message: "Login berhasil",
      token,
      role: user.role,
      user_id: user.user_id,   
      name: user.name          
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});
// REGISTER
router.post("/register", async (req, res) => {
  const { name, email, password, role } = req.body;

  try {
    // ✅ 1. Cek apakah email sudah terdaftar
    const [exist] = await sequelize.query(
      "SELECT * FROM users WHERE email = ?",
      { replacements: [email] }
    );

    if (exist.length > 0) {
      return res.json({
        success: false,
        message: "Email sudah terdaftar",
      });
    }

    // ✅ 2. Hash password terlebih dahulu
    const hashed = await bcrypt.hash(password, 10);

    // ✅ 3. Simpan user baru
    await sequelize.query(
      "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)",
      { replacements: [name, email, hashed, role] }
    );

    res.json({
      success: true,
      message: "Registrasi berhasil",
    });

  } catch (err) {
    console.error("REGISTER ERROR:", err);
    res.status(500).json({
      success: false,
      message: "Terjadi kesalahan server",
      error: err.message,
    });
  }
});


module.exports = router;
