package test

import (
	"ackdistro/test/testhelper"
	"fmt"
	. "github.com/onsi/ginkgo"

	"ackdistro/test/suites/apply"
	"ackdistro/test/testhelper/settings"
)

var _ = Describe("sealer apply", func() {
	Context("start apply calico", func() {
		rawClusterFilePath := apply.GetRawClusterFilePath()
		rawCluster := apply.LoadClusterFileFromDisk(rawClusterFilePath)
		rawCluster.Spec.Image = settings.TestImageName
		rawCluster.Spec.Env = settings.CalicoEnv
		BeforeEach(func() {
			if rawCluster.Spec.Image != settings.TestImageName {
				//rawCluster imageName updated to customImageName
				rawCluster.Spec.Image = settings.TestImageName
				apply.MarshalClusterToFile(rawClusterFilePath, rawCluster)
			}
		})

		Context("check regular scenario that provider is bare metal, executes machine is master0", func() {
			var tempFile string
			BeforeEach(func() {
				tempFile = testhelper.CreateTempFile()
			})

			AfterEach(func() {
				testhelper.RemoveTempFile(tempFile)
			})
			It("init, clean up", func() {
				By("start to prepare infra")
				cluster := rawCluster.DeepCopy()
				cluster.Spec.Provider = settings.AliCloud
				cluster.Spec.Image = settings.TestImageName
				cluster = apply.CreateAliCloudInfraAndSave(cluster, tempFile)
				defer apply.CleanUpAliCloudInfra(cluster)
				sshClient := testhelper.NewSSHClientByCluster(cluster)
				testhelper.CheckFuncBeTrue(func() bool {
					err := sshClient.SSH.Copy(sshClient.RemoteHostIP, settings.DefaultSealerBin, settings.DefaultSealerBin)
					return err == nil
				}, settings.MaxWaiteTime)

				By("start to init cluster")
				fmt.Println("1111111111111")
				apply.GenerateClusterfile1(tempFile)
				fmt.Println("22222222222222")
				apply.SendAndApplyCluster(sshClient, tempFile)
				fmt.Println("333333333333333")
				apply.CheckNodeNumWithSSH(sshClient, 2)

				By("Wait for the cluster to be ready", func() {
					apply.WaitAllNodeRunningBySSH(sshClient.SSH,sshClient.RemoteHostIP)
				})
				By("start to delete cluster")
				err := sshClient.SSH.CmdAsync(sshClient.RemoteHostIP, apply.SealerDeleteCmd(tempFile))
				testhelper.CheckErr(err)
			})
		})
	})

	Context("start apply hybridnet", func() {
		rawClusterFilePath := apply.GetRawClusterFilePath()
		rawCluster := apply.LoadClusterFileFromDisk(rawClusterFilePath)
		rawCluster.Spec.Image = settings.TestImageName
		rawCluster.Spec.Env = settings.HybridnetEnv
		BeforeEach(func() {
			if rawCluster.Spec.Image != settings.TestImageName {
				//rawCluster imageName updated to customImageName
				rawCluster.Spec.Image = settings.TestImageName
				apply.MarshalClusterToFile(rawClusterFilePath, rawCluster)
			}
		})

		Context("check regular scenario that provider is bare metal, executes machine is master0", func() {
			var tempFile string
			BeforeEach(func() {
				tempFile = testhelper.CreateTempFile()
			})

			AfterEach(func() {
				testhelper.RemoveTempFile(tempFile)
			})
			It("init, clean up", func() {
				By("start to prepare infra")
				cluster := rawCluster.DeepCopy()
				cluster.Spec.Provider = settings.AliCloud
				cluster.Spec.Image = settings.TestImageName
				cluster = apply.CreateAliCloudInfraAndSave(cluster, tempFile)
				defer apply.CleanUpAliCloudInfra(cluster)
				sshClient := testhelper.NewSSHClientByCluster(cluster)
				testhelper.CheckFuncBeTrue(func() bool {
					err := sshClient.SSH.Copy(sshClient.RemoteHostIP, settings.DefaultSealerBin, settings.DefaultSealerBin)
					return err == nil
				}, settings.MaxWaiteTime)

				By("start to init cluster")
				fmt.Println("444444444444")
				apply.GenerateClusterfile1(tempFile)
				fmt.Println("555555555555")
				apply.SendAndApplyCluster(sshClient, tempFile)
				fmt.Println("666666666666")
				apply.CheckNodeNumWithSSH(sshClient, 2)

				By("Wait for the cluster to be ready", func() {
					apply.WaitAllNodeRunningBySSH(sshClient.SSH,sshClient.RemoteHostIP)
				})
				By("start to delete cluster")
				err := sshClient.SSH.CmdAsync(sshClient.RemoteHostIP, apply.SealerDeleteCmd(tempFile))
				testhelper.CheckErr(err)
			})
		})
	})
})
