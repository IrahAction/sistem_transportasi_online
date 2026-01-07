const { Sequelize, DataTypes } = require('sequelize');
const sequelize = new Sequelize(process.env.DATABASE_URL, { logging:false });

const User = sequelize.define('User', {
  user_id: { type: DataTypes.INTEGER, primaryKey:true, autoIncrement:true },
  name: DataTypes.STRING,
  email: { type: DataTypes.STRING, unique:true },
  password: DataTypes.STRING,
  role: DataTypes.ENUM('user','driver','merchant','admin')
}, { tableName: 'users', timestamps:false });

const Order = sequelize.define('Order', {
  order_id: { type: DataTypes.INTEGER, primaryKey:true, autoIncrement:true },
  user_id: DataTypes.INTEGER,
  driver_id: DataTypes.INTEGER,
  service_type: DataTypes.ENUM('GoRide','GoFood','GoSend'),
  merchant_id: DataTypes.INTEGER,
  origin: DataTypes.TEXT,
  destination: DataTypes.TEXT,
  distance_km: DataTypes.FLOAT,
  price: DataTypes.FLOAT,
  status: DataTypes.ENUM('pending','accepted','in_progress','completed','cancelled')
}, { tableName:'orders', timestamps:false });

const Payment = sequelize.define('Payment', {
  payment_id: { type: DataTypes.INTEGER, primaryKey:true, autoIncrement:true },
  order_id: DataTypes.INTEGER,
  method: DataTypes.STRING,
  amount: DataTypes.FLOAT,
  status: DataTypes.ENUM('pending','success','failed'),
  transaction_id: DataTypes.STRING
}, { tableName:'payments', timestamps:false });

const Vehicle = sequelize.define('Vehicle', {
  vehicle_id: { type: DataTypes.INTEGER, primaryKey:true, autoIncrement:true },
  driver_id: DataTypes.INTEGER,
  plate_no: DataTypes.STRING,
  type: DataTypes.STRING,
  brand: DataTypes.STRING,
  status: DataTypes.STRING
}, { tableName:'vehicles', timestamps:false });

module.exports = { sequelize, User, Order, Payment, Vehicle };
