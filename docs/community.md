# Community

We are committed to making ACK Distro a stable and easy-to-use Kubernetes distribution. We value every user's feedback and will provide long-term support to ACK Distro in the community. Please read this document carefully before submitting Issue and Pull Request for better support.

## Feedback

You can give us feedback on your experience by submitting Issue. Before submitting issue, please check the existing issue (link) to see if other users have already given feedback on the same ones. If not, please follow the issue (template link) format to submit your comments.

## Code development

In addition to feedback, we also welcome Feature/BugFix code contributions of all types to help improve ACK Distro. As with other open source projects, any developer can contribute code through fork & pull requests.

### 1) FORK
Click the 【Fork】button, in the top right corner, put alibaba/ackdistro in your own repository, such as yourname/ackdistro

### 2) CLONE
Clone the fork project to the local

### 3) Set Remote upstream
Update the alibaba/ackdistro code, and put in your repository:


```bash
git remote add upstream https://github.com/alibaba/ackdistro.git git remote set-url --push upstream no-pushing
```


Update the master branch code to your repository for using:


```bash
git pull upstream main # git pull <remote name> <branch name> git push
```


The code is first submitted to the warehouse, and then click【pull request】to apply for consolidation of the code. Then you can see a yellow button 【signed the CLA】in PR, click it until the button turns green.

### Requirements development

You can look for tasks that have been tagged with kind/feature in the issue. Requirements that have not been placed in milestones indicate that they are under discussion and no decision has been made on whether to develop them. It is recommended to claim the requirements that have been placed in milestones. If you have some new requirements, it is recommended to open an issue to discuss them first before developing the code.

### Bug fixing and optimization

Pull requests can be made for any optimization idea, such as: incomplete documentation, bugs, typesetting problems, redundant spaces, typos, robust processing, redundant code duplication, nonstandard naming, ugly code, etc.
