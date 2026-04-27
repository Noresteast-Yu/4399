const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

// 加载环境变量
dotenv.config();

// 初始化Express应用
const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());

// 数据库连接（可选）
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/smart-travel';

mongoose.connect(MONGODB_URI)
  .then(() => console.log('数据库连接成功'))
  .catch(err => {
    console.warn('数据库连接失败，将使用模拟数据模式:', err.message);
  });

// 处理未捕获的异常
process.on('uncaughtException', (err) => {
  console.error('未捕获的异常:', err);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('未处理的Promise拒绝:', reason);
});

// 路由
const routes = require('./routes');
app.use('/api', routes);

// 健康检查
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', mode: mongoose.connection.readyState === 1 ? 'database' : 'mock' });
});

// 启动服务器
const server = app.listen(PORT, () => {
  console.log(`服务器运行在端口 ${PORT}`);
});

module.exports = app;