// server.js
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const http = require("http");

const authRoutes = require('./routes/auth');
const orderRoutes = require('./routes/order');
const menuRoutes = require('./routes/menu');
const paymentRoutes = require('./routes/payment');

const { sequelize } = require("./services/db");
const { initSocket } = require("./services/socket");

const app = express();
const server = http.createServer(app);

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ROUTES
app.use('/api/auth', authRoutes);
app.use('/api/order', orderRoutes);
app.use('/api/menu', menuRoutes);
app.use('/api/payment', paymentRoutes);

sequelize.authenticate().then(() => console.log("DB RUN"));

// START SOCKET
initSocket(server);

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => console.log(`API running on ${PORT}`));
