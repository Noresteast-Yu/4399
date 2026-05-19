const mongoose = require('mongoose');

const LineStationSchema = new mongoose.Schema({
  lineId: {
    type: String,
    required: true,
    ref: 'MetroLine',
    index: true
  },
  stationId: {
    type: String,
    required: true,
    ref: 'Station',
    index: true
  },
  direction: {
    type: String,
    required: true
  },
  stationOrder: {
    type: Number,
    required: true
  },
  isTransfer: {
    type: Boolean,
    default: false
  },
  transferLineIds: {
    type: [String],
    default: []
  },
  platformTip: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

LineStationSchema.index({ lineId: 1, direction: 1, stationOrder: 1 }, { unique: true });
LineStationSchema.index({ lineId: 1, direction: 1, stationId: 1 }, { unique: true });

module.exports = mongoose.model('LineStation', LineStationSchema);
