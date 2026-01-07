function toRad(Value) {
  return Value * Math.PI / 180;
}

function calculateDistanceKm(origin, destination) {
  // origin, destination expected as {lat: number, lon: number} or {lat, lng}
  if (!origin || !destination) return 0;
  const lat1 = origin.lat || origin.latitude;
  const lon1 = origin.lon || origin.longitude || origin.lng;
  const lat2 = destination.lat || destination.latitude;
  const lon2 = destination.lon || destination.longitude || destination.lng;
  const R = 6371; // km
  const dLat = toRad(lat2-lat1);
  const dLon = toRad(lon2-lon1);
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const d = R * c;
  return parseFloat(d.toFixed(2));
}

module.exports = { calculateDistanceKm };
