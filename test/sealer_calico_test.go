package test

import (
	"ackdistro/test/testhelper"
	. "github.com/onsi/ginkgo"
	"strings"
	"time"

	"ackdistro/test/suites/apply"
	"ackdistro/test/testhelper/settings"
)

var _ = Describe("run calico", func() {
	Context("start apply calico", func() {
		rawClusterFilePath := apply.GetRawClusterFilePath()
		rawCluster := apply.LoadClusterFileFromDisk(rawClusterFilePath)
		rawCluster.Spec.Image = settings.TestImageName
		rawCluster.Spec.Env = settings.CalicoEnv
		BeforeEach(func() {
			if rawCluster.Spec.Image != settings.TestImageName {
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
				//defer apply.CleanUpAliCloudInfra(cluster)
				sshClient := testhelper.NewSSHClientByCluster(cluster)
				testhelper.CheckFuncBeTrue(func() bool {
					err := sshClient.SSH.Copy(sshClient.RemoteHostIP, settings.DefaultSealerBin, settings.DefaultSealerBin)
					return err == nil
				}, settings.MaxWaiteTime)

				By("start to init cluster")
				apply.GenerateClusterfile(tempFile)
				apply.SendAndApplyCluster(sshClient, tempFile)

				By("start to delete cluster")
				err := sshClient.SSH.CmdAsync(sshClient.RemoteHostIP, apply.SealerDeleteCmd(tempFile))
				testhelper.CheckErr(err)

				//wait 20s
				By("wait 20s")
				time.Sleep(20 * time.Second)

				By("sealer run calico")
				masters := strings.Join(cluster.Spec.Masters.IPList, ",")
				nodes := strings.Join(cluster.Spec.Nodes.IPList, ",")
				apply.SendAndRunCluster(sshClient, tempFile, masters, nodes, cluster.Spec.SSH.Passwd)
				apply.CheckNodeNumWithSSH(sshClient, 6)

				By("exec e2e test")
				//download e2e && sshcmdfile and give sshcmd exec permissions
				err = sshClient.SSH.CmdAsync(sshClient.RemoteHostIP, "wget https://sealer.oss-cn-beijing.aliyuncs.com/e2e/kubernetes_e2e_images_v1.20.0.tar.gz",
					"wget https://sealer.oss-cn-beijing.aliyuncs.com/e2e/sshcmd", "chmod 777 sshcmd")
				testhelper.CheckErr(err)

				By("get load.sh file")
				load := apply.GetLoadFile()
				testhelper.CheckFuncBeTrue(func() bool {
					err := sshClient.SSH.Copy(sshClient.RemoteHostIP, load, load)
					return err == nil
				}, settings.MaxWaiteTime)

				By("master0 exec load.sh,send e2e file to master && node，then,exec load.sh")
				err = sshClient.SSH.CmdAsync(sshClient.RemoteHostIP, "bash load.sh", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Nodes.IPList[0]+
					" --mode 'scp' --local-path 'kubernetes_e2e_images_v1.20.0.tar.gz' --remote-path 'kubernetes_e2e_images_v1.20.0.tar.gz'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Nodes.IPList[1]+
					" --mode 'scp' --local-path 'kubernetes_e2e_images_v1.20.0.tar.gz' --remote-path 'kubernetes_e2e_images_v1.20.0.tar.gz'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Nodes.IPList[2]+
					" --mode 'scp' --local-path 'kubernetes_e2e_images_v1.20.0.tar.gz' --remote-path 'kubernetes_e2e_images_v1.20.0.tar.gz'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Masters.IPList[1]+
					" --mode 'scp' --local-path 'kubernetes_e2e_images_v1.20.0.tar.gz' --remote-path 'kubernetes_e2e_images_v1.20.0.tar.gz'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Masters.IPList[2]+
					" --mode 'scp' --local-path 'kubernetes_e2e_images_v1.20.0.tar.gz' --remote-path 'kubernetes_e2e_images_v1.20.0.tar.gz'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Nodes.IPList[0]+
					" --mode 'scp' --local-path 'load.sh' --remote-path 'load.sh'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Nodes.IPList[1]+
					" --mode 'scp' --local-path 'load.sh' --remote-path 'load.sh'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Nodes.IPList[2]+
					" --mode 'scp' --local-path 'load.sh' --remote-path 'load.sh'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Masters.IPList[1]+
					" --mode 'scp' --local-path 'load.sh' --remote-path 'load.sh'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Masters.IPList[2]+
					" --mode 'scp' --local-path 'load.sh' --remote-path 'load.sh'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Nodes.IPList[0]+
					" --cmd 'bash load.sh'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Nodes.IPList[1]+
					" --cmd 'bash load.sh'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Nodes.IPList[2]+
					" --cmd 'bash load.sh'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Masters.IPList[1]+
					" --cmd 'bash load.sh'", "./sshcmd --user root --passwd Sealer123 --host "+cluster.Spec.Masters.IPList[2]+
					" --cmd 'bash load.sh'")
				testhelper.CheckErr(err)

				By("give exec permissions && download and exec scripe")
				err = sshClient.SSH.CmdAsync(sshClient.RemoteHostIP, "sudo cp .kube/config /tmp/kubeconfig", "chmod 777 /tmp/kubeconfig",
					"wget https://sealer.oss-cn-beijing.aliyuncs.com/e2e/run.sh", "wget https://sealer.oss-cn-beijing.aliyuncs.com/e2e/get-log.sh", "wget https://sealer.oss-cn-beijing.aliyuncs.com/e2e/begin.sh")
				testhelper.CheckErr(err)

				By("exec run.sh && get-log.sh")
				err = sshClient.SSH.CmdAsync(sshClient.RemoteHostIP, "bash begin.sh")
				testhelper.CheckErr(err)
			})
		})
	})
})
