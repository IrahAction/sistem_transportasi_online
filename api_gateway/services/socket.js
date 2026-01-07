// services/socket.js
const { Server } = require('socket.io');

let io = null;
const driverLocations = new Map();

function initSocket(server) {
  io = new Server(server, {
    cors: { origin: "*" }
  });

  io.on("connection", socket => {
    const user = socket.user || {};

    // driver mengirim lokasi
    socket.on("driver:location", data => {
      const { driver_id, order_id, lat, lng } = data;
      driverLocations.set(driver_id, { lat, lng, ts: Date.now() });

      if (order_id) io.to(`order_${order_id}`).emit("order:driver_location", data);
    });

    socket.on("order:join", data => {
      socket.join(`order_${data.order_id}`);
    });
  });

  return io;
}

function getIO() {
  return io;
}

module.exports = { initSocket, getIO, driverLocations };
