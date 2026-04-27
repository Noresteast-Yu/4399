const mongoose = require('mongoose');

const TravelAlertSchema = new mongoose.Schema({
  type: {
    type: String,
    required: true,
    enum: ['delay', 'control', 'accident', 'other']
  },
  title: {
    type: String,
    required: true
  },
  message: {
    type: String,
    required: true
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  affectedRoutes: [
    {
      type: String
    }
  ]
});

module.exports = mongoose.model('TravelAlert', TravelAlertSchema);