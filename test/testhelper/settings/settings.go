package settings

import (
	"os"
	"time"

	"github.com/alibaba/sealer/logger"
)

// init test params and settings
func init() {
	defaultWaiteTime := os.Getenv("DEFAULT_WAITE_TIME")
	if defaultWaiteTime == "" {
		DefaultWaiteTime = 300 * time.Second
	} else {
		DefaultWaiteTime, _ = time.ParseDuration(defaultWaiteTime)
	}

	maxWaiteTime := os.Getenv("MAX_WAITE_TIME")
	if maxWaiteTime == "" {
		MaxWaiteTime = 2400 * time.Second
	} else {
		MaxWaiteTime, _ = time.ParseDuration(maxWaiteTime)
	}

	pollingInterval := os.Getenv("DEFAULT_POLLING_INTERVAL")
	if pollingInterval == "" {
		DefaultPollingInterval = 10
	}
	logger.InitLogger(logger.Config{
		DebugMode: true,
	})
}
