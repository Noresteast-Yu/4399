package router

import (
	"net/http"
	"strings"

	"smart-travel-backend/config"
	"smart-travel-backend/handlers"

	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	r.Use(func(c *gin.Context) {
		origin := allowedOrigin(c.GetHeader("Origin"))
		if origin != "" {
			c.Header("Access-Control-Allow-Origin", origin)
		}
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		c.Header("Access-Control-Allow-Credentials", "true")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
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

		api.GET("/indoor-guide", handlers.GetIndoorGuide)

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

func allowedOrigin(origin string) string {
	if config.AppConfig == nil {
		return "*"
	}

	for _, allowed := range config.AppConfig.CORSOrigins {
		if allowed == "*" {
			if origin != "" {
				return origin
			}
			return "*"
		}
		if origin != "" && strings.EqualFold(strings.TrimSpace(allowed), origin) {
			return origin
		}
	}
	return ""
}
