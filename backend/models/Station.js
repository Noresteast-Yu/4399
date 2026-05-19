const mongoose = require('mongoose');

const StationSchema = new mongoose.Schema({
  stationId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  stationName: {
    type: String,
    required: true,
    index: true
  },
  stationAlias: {
    type: String,
    default: null
  },
  city: {
    type: String,
    required: true,
    default: '上海',
    index: true
  },
  district: {
    type: String,
    default: null
  },
  stationType: {
    type: String,
    required: true,
    default: '地铁站'
  },
  description: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Station', StationSchema);
