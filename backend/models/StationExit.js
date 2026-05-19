const mongoose = require('mongoose');

const StationExitSchema = new mongoose.Schema({
  exitId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  stationId: {
    type: String,
    required: true,
    ref: 'Station',
    index: true
  },
  exitName: {
    type: String,
    required: true
  },
  nearbyPlace: {
    type: String,
    default: null
  },
  guideTip: {
    type: String,
    default: null
  },
  isAccessible: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('StationExit', StationExitSchema);
