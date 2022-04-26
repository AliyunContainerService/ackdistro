package test

import (
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"ackdistro/test/testhelper"
	"ackdistro/test/testhelper/settings"
	"github.com/alibaba/sealer/common"
)

func TestSealerTests(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "run sealer suite")
}

var _ = SynchronizedBeforeSuite(func() []byte {
	output, err := exec.LookPath("sealer")
	Expect(err).NotTo(HaveOccurred(), output)
	SetDefaultEventuallyTimeout(settings.DefaultWaiteTime)
	settings.DefaultSealerBin = output
	settings.DefaultTestEnvDir = testhelper.GetPwd()
	settings.TestImageName = settings.CustomImageName
	if settings.TestImageName == "" {
		settings.TestImageName = settings.DefaultImage
	}
	home := common.GetHomeDir()
	logcfg := `{	"Console": {
		"level": "DEBG",
		"color": true
	},
	"TimeFormat":"2006-01-02 15:04:05"}`
	err = ioutil.WriteFile(filepath.Join(home, ".sealer.json"), []byte(logcfg), os.ModePerm)
	Expect(err).NotTo(HaveOccurred())
	return nil
}, func(data []byte) {
	SetDefaultEventuallyTimeout(settings.DefaultWaiteTime)
})
