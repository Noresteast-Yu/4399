const mongoose = require('mongoose');

const TransferRuleSchema = new mongoose.Schema({
  ruleId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  originStationId: {
    type: String,
    required: true,
    ref: 'Station',
    index: true
  },
  lineId: {
    type: String,
    required: true,
    ref: 'MetroLine',
    index: true
  },
  targetStationId: {
    type: String,
    required: true,
    ref: 'Station',
    index: true
  },
  direction: {
    type: String,
    required: true
  },
  stopsCount: {
    type: Number,
    required: true
  },
  estimatedMinutes: {
    type: Number,
    required: true
  },
  transferLineIds: {
    type: [String],
    default: []
  },
  carriageSuggestion: {
    type: String,
    default: null
  },
  transferTip: {
    type: String,
    default: null
  },
  tags: {
    type: [String],
    default: []
  },
  dataLevel: {
    type: String,
    enum: ['demo', 'verified', 'manual'],
    default: 'demo'
  }
}, {
  timestamps: true
});

TransferRuleSchema.index({ originStationId: 1, lineId: 1 });

module.exports = mongoose.model('TransferRule', TransferRuleSchema);
