package test

import (
	"ackdistro/test/suites/apply"
	"ackdistro/test/testhelper"
	"ackdistro/test/testhelper/settings"
	. "github.com/onsi/ginkgo"
	"strings"
	"time"
)

var _ = Describe("run hybirdnet", func() {
	Context("start apply hybirdnet", func() {
		rawClusterFilePath := apply.GetRawClusterFilePath()
		rawCluster := apply.LoadClusterFileFromDisk(rawClusterFilePath)
		rawCluster.Spec.Image = settings.TestImageName
		rawCluster.Spec.Env = settings.HybridnetEnv
		BeforeEach(func() {
			if rawCluster.Spec.Image != settings.TestImageName {
				rawCluster.Spec.Image = settings.TestImageName
				apply.MarshalClusterToFile(rawClusterFilePath, rawCluster)
			}
		})

		Context("executes machine is master0", func() {
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
				apply.GenerateClusterfile(tempFile)
				apply.SendAndApplyCluster(sshClient, tempFile)

				By("start to delete cluster")
				err := sshClient.SSH.CmdAsync(sshClient.RemoteHostIP, apply.SealerDeleteCmd(tempFile))
				testhelper.CheckErr(err)

				By("wait 20s")
				time.Sleep(20 * time.Second)

				By("sealer run hybirdnet")
				masters := strings.Join(cluster.Spec.Masters.IPList, ",")
				nodes := strings.Join(cluster.Spec.Nodes.IPList, ",")
				apply.SendAndRunHybirdnetCluster(sshClient, tempFile, masters, nodes, cluster.Spec.SSH.Passwd)
				apply.CheckNodeNumWithSSH(sshClient, 2)

				By("exec e2e test")
				//下载e2e && sshcmd文件并且给予sshcmd执行权限
				err = sshClient.SSH.CmdAsync(sshClient.RemoteHostIP, "wget https://sealer.oss-cn-beijing.aliyuncs.com/e2e/kubernetes_e2e_images_v1.20.0.tar.gz",
					"wget https://sealer.oss-cn-beijing.aliyuncs.com/e2e/sshcmd", "chmod 777 sshcmd", "")
				testhelper.CheckErr(err)

				//获取load.sh文件
				load := apply.GetLoadFile()
				testhelper.CheckFuncBeTrue(func() bool {
					err := sshClient.SSH.Copy(sshClient.RemoteHostIP, load, load)
					return err == nil
				}, settings.MaxWaiteTime)

				//master0执行load.sh,发送e2e文件到master && node节点，然后再执行load.sh
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

				//给定执行权限 && 下载并执行脚本
				err = sshClient.SSH.CmdAsync(sshClient.RemoteHostIP, "sudo cp .kube/config /tmp/kubeconfig", "chmod 777 /tmp/kubeconfig",
					"wget https://sealer.oss-cn-beijing.aliyuncs.com/e2e/run.sh", "wget https://sealer.oss-cn-beijing.aliyuncs.com/e2e/get-log.sh", "bash run.sh & bash get-log.sh")
				testhelper.CheckErr(err)
			})
		})
	})
})
