package router

import (
	"smart-travel-backend/handlers"

	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	r.GET("/health", handlers.HealthCheck)

	api := r.Group("/api")
	{
		routePlan := api.Group("/route-plan")
		{
			routePlan.POST("/plan", handlers.PlanRoute)
		}

		subway := api.Group("/subway-service")
		{
			subway.GET("/station/:stationId", handlers.GetStation)
			subway.GET("/station/:stationId/facilities", handlers.GetStationFacilities)
			subway.GET("/facilities", handlers.GetAllStationsFacilities)
			subway.GET("/lines", handlers.GetLines)
		}

		metro := api.Group("/metro")
		{
			metro.GET("/arrival", handlers.GetMetroArrival)
		}

		highSpeedRail := api.Group("/high-speed-rail")
		{
			highSpeedRail.GET("/train/:trainNumber", handlers.GetTrainInfo)
			highSpeedRail.POST("/guide", handlers.GetTrainGuide)
		}

		transferTime := api.Group("/transfer-time")
		{
			transferTime.POST("/start", handlers.StartTransfer)
			transferTime.GET("/update/:sessionId", handlers.GetTransferUpdate)
		}

		commonRoutes := api.Group("/common-routes")
		{
			commonRoutes.GET("/user/:userId", handlers.GetCommonRoutes)
			commonRoutes.POST("/add", handlers.AddCommonRoute)
			commonRoutes.DELETE("/:id", handlers.DeleteCommonRoute)
		}

		travelAlerts := api.Group("/travel-alerts")
		{
			travelAlerts.GET("", handlers.GetTravelAlerts)
			travelAlerts.GET("/:type", handlers.GetTravelAlerts)
		}

		feedback := api.Group("/feedback")
		{
			feedback.POST("/submit", handlers.SubmitFeedback)
		}
	}

	return r
}
