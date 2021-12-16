# 社区
我们致力于将ACK Distro打造为一个稳定、好用的Kubernetes发行版，我们重视每一个用户的反馈，将在社区为ACK Distro提供长期支持。为了让我们可以更好地为您提供支持，请在提交Issue和Pull Request之前仔细阅读本文档。

## 意见反馈
您可以通过提交issue来向我们反馈您的使用体验，在提交issue之前，请检查已有的issue（链接），看看是否已经有其他用户反馈过同样的问题。如果确认没有，请依据issue（模板链接）格式来提交您的意见。

## 代码开发
除了意见反馈，我们也十分欢迎Feature/BugFix各种类型的代码贡献，来帮助ACK Distro完善。和其它的开源项目一样，任何开发者都可以通过fork & pull request的方式进行代码贡献。

### 1) FORK
点击项目右上角的【Fork】按钮，把alibaba/ackdistro放到自己的仓库中 如：yourname/ackdistro

### 2) CLONE
把fork后的项目clone到自己本地，如：git clone https://github.com/yourname/ackdistro

### 3) Set Remote upstream
把alibaba/ackdistro的代码更新到自己的仓库中：
```bash
git remote add upstream https://github.com/AliyunContainerService/ackdistro.git git remote set-url --push upstream no-pushing
```

更新主分支代码到自己的仓库可以用：
```bash
git pull upstream main # git pull <remote name> <branch name> git push
```
​
代码先提交到自己的仓库中，然后在仓库里点击【pull request】申请合并代码，之后在pull request中可以看到一个【signed the CLA】黄色按钮，点击【签署CLA】直至按钮变绿.

### 需求开发
可以到issue中寻找已经贴了kind/feature标签的任务，没有放到里程碑的需求说明正在讨论中，还未决定是否开发。建议认领已经放到里程碑内的需求。
​
如果你有一些新的需求，建议先开issue讨论，再进行代码开发。

### bug修复以及优化
任何可以优化的点都能进行pull request，如：文档不全、发现bug、排版问题、多余空格、错别字、健壮性处理、冗长代码重复代码、命名不规范、 丑陋代码等等。
