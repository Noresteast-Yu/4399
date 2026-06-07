package router

import (
	"smart-travel-backend/config"
	"smart-travel-backend/handlers"

	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", corsOrigin(c.Request.Header.Get("Origin")))
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

		indoorGuide := api.Group("/indoor-guide")
		{
			indoorGuide.GET("", handlers.GetIndoorGuide)
			indoorGuide.GET("/progress", handlers.GetIndoorGuideProgress)
		}

		indoorNavigation := api.Group("/indoor-navigation")
		{
			indoorNavigation.GET("/topology", handlers.GetIndoorStationTopology)
			indoorNavigation.GET("/path", handlers.GetIndoorNavigationPath)
		}

		highSpeedRail := api.Group("/high-speed-rail")
		{
			highSpeedRail.GET("/train/:trainNumber", handlers.GetTrainInfo)
			highSpeedRail.POST("/guide", handlers.GetTrainGuide)
		}

		commonRoutes := api.Group("/common-routes")
		{
			commonRoutes.GET("/user/:userId", handlers.GetCommonRoutes)
			commonRoutes.POST("/add", handlers.AddCommonRoute)
			commonRoutes.DELETE("/:id", handlers.DeleteCommonRoute)
		}

		data := api.Group("/data")
		{
			data.GET("/validate", handlers.ValidateData)
			data.GET("/static-resources", handlers.GetStaticResources)
		}

		users := api.Group("/users")
		{
			users.GET("/:userId/preferences", handlers.GetUserPreferences)
			users.PUT("/:userId/preferences", handlers.SaveUserPreferences)
			users.GET("/:userId/abilities", handlers.GetUserAbilities)
			users.PUT("/:userId/abilities/:abilityType", handlers.SaveUserAbility)
			users.GET("/:userId/luggage", handlers.GetUserLuggage)
			users.PUT("/:userId/luggage/:luggageType", handlers.SaveUserLuggage)
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

func corsOrigin(requestOrigin string) string {
	origins := []string{"*"}
	if config.AppConfig != nil && len(config.AppConfig.CORSOrigins) > 0 {
		origins = config.AppConfig.CORSOrigins
	}

	for _, origin := range origins {
		if origin == "*" {
			if requestOrigin != "" {
				return requestOrigin
			}
			return "*"
		}
		if origin == requestOrigin {
			return requestOrigin
		}
	}

	return origins[0]
}
