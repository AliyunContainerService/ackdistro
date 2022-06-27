package testhelper

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"time"

	"github.com/onsi/gomega"
	"sigs.k8s.io/yaml"

	"ackdistro/test/testhelper/settings"

	v1 "github.com/alibaba/sealer/types/api/v1"
	"github.com/alibaba/sealer/utils/ssh"
)

func GetPwd() string {
	pwd, err := os.Getwd()
	CheckErr(err)
	return pwd
}

func CreateTempFile() string {
	dir := os.TempDir()
	file, err := ioutil.TempFile(dir, "tmpfile")
	CheckErr(err)
	defer CheckErr(file.Close())
	return file.Name()
}

func RemoveTempFile(file string) {
	CheckErr(os.Remove(file))
}

func WriteFile(fileName string, content []byte) error {
	dir := filepath.Dir(fileName)
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		if err = os.MkdirAll(dir, settings.FileMode0755); err != nil {
			return err
		}
	}

	if err := ioutil.WriteFile(fileName, content, settings.FileMode0644); err != nil {
		return err
	}
	return nil
}

type SSHClient struct {
	RemoteHostIP string
	SSH          ssh.Interface
}

func NewSSHClientByCluster(usedCluster *v1.Cluster) *SSHClient {
	sshClient, err := ssh.NewSSHClientWithCluster(usedCluster)
	CheckErr(err)
	CheckNotNil(sshClient)
	return &SSHClient{
		RemoteHostIP: sshClient.Host,
		SSH:          sshClient.SSH,
	}
}

func MarshalYamlToFile(file string, obj interface{}) error {
	data, err := yaml.Marshal(obj)
	if err != nil {
		return err
	}
	if err = WriteFile(file, data); err != nil {
		return err
	}
	return nil
}

func CheckErr(err error) {
	gomega.Expect(err).NotTo(gomega.HaveOccurred())
}

func CheckNotNil(obj interface{}) {
	gomega.Expect(obj).NotTo(gomega.BeNil())
}

func CheckEqual(obj1 interface{}, obj2 interface{}) {
	gomega.Expect(obj1).To(gomega.Equal(obj2))
}

func CheckFuncBeTrue(f func() bool, t time.Duration) {
	gomega.Eventually(f(), t).Should(gomega.BeTrue())
}
