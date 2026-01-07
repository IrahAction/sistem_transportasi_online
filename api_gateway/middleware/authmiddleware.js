const jwt = require("jsonwebtoken");

const verifyToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];

  if (!authHeader) {
    return res.status(401).json({ success: false, message: "Token tidak ditemukan" });
  }

  const token = authHeader.split(" ")[1]; // Format: "Bearer <token>"

  if (!token) {
    return res.status(401).json({ success: false, message: "Token tidak valid" });
  }

  try {
    const decoded = jwt.verify(token, "SECRET_KEY"); // gunakan key yang sama seperti di login
    req.user = decoded; // simpan data user ke request
    next();
  } catch (err) {
    res.status(403).json({ success: false, message: "Token tidak sah atau sudah kedaluwarsa" });
  }
};

module.exports = verifyToken;
