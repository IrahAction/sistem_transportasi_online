const express = require("express");
const router = express.Router();
const { sequelize } = require("../services/db");
const verifyToken = require("../middleware/authmiddleware");
const calculateFare = require("../services/kalkulator");
const { getIO, driverLocations } = require('../services/socket');
function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // km
  const toRad = (v) => (v * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
// === USER: Buat pesanan baru ===
router.post("/create", verifyToken, async (req, res) => {
  try {
    const userId = req.user.id; // Ambil dari token
    const { type, pickup_location, dropoff_location, merchant_id, total, items } = req.body;

    if (!type || !pickup_location || !dropoff_location) {
      return res.status(400).json({
        success: false,
        message: "Data tidak lengkap — pastikan lokasi asal & tujuan terisi.",
      });
    }

    // Parsing koordinat jika format "lat,long"
    let pickupLat = null, pickupLng = null, dropLat = null, dropLng = null;
    if (pickup_location.includes(",")) [pickupLat, pickupLng] = pickup_location.split(",").map(Number);
    if (dropoff_location.includes(",")) [dropLat, dropLng] = dropoff_location.split(",").map(Number);

    let query = "";
    let replacements = [];

    // === 1️⃣ RIDE SERVICE ===
    if (type === "ride") {
      query = `
        INSERT INTO orders (user_id, service_type, origin, destination, pickup_lat, pickup_lng, drop_lat, drop_lng, price, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW())
      `;
      replacements = [userId, type, pickup_location, dropoff_location, pickupLat, pickupLng, dropLat, dropLng, total || 0];
    }

    // === 2️⃣ FOOD DELIVERY ===
    else if (type === "food") {
      if (!merchant_id) {
        return res.status(400).json({
          success: false,
          message: "merchant_id wajib diisi untuk food delivery",
        });
      }

      // Buat pesanan makanan utama
      const [result] = await sequelize.query(
        `
        INSERT INTO orders (user_id, merchant_id, service_type, origin, destination, pickup_lat, pickup_lng, drop_lat, drop_lng, price, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW())
        `,
        {
          replacements: [
            userId,
            merchant_id,
            type,
            pickup_location,
            dropoff_location,
            pickupLat,
            pickupLng,
            dropLat,
            dropLng,
            total || 0,
          ],
        }
      );

      const orderId = result.insertId || result;

      // Jika ada daftar item makanan
      if (items && Array.isArray(items)) {
        for (const item of items) {
          await sequelize.query(
            `
            INSERT INTO order_items (order_id, item_id, quantity, subtotal)
            VALUES (?, ?, ?, ?)
            `,
            { replacements: [orderId, item.item_id, item.quantity, item.subtotal] }
          );
        }
      }

      return res.json({
        success: true,
        message: "Order makanan berhasil dibuat",
        order_id: orderId,
      });
    }

    // === 3️⃣ PACKAGE DELIVERY ===
    else if (type === "package") {
      query = `
        INSERT INTO orders (user_id, service_type, origin, destination, pickup_lat, pickup_lng, drop_lat, drop_lng, price, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW())
      `;
      replacements = [userId, type, pickup_location, dropoff_location, pickupLat, pickupLng, dropLat, dropLng, total || 0];
    }
    // Hitung distance (km) menggunakan koordinat user
const R = 6371; // radius bumi km
function calcDistance(lat1, lng1, lat2, lng2) {
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) *
            Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}
const distanceKm = calcDistance(pickupLat, pickupLng, dropLat, dropLng);

// Tarif
const hargaDasar = distanceKm * biayaPerKm;
const foodPrice = items?.reduce((sum, i) => sum + i.subtotal, 0) || 0;
const fare = calculateFare(type, distanceKm, foodPrice);

await sequelize.query(
  `
  INSERT INTO orders 
  (user_id, service_type, origin, destination, pickup_lat, pickup_lng, drop_lat, drop_lng, distance_km, price, driver_fee, service_fee, status, created_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW())
  `,
  {
    replacements: [
      userId,
      type,
      pickup_location,
      dropoff_location,
      pickupLat,
      pickupLng,
      dropLat,
      dropLng,
      distanceKm.toFixed(2),
      totalUserBayar,
      driverKomisi,
      biayaLayanan
    ],
  }
);

    // Jalankan query umum (ride / package)
    if (query && replacements.length > 0) {
      await sequelize.query(query, { replacements });
      return res.json({ success: true, message: `Order ${type} berhasil dibuat` });
    }

    return res.status(400).json({ success: false, message: "Jenis layanan tidak valid" });
  } catch (err) {
    console.error("Error create order:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});
// === DRIVER: Ambil 5 order pending terdekat ===
router.get('/nearby', async (req, res) => {
  const { lat, lng, limit = 5 } = req.query;
  if (!lat || !lng) return res.status(400).json({ success: false, message: "lat,lng missing" });

  // MySQL approximate using Haversine in SQL
  const sql = `
    SELECT o.*, 
    ( 6371 * acos( cos( radians(?) ) * cos( radians( pickup_lat ) ) * cos( radians( pickup_lng ) - radians(?) ) + sin( radians(?) ) * sin( radians( pickup_lat ) ) ) ) AS distance_km
    FROM orders o
    WHERE status = 'pending'
    HAVING distance_km IS NOT NULL
    ORDER BY distance_km ASC
    LIMIT ?
  `;
  try {
    const [rows] = await sequelize.query(sql, { replacements: [parseFloat(lat), parseFloat(lng), parseFloat(lat), parseInt(limit, 10)] });
    return res.json({ success: true, data: rows });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: err.message });
  }
});
// === DRIVER: Lihat order pending ===
router.get("/pending", async (req, res) => {
  try {
    if (req.user.role !== "driver") {
      return res.status(403).json({ success: false, message: "Akses driver saja" });
    }
    const [orders] = await sequelize.query("SELECT * FROM orders WHERE status = 'pending'");
    res.json({ success: true, data: orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
// === DRIVER: Lihat order diterima ===
router.put("/accept/:id", verifyToken, async (req, res) => {
  const orderId = req.params.id;
  const driverId = req.user.id;

  try {
    // Update order ke accepted
    await sequelize.query(
      "UPDATE orders SET driver_id = ?, status = 'accepted' WHERE order_id = ? AND status = 'pending'",
      { replacements: [driverId, orderId] }
    );

    res.json({ success: true, message: "Order berhasil diterima" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
//DRIVER: Update status order
router.put("/update/:id", async (req, res) => {
  const { id } = req.params;
  const { driver_id, status } = req.body;
  try {
    await sequelize.query(
      "UPDATE orders SET driver_id = ?, status = ? WHERE order_id = ?",
      { replacements: [driver_id, status, id] }
    );
    res.json({ success: true, message: "Status order diperbarui" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
//DRIVER: Tandai pesanan selesai
router.put("/complete/:id", verifyToken, async (req, res) => {
  const { id } = req.params; // order_id
  const driverId = req.user.id;

  try {
    //ambil order dari DB untuk mendapatkan drop_lat/drop_lng
    const [rows] = await sequelize.query("SELECT * FROM orders WHERE order_id = ?", { replacements: [id] });
    if (!rows || rows.length === 0) return res.status(404).json({ success: false, message: "Order tidak ditemukan" });

    const order = rows[0];
    const dropLat = order.drop_lat;
    const dropLng = order.drop_lng;

    if (dropLat == null || dropLng == null) {
      return res.status(400).json({ success: false, message: "Order tidak memiliki koordinat tujuan" });
    }

    // cek last driver location
    const last = driverLocations.get(driverId);
    if (!last) {
      return res.status(400).json({ success: false, message: "Lokasi driver tidak tersedia. Pastikan driver online dan share location." });
    }

    const dKm = haversineKm(last.lat, last.lng, dropLat, dropLng);
    const dMeters = dKm * 1000;

    if (dMeters > 100) {
      return res.status(400).json({
        success: false,
        message: `Driver masih ${Math.round(dMeters)} m dari tujuan. Harus <= 100 m untuk menyelesaikan.`
      });
    }

    // update status completed
    await sequelize.query("UPDATE orders SET status = 'completed', driver_id = ? WHERE order_id = ?", { replacements: [driverId, id] });

    //broadcast ke user & merchant
    io.to(`order_${id}`).emit('order:completed', { order_id: id, driver_id: driverId });
    if (order.user_id) io.to(`user_${order.user_id}`).emit('order:completed', { order_id: id });

    return res.json({ success: true, message: "Pesanan selesai ✅" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});
//MERCHANT: Ambil semua pesanan makanan
router.get("/food", async (req, res) => {
  try {
    const [orders] = await sequelize.query(
      "SELECT * FROM orders WHERE service_type = 'food' ORDER BY created_at DESC"
    );
    res.json({ success: true, data: orders });
  } catch (err) {
    console.error("Error get food orders:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});
module.exports = router;
