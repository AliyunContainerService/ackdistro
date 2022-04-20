// Copyright © 2021 Alibaba Group Holding Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package settings

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/mitchellh/go-homedir"
)

const (
	DefaultRegistryAuthFileDir        = "/root/.docker"
)

const (
	BAREMETAL         = "BAREMETAL"
	AliCloud          = "ALI_CLOUD"
	ClusterNameForRun = "my-cluster"
	ClusterWorkDir    = "/root/.sealer/%s"
)

var (
	DefaultPollingInterval time.Duration
	MaxWaiteTime           time.Duration
	DefaultWaiteTime       time.Duration
	DefaultEnv             = "PodCIDR=172.45.0.0/16,SvcCIDR=10.96.0.0/16,Network=calico,EtcdDevice=/dev/vdb,DockerRunDiskSize=200,KubeletRunDiskSize=200,StorageDevice=/dev/vdc,YodaDevice=/dev/vdc3"
	DefaultSealerBin       = ""
	DefaultTestEnvDir      = ""
	RegistryURL            = os.Getenv("REGISTRY_URL")
	RegistryUsername       = os.Getenv("REGISTRY_USERNAME")
	RegistryPasswd         = os.Getenv("REGISTRY_PASSWORD")
	TestImageName      = "ack-distro:test" //default: registry.cn-qingdao.aliyuncs.com/sealer-io/kubernetes:v1.19.8
)

func GetClusterWorkDir(clusterName string) string {
	home, err := homedir.Dir()
	if err != nil {
		return fmt.Sprintf(ClusterWorkDir, clusterName)
	}
	return filepath.Join(home, ".sealer", clusterName)
}

func GetClusterWorkClusterfile(clusterName string) string {
	return filepath.Join(GetClusterWorkDir(clusterName), "Clusterfile")
}
