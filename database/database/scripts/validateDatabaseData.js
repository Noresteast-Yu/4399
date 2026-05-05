const { validateData } = require("../services/dataValidator")
const repository = require("../services/databaseRepository")

const result = validateData()

console.log("数据库/数据模块校验结果：")
console.log(JSON.stringify(result, null, 2))

if (!result.ok) {
  process.exitCode = 1
} else {
  console.log("\n接口示例：")
  console.log("GET /api/subway-service/lines")
  console.log(JSON.stringify(repository.listLines().slice(0, 3), null, 2))

  console.log("\nGET /api/subway-service/station/tongji_university")
  console.log(JSON.stringify(repository.getStationInfo("tongji_university"), null, 2))

  console.log("\nPOST /api/route-plan/plan")
  console.log(
    JSON.stringify(repository.getRoutePlans("上海虹桥火车站", "同济大学")[0], null, 2)
  )
}
