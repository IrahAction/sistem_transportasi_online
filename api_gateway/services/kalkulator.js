// services/kalkulator.js
function calculateFare(type, distanceKm = 0, foodPrice = 0) {
  const biayaPerKm = 1850;
  const biayaLayanan = 1000;

  const biayaPerjalanan = distanceKm * biayaPerKm;

  // === RIDE / PACKAGE ===
  if (type === "ride" || type === "package") {
    return {
      user_total: biayaPerjalanan + biayaLayanan,
      user_distance_cost: biayaPerjalanan,
      user_fee: biayaLayanan,

      driver_total: biayaPerjalanan * 0.7,
      driver_commission: biayaPerjalanan * 0.7,

      merchant_total: 0,
      merchant_fee: 0
    };
  }

  // === FOOD ===
  if (type === "food") {
    const merchant_receive = foodPrice * 0.9;   // merchant dapat 90%
    const app_cut = foodPrice * 0.1;           // aplikasi ambil 10%

    return {
      user_total: foodPrice + biayaLayanan,
      user_food: foodPrice,
      user_fee: biayaLayanan,

      driver_total: biayaPerjalanan * 0.7,
      driver_commission: biayaPerjalanan * 0.7,

      merchant_total: foodPrice,
      merchant_receive,
      merchant_fee: app_cut
    };
  }

  return null;
}

module.exports = calculateFare;
