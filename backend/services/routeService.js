const Station = require('../models/Station');
const MetroLine = require('../models/MetroLine');
const LineStation = require('../models/LineStation');
const TransferRule = require('../models/TransferRule');

class RouteService {
  async planRoute(startStationName, endStationName) {
    try {
      const startStation = await this.findStation(startStationName);
      const endStation = await this.findStation(endStationName);

      if (!startStation || !endStation) {
        return {
          success: false,
          error: '未找到起点或终点站点',
          routes: []
        };
      }

      const routes = await this.findRoutes(startStation, endStation);

      return {
        success: true,
        routes: routes
      };
    } catch (error) {
      console.error('路线规划失败:', error);
      return {
        success: false,
        error: '路线规划失败',
        routes: []
      };
    }
  }

  async findStation(name) {
    const escapedName = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const station = await Station.findOne({
      $or: [
        { stationName: { $regex: escapedName, $options: 'i' } },
        { stationAlias: { $regex: escapedName, $options: 'i' } }
      ]
    });
    return station;
  }

  async findRoutes(startStation, endStation) {
    const routes = [];

    const startStationId = startStation.stationId;
    const endStationId = endStation.stationId;

    const startLines = await LineStation.find({ stationId: startStationId });
    const endLines = await LineStation.find({ stationId: endStationId });

    const startLineIds = [...new Set(startLines.map(ls => ls.lineId))];
    const endLineIds = [...new Set(endLines.map(ls => ls.lineId))];

    const startLineDetails = await MetroLine.find({ lineId: { $in: startLineIds } });
    const endLineDetails = await MetroLine.find({ lineId: { $in: endLineIds } });

    const startLineMap = {};
    startLineDetails.forEach(line => {
      startLineMap[line.lineId] = line;
    });
    const endLineMap = {};
    endLineDetails.forEach(line => {
      endLineMap[line.lineId] = line;
    });

    for (const startLineStation of startLines) {
      for (const endLineStation of endLines) {
        const startLineDetail = startLineMap[startLineStation.lineId];
        const endLineDetail = endLineMap[endLineStation.lineId];

        if (!startLineDetail || !endLineDetail) continue;

        if (startLineStation.lineId === endLineStation.lineId) {
          const directRoute = await this.findDirectRoute(
            startStation,
            endStation,
            startLineStation,
            endLineStation,
            startLineDetail
          );
          if (directRoute) {
            routes.push(directRoute);
          }
        } else {
          const transferRoutes = await this.findTransferRoutes(
            startStation,
            endStation,
            startLineStation,
            endLineStation,
            startLineDetail,
            endLineDetail
          );
          routes.push(...transferRoutes);
        }
      }
    }

    routes.sort((a, b) => a.totalTime - b.totalTime);

    return routes.slice(0, 3);
  }

  async findDirectRoute(startStation, endStation, startLineStation, endLineStation, lineDetail) {
    try {
      const lineId = startLineStation.lineId;
      const direction = startLineStation.direction;

      const startOrder = startLineStation.stationOrder;
      const endOrder = endLineStation.stationOrder;

      const stopsCount = Math.abs(endOrder - startOrder);
      
      const transferRule = await TransferRule.findOne({
        originStationId: startStation.stationId,
        lineId: lineId,
        targetStationId: endStation.stationId,
        direction: direction
      });

      const finalTime = transferRule ? transferRule.estimatedMinutes : Math.round(stopsCount * 1.5);

      const actualDirection = startOrder < endOrder ? direction : `往反方向`;

      return {
        title: '直达路线',
        totalTime: finalTime,
        time: `${finalTime}分钟`,
        transfers: 0,
        description: `AI 分析：${startStation.stationName}与${endStation.stationName}均在${lineDetail.lineName}上，无需换乘即可直达。全程约${finalTime}分钟，是最省时省力的方案。`,
        segments: [
          {
            type: 'walk',
            line: '步行',
            description: `从${startStation.stationName}到${startStation.stationName}站`,
            time: '3分钟',
            distance: '200m'
          },
          {
            type: 'subway',
            line: lineDetail.lineName,
            color: lineDetail.colorHex,
            description: `${startStation.stationName}站 → ${endStation.stationName}站`,
            time: `${finalTime}分钟`,
            stops: stopsCount
          },
          {
            type: 'walk',
            line: '步行',
            description: `从${endStation.stationName}地铁站到达目的地`,
            time: '3分钟',
            distance: '150m'
          }
        ]
      };
    } catch (error) {
      console.error('查找直达路线失败:', error);
      return null;
    }
  }

  async findTransferRoutes(startStation, endStation, startLineStation, endLineStation, startLineDetail, endLineDetail) {
    const routes = [];

    try {
      const transferStations = await this.findCommonTransferStations(
        startLineStation.lineId,
        endLineStation.lineId
      );

      for (const transferStation of transferStations) {
        const route = await this.buildTransferRoute(
          startStation,
          endStation,
          startLineStation,
          endLineStation,
          transferStation,
          startLineDetail,
          endLineDetail
        );
        if (route) {
          routes.push(route);
        }
      }
    } catch (error) {
      console.error('查找换乘路线失败:', error);
    }

    return routes;
  }

  async findCommonTransferStations(lineId1, lineId2) {
    const line1Stations = await LineStation.find({ lineId: lineId1, isTransfer: true })
      .distinct('stationId');
    const line2Stations = await LineStation.find({ lineId: lineId2, isTransfer: true })
      .distinct('stationId');

    return line1Stations.filter(stationId => line2Stations.includes(stationId));
  }

  async buildTransferRoute(
    startStation,
    endStation,
    startLineStation,
    endLineStation,
    transferStationId,
    startLineDetail,
    endLineDetail
  ) {
    try {
      const transferStation = await Station.findOne({ stationId: transferStationId });
      if (!transferStation) return null;

      const transferLineStation1 = await LineStation.findOne({
        lineId: startLineStation.lineId,
        stationId: transferStationId,
        direction: startLineStation.direction
      });

      const transferLineStation2 = await LineStation.findOne({
        lineId: endLineStation.lineId,
        stationId: transferStationId
      });

      if (!transferLineStation1 || !transferLineStation2) return null;

      const firstLegStops = Math.abs(transferLineStation1.stationOrder - startLineStation.stationOrder);
      const secondLegStops = Math.abs(endLineStation.stationOrder - transferLineStation2.stationOrder);

      const firstLegTime = Math.round(firstLegStops * 1.5);
      const secondLegTime = Math.round(secondLegStops * 1.5);
      const transferTime = 5;

      const totalTime = firstLegTime + transferTime + secondLegTime;

      return {
        title: '换乘路线',
        totalTime: totalTime,
        time: `${totalTime}分钟`,
        transfers: 1,
        description: `AI 分析：在${transferStation.stationName}换乘，虽然需要一次换乘，但可以到达目的地。全程约${totalTime}分钟。`,
        segments: [
          {
            type: 'walk',
            line: '步行',
            description: `从${startStation.stationName}到${startStation.stationName}站`,
            time: '3分钟',
            distance: '200m'
          },
          {
            type: 'subway',
            line: startLineDetail.lineName,
            color: startLineDetail.colorHex,
            description: `${startStation.stationName}站 → ${transferStation.stationName}站`,
            time: `${firstLegTime}分钟`,
            stops: firstLegStops
          },
          {
            type: 'walk',
            line: '站内换乘',
            description: `${transferStation.stationName}站换乘${endLineDetail.lineName}`,
            time: `${transferTime}分钟`,
            distance: '100m'
          },
          {
            type: 'subway',
            line: endLineDetail.lineName,
            color: endLineDetail.colorHex,
            description: `${transferStation.stationName}站 → ${endStation.stationName}站`,
            time: `${secondLegTime}分钟`,
            stops: secondLegStops
          },
          {
            type: 'walk',
            line: '步行',
            description: `从${endStation.stationName}地铁站到达目的地`,
            time: '3分钟',
            distance: '150m'
          }
        ]
      };
    } catch (error) {
      console.error('构建换乘路线失败:', error);
      return null;
    }
  }
}

module.exports = new RouteService();
