const mongoose = require('mongoose');

const MetroLineSchema = new mongoose.Schema({
  lineId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  lineName: {
    type: String,
    required: true,
    index: true
  },
  city: {
    type: String,
    required: true,
    default: '上海',
    index: true
  },
  colorName: {
    type: String,
    default: null
  },
  colorHex: {
    type: String,
    default: null
  },
  directions: {
    type: [String],
    default: []
  },
  description: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('MetroLine', MetroLineSchema);
