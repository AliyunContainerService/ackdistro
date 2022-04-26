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
	BAREMETAL         = "BAREMETAL"
	AliCloud          = "ALI_CLOUD"
	DefaultImage      = "ack-distro:test"
)

var (
	DefaultPollingInterval time.Duration
	MaxWaiteTime           time.Duration
	DefaultWaiteTime       time.Duration
	DefaultSealerBin       = ""
	DefaultTestEnvDir      = ""
	CustomImageName        = os.Getenv("IMAGE_NAME")

	TestImageName      = "ack-distro:test" //default: registry.cn-qingdao.aliyuncs.com/sealer-io/kubernetes:v1.19.8
	CustomCalicoEnv    = "Network=calico"
	CustomhybridnetEnv = "Network=hybridnet"
	CalicoEnv		   = []string{"Network=calico"}
	HybridnetEnv	   = []string{"Network=hybridnet"}
)
