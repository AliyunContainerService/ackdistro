/*
Copyright 2021 alibaba.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package v2

import (
	"github.com/alibaba/sealer/common"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	v1 "github.com/alibaba/sealer/types/api/v1"
)

// NOTE: json tags are required.  Any new fields you add must have json tags for the fields to be serialized.

// ClusterSpec defines the desired state of Cluster
type ClusterSpec struct {
	// desired state of cluster
	// Important: Run "make" to regenerate code after modifying this file
	// Foo is an example field of Cluster. Edit Cluster_types.go to remove/update
	Image string `json:"image,omitempty"`
	// Why env not using map[string]string
	// Because some argument is list, like: CertSANS=127.0.0.1 CertSANS=localhost, if ENV is map, will merge those two values
	// but user want to config a list, using array we can convert it to {CertSANS:[127.0.0.1, localhost]}
	Env     []string `json:"env,omitempty"`
	CMDArgs []string `json:"cmd_args,omitempty"`
	CMD     []string `json:"cmd,omitempty"`
	Hosts   []Host   `json:"hosts,omitempty"`
	SSH     v1.SSH   `json:"ssh,omitempty"`
}

type Host struct {
	IPS   []string `json:"ips,omitempty"`
	Roles []string `json:"roles,omitempty"`
	//overwrite SSH config
	SSH v1.SSH `json:"ssh,omitempty"`
	//overwrite env
	Env []string `json:"env,omitempty"`
}

// ClusterStatus defines the observed state of Cluster
type ClusterStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "make" to regenerate code after modifying this file
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// Cluster is the Schema for the clusters API
type Cluster struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   ClusterSpec   `json:"spec,omitempty"`
	Status ClusterStatus `json:"status,omitempty"`
}

func (in *Cluster) GetMasterIPList() []string {
	return in.GetIPSByRole(common.MASTER)
}

func (in *Cluster) GetNodeIPList() []string {
	return in.GetIPSByRole(common.NODE)
}

func (in *Cluster) GetAllIPList() []string {
	return append(in.GetIPSByRole(common.MASTER), in.GetIPSByRole(common.NODE)...)
}

func (in *Cluster) GetMaster0IP() string {
	if len(in.Spec.Hosts) == 0 {
		return ""
	}
	if len(in.Spec.Hosts[0].IPS) == 0 {
		return ""
	}
	return in.Spec.Hosts[0].IPS[0]
}

func (in *Cluster) GetIPSByRole(role string) []string {
	var hosts []string
	for _, host := range in.Spec.Hosts {
		for _, hostRole := range host.Roles {
			if role == hostRole {
				hosts = append(hosts, host.IPS...)
				continue
			}
		}
	}
	return hosts
}
func (in *Cluster) GetAnnotationsByKey(key string) string {
	return in.Annotations[key]
}

func (in *Cluster) SetAnnotations(key, value string) {
	if in.Annotations == nil {
		in.Annotations = make(map[string]string)
	}
	in.Annotations[key] = value
}

// +kubebuilder:object:root=true
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// ClusterList contains a list of Cluster
type ClusterList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []Cluster `json:"items"`
}

func init() {
	SchemeBuilder.Register(&Cluster{}, &ClusterList{})
}
