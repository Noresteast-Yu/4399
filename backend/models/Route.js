const mongoose = require('mongoose');

const RouteSchema = new mongoose.Schema({
  start: {
    type: String,
    required: true
  },
  end: {
    type: String,
    required: true
  },
  time: {
    type: String,
    required: true
  },
  distance: {
    type: String,
    required: true
  },
  userId: {
    type: String,
    required: false
  },
  segments: [
    {
      type: String,
      distance: String,
      time: String
    }
  ],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Route', RouteSchema);