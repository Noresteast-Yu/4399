const trains = [
  {
    "number": "G102",
    "start": "北京南站",
    "end": "上海虹桥站",
    "departure": "08:00",
    "arrival": "13:00",
    "platform": "5",
    "doorDirection": "左侧",
    "stations": [
      "北京南站",
      "济南西站",
      "南京南站",
      "上海虹桥站"
    ],
    "carriages": [
      {
        "number": "1",
        "type": "商务座",
        "distance": "约100米"
      },
      {
        "number": "2-3",
        "type": "一等座",
        "distance": "约80米"
      },
      {
        "number": "4-15",
        "type": "二等座",
        "distance": "约60米"
      },
      {
        "number": "16",
        "type": "餐车",
        "distance": "约40米"
      },
      {
        "number": "17",
        "type": "无障碍车厢",
        "distance": "约20米"
      }
    ]
  }
]

module.exports = trains
