const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/smart-travel';

mongoose.connect(MONGODB_URI, {
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
})
  .then(() => console.log('数据库连接成功'))
  .catch(err => {
    console.warn('数据库连接失败，将使用模拟数据模式:', err.message);
  });

process.on('uncaughtException', (err) => {
  console.error('未捕获的异常:', err);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('未处理的Promise拒绝:', reason);
});

const routes = require('./routes');
app.use('/api', routes);

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', mode: mongoose.connection.readyState === 1 ? 'database' : 'mock' });
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`服务器运行在端口 ${PORT}`);
});

module.exports = app;