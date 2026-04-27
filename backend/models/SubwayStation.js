const mongoose = require('mongoose');

const SubwayStationSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  lines: [
    {
      type: String,
      required: true
    }
  ],
  firstTrain: {
    type: String,
    required: true
  },
  lastTrain: {
    type: String,
    required: true
  },
  interval: {
    type: String,
    required: true
  },
  facilities: [
    {
      name: String,
      icon: String,
      location: String
    }
  ],
  crowdLevels: [
    {
      time: String,
      level: String,
      color: String
    }
  ]
});

module.exports = mongoose.model('SubwayStation', SubwayStationSchema);