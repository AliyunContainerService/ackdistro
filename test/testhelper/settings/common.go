package settings

import (
	"os"
	"time"
)

const (
	FileMode0755 = 0755
	FileMode0644 = 0644
)
const (
	BAREMETAL    = "BAREMETAL"
	AliCloud     = "ALI_CLOUD"
	DefaultImage = "ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:test"
)

var (
	DefaultPollingInterval time.Duration
	MaxWaiteTime           time.Duration
	DefaultWaiteTime       time.Duration
	DefaultSealerBin       = ""
	DefaultTestEnvDir      = ""
	CustomImageName        = os.Getenv("IMAGE_NAME")
	LoadPath               = ""

	TestImageName      = "ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:test"
	CustomCalicoEnv    = "Network=calico"
	CustomhybridnetEnv = "Network=hybridnet"
	CalicoEnv          = []string{"Network=calico"}
	HybridnetEnv       = []string{"Network=hybridnet"}
)
