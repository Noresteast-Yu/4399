const mongoose = require('mongoose');

const TrainSchema = new mongoose.Schema({
  number: {
    type: String,
    required: true,
    unique: true
  },
  start: {
    type: String,
    required: true
  },
  end: {
    type: String,
    required: true
  },
  departure: {
    type: String,
    required: true
  },
  arrival: {
    type: String,
    required: true
  },
  platform: {
    type: String,
    required: true
  },
  doorDirection: {
    type: String,
    required: true
  },
  stations: [
    {
      type: String,
      required: true
    }
  ],
  carriages: [
    {
      number: String,
      type: String,
      distance: String
    }
  ]
});

module.exports = mongoose.model('Train', TrainSchema);