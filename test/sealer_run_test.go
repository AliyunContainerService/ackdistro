package test

import (
	"strconv"
	"strings"

	. "github.com/onsi/ginkgo"

	"ackdistro/test/suites/apply"
	"ackdistro/test/testhelper"
	"ackdistro/test/testhelper/settings"
)

var _ = Describe("sealer run", func() {
	Context("run on ali cloud", func() {
		AfterEach(func() {
			apply.DeleteClusterByFile(settings.GetClusterWorkClusterfile(settings.ClusterNameForRun))
		})

		It("exec sealer run", func() {
			master := strconv.Itoa(1)
			node := strconv.Itoa(1)
			apply.SealerRun(master, node, "", settings.AliCloud)
			apply.CheckNodeNumLocally(2)
		})

	})

	Context("run on bareMetal", func() {
		var tempFile string
		BeforeEach(func() {
			tempFile = testhelper.CreateTempFile()
		})

		AfterEach(func() {
			testhelper.RemoveTempFile(tempFile)
		})

		It("bareMetal run", func() {
			rawCluster := apply.LoadClusterFileFromDisk(apply.GetRawClusterFilePath())
			By("start to prepare infra")
			usedCluster := apply.CreateAliCloudInfraAndSave(rawCluster, tempFile)
			//defer to delete cluster
			defer func() {
				apply.CleanUpAliCloudInfra(usedCluster)
			}()
			sshClient := testhelper.NewSSHClientByCluster(usedCluster)
			testhelper.CheckFuncBeTrue(func() bool {
				err := sshClient.SSH.Copy(sshClient.RemoteHostIP, settings.DefaultSealerBin, settings.DefaultSealerBin)
				return err == nil
			}, settings.MaxWaiteTime)

			By("start to init cluster", func() {
				masters := strings.Join(usedCluster.Spec.Masters.IPList, ",")
				nodes := strings.Join(usedCluster.Spec.Nodes.IPList, ",")
				apply.SendAndRunCluster(sshClient, tempFile, masters, nodes, usedCluster.Spec.SSH.Passwd)
				apply.CheckNodeNumWithSSH(sshClient, 2)
			})

		})
	})
})
