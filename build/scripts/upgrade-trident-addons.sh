#! /bin/bash

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

set -x

export DNSDomain=${DNSDomain:-cluster.local}
export HostIPFamily=${HostIPFamily:-4}
export EnableLocalDNSCache=${EnableLocalDNSCache:-false}
export MTU=${MTU:-1440}
export IPIP=${IPIP:-Always}
export IPv6DualStack=${IPv6DualStack:-true}
export IPAutoDetectionMethod=${IPAutoDetectionMethod:-can-reach=8.8.8.8}
export DisableFailureDomain=${DisableFailureDomain:-false}
export RegistryURL=${RegistryURL:-sea.hub:5000}
export RegistryDomain=${RegistryDomain}
export Addons=${Addons}
export Network=${Network}
export GenerateClusterInfo=${GenerateClusterInfo:-true}
export SuspendPeriodBroadcastHealthCheck=${SuspendPeriodBroadcastHealthCheck:-false}
export ParalbHostInterface=${ParalbHostInterface}
export deployMode=${deployMode:-offline}
export PlatformType=${PlatformType}
export gatewayDomain=${gatewayDomain:-cnstack.local}
if [ "$DisableGateway" != "true" ];then
  export gatewayExposeMode=${gatewayExposeMode:-ip_domain}
  export gatewayInternalIP=${gatewayInternalIP:-${Master0IP}}
  export gatewayExternalIP=${gatewayExternalIP:-${Master0IP}}
  export gatewayPort=${gatewayPort:-30383}
  export gatewayAPIServerPort=${gatewayAPIServerPort:-30384}
fi
export ingressAddress=${ingressAddress:-ingress.${gatewayDomain}}
export ingressInternalIP=${ingressInternalIP:-${Master0IP}}
export ingressExternalIP=${ingressExternalIP:-${Master0IP}}
export ingressHttpPort=${ingressHttpPort:-80}
export ingressHttpsPort=${ingressHttpsPort:-443}
export harborAddress=${harborAddress:-harbor.${gatewayDomain}}
export vcnsOssAddress=${vcnsOssAddress:-vcns-oss.${gatewayDomain}}
export apiServerInternalIP=${apiServerInternalIP}
export apiServerInternalPort=${apiServerInternalPort}
export KUBECONFIG=/etc/kubernetes/admin.conf
export DefaultStorageClass=${DefaultStorageClass:-yoda-lvm-default}

if [ "$Master0IP" == "" ];then
  echo "Master0IP is required"
  exit 1
fi
if [ "$HostIPFamily" == "6" ];then
  export SvcCIDR=${SvcCIDR:-4408:4003:10bb:6a01:83b9:6360:c66d:0000/112,10.96.0.0/16}
  export PodCIDR=${PodCIDR:-3408:4003:10bb:6a01:83b9:6360:c66d:0000/112,100.64.0.0/16}
else
  export SvcCIDR=${SvcCIDR:-10.96.0.0/16,4408:4003:10bb:6a01:83b9:6360:c66d:0000/112}
  if ! echo "$SvcCIDR" | grep ",";then
    export SvcCIDR=${SvcCIDR},4408:4003:10bb:6a01:83b9:6360:c66d:0000/112
  fi
  if [ "$Network" == "calico" ];then
    export PodCIDR=${PodCIDR:-100.64.0.0/16}
  else
    export PodCIDR=${PodCIDR:-100.64.0.0/16,3408:4003:10bb:6a01:83b9:6360:c66d:0000/112}
    if ! echo "$PodCIDR" | grep ",";then
      export PodCIDR=${PodCIDR},3408:4003:10bb:6a01:83b9:6360:c66d:0000/112
    fi
  fi
fi

OLD_IS_TRIDENT=false

helm_install() {
  for i in `seq 1 3`;do
    sleep 1
    helm -n kube-system upgrade -i --reuse-values $1 chart/$1 -f /tmp/ackd-helmconfig.yaml && return 0
  done
  return 1
}

helm_install_hybridnet() {
  for i in `seq 1 3`;do
    sleep 1
    helm -n kube-system upgrade -i --reuse-values $1 chart/$1 -f /tmp/ackd-helmconfig.yaml --set init=null && return 0
  done
  return 1
}

# Prepare envs
CoreDnsIP=`trident get-indexed-ip --cidr ${SvcCIDR%,*} --index 10` || panic "failed to get coredns svc ip"

YodaSchedulerSvcIP=`trident get-indexed-ip --cidr ${SvcCIDR%,*} --index 4` || panic "failed to get yoda svc ip"

# Apply yamls
#TODO, check guest coredns configuration and ask him to provide
for f in `ls ack-distro-yamls`;do
  sed "s/##DNSDomain##/${DNSDomain}/g" ack-distro-yamls/${f} | sed "s/##REGISTRY_DOMAIN##/${RegistryDomain}/g" | kubectl apply -f -
done

LocalDNSCacheIP=169.254.20.10
VtepAddressCIDRs="0.0.0.0/0,::/0"
if [ "$HostIPFamily" == "6" ];then
  LocalDNSCacheIP=fd00::aaaa::ffff:a
  VtepAddressCIDRs="::/0"
fi
NumOfMasters=$(kubectl get no -l node-role.kubernetes.io/master="" | grep -v NAME | wc -l)
MetricsServerReplicas=2
if [ $NumOfMasters -eq 1 ];then
  MetricsServerReplicas=1
fi

# Prepare helm config
cat >/tmp/ackd-helmconfig.yaml <<EOF
global:
  EnableLocalDNSCache: ${EnableLocalDNSCache}
  LocalDNSCacheIP: ${LocalDNSCacheIP}
  YodaSchedulerSvcIP: ${YodaSchedulerSvcIP}
  CoreDnsIP: ${CoreDnsIP}
  PodCIDR: ${PodCIDR}
  MTU: "${MTU}"
  IPIP: ${IPIP}
  IPAutoDetectionMethod: ${IPAutoDetectionMethod}
  DisableFailureDomain: ${DisableFailureDomain}
  RegistryURL: ${RegistryURL}
  SuspendPeriodHealthCheck: false
  SuspendPeriodBroadcastHealthCheck: ${SuspendPeriodBroadcastHealthCheck}
  NumOfMasters: ${NumOfMasters}
  IPv6DualStack: ${IPv6DualStack}
  IPVSExcludeCIDRs: 10.103.97.2/32,1248:4003:10bb:6a01:83b9:6360:c66d:0002/128
init:
  cidr: ${PodCIDR%,*}
  ipVersion: "${HostIPFamily}"
  ingressControllerVIP: "${ingressInternalIP}"
  apiServerVIP: "${apiServerInternalIP}"
  iamGatewayVIP: "${gatewayInternalIP}"
defaultIPFamily: IPv${HostIPFamily}
multiCluster: true
daemon:
  vtepAddressCIDRs: ${VtepAddressCIDRs}
  hostInterface: "${ParalbHostInterface}"
manager:
  replicas: ${NumOfMasters}
webhook:
  replicas: ${NumOfMasters}
typha:
  replicas: ${NumOfMasters}
metricsServer:
  replicas: ${MetricsServerReplicas}
EOF

# create etcd secret
for NS in kube-system acs-system;do
	if kubectl get secret etcd-client-cert -n ${NS};then
	  continue
	fi

	if ! kubectl create secret generic etcd-client-cert  \
    --from-file=ca.pem=/etc/kubernetes/pki/etcd/ca.crt --from-file=etcd-client.pem=/etc/kubernetes/pki/apiserver-etcd-client.crt  \
    --from-file=etcd-client-key.pem=/etc/kubernetes/pki/apiserver-etcd-client.key -n ${NS};then
    panic "failed to create etcd secret"
  fi
done

if [ "${Network}" == "calico" ];then
  if helm -n default status calico;then
    helm_install calico || panic "failed to install calico"
  else
    echo "failed to check calico exist"
    exit 1
  fi
else
  # for vivo
  if helm -n kube-system status hybridnet &>/dev/null;then
    kubectl apply -f chart/hybridnet/crds/
    helm_install_hybridnet hybridnet || panic "failed to install hybridnet"
  elif helm -n default status rama &>/dev/null;then
    kubectl -n kube-system annotate sa hybridnet meta.helm.sh/release-namespace=kube-system --overwrite
    kubectl -n kube-system annotate sa hybridnet meta.helm.sh/release-name=hybridnet --overwrite
    kubectl -n kube-system annotate clusterrole system:hybridnet meta.helm.sh/release-namespace=kube-system --overwrite
    kubectl -n kube-system annotate clusterrole system:hybridnet meta.helm.sh/release-name=hybridnet --overwrite
    kubectl -n kube-system annotate clusterrolebinding hybridnet meta.helm.sh/release-namespace=kube-system --overwrite
    kubectl -n kube-system annotate clusterrolebinding hybridnet meta.helm.sh/release-name=hybridnet --overwrite

    kubectl -n kube-system delete ds hybridnet-daemon hybridnet-manager hybridnet-webhook
    kubectl -n kube-system delete svc hybridnet-webhook
    kubectl delete MutatingWebhookConfiguration hybridnet-mutating-webhook
    kubectl delete ValidatingWebhookConfiguration hybridnet-validating-webhook
    kubectl apply -f chart/hybridnet/crds/

    kubectl apply -f -<<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    meta.helm.sh/release-name: hybridnet
    meta.helm.sh/release-namespace: kube-system
  generation: 4
  labels:
    app: hybridnet
    app.kubernetes.io/managed-by: Helm
    component: manager
  name: hybridnet-manager
  namespace: kube-system
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: hybridnet
      component: manager
  strategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: hybridnet
        component: manager
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: hybridnet
                component: manager
            topologyKey: kubernetes.io/hostname
      containers:
      - command:
        - /hybridnet/hybridnet-manager
        - --default-ip-retain=true
        - --controller-concurrency=Pod=1,IPAM=1,IPInstance=1
        - --feature-gates=DualStack=true
        - --kube-client-qps=300
        - --kube-client-burst=600
        - --metrics-port=9899
        env:
        - name: DEFAULT_NETWORK_TYPE
          value: Overlay
        - name: DEFAULT_IP_FAMILY
          value: IPv4
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        image: ${RegistryURL}/ecp_builder/hybridnet:v0.5.1
        imagePullPolicy: IfNotPresent
        name: hybridnet-manager
        ports:
        - containerPort: 9899
          hostPort: 9899
          name: http-metrics
          protocol: TCP
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      hostNetwork: true
      nodeSelector:
        node-role.kubernetes.io/master: ""
      priorityClassName: system-cluster-critical
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: hybridnet
      serviceAccountName: hybridnet
      terminationGracePeriodSeconds: 30
      tolerations:
      - effect: NoSchedule
        operator: Exists
EOF
    suc=false
    for i in `seq 1 24`;do
      sleep 5
      updatedReplicas=`kubectl -n kube-system get deploy hybridnet-manager -ojsonpath='{.status.updatedReplicas}'`
      availableReplicas=`kubectl -n kube-system get deploy hybridnet-manager -ojsonpath='{.status.availableReplicas}'`
      readyReplicas=`kubectl -n kube-system get deploy hybridnet-manager -ojsonpath='{.status.readyReplicas}'`
      if [ "$updatedReplicas" == "1" ] && [ "$availableReplicas" == "1" ] && [ "$availableReplicas" == "1" ];then
        suc=true
        break
      fi
    done

    if [ "$suc" != "true" ];then
      echo "failed to update hybridnet to v0.5.1"
      exit 1
    fi
    helm_install_hybridnet hybridnet || panic "failed to install hybridnet"
  else
    echo "failed to check hybridnet exist"
    exit 1
  fi
fi

kubectl -n kube-system annotate psp ack.privileged meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate sa coredns kube-proxy metrics-server meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate cm kube-proxy-worker kube-proxy-master meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate clusterrole system:coredns ack:podsecuritypolicy:privileged  meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate clusterrolebinding system:coredns ack:podsecuritypolicy:authenticated kubeadm:node-proxier metrics-server  meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate service kube-dns heapster  metrics-server meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate ds coredns kube-proxy-master kube-proxy-worker meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate deploy metrics-server meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate APIService v1beta1.metrics.k8s.io meta.helm.sh/release-namespace=kube-system --overwrite
helm_install kube-core || panic "failed to install kube-core"

if helm -n default status yoda;then
  helm -n default delete yoda
fi
kubectl delete crd nodelocalstorageinitconfigs.storage.yoda.io nodelocalstorages.storage.yoda.io || true
kubectl delete crd nodelocalstorageinitconfigs.csi.aliyun.com nodelocalstorages.csi.aliyun.com || true
cp -f chart/open-local/values-acka.yaml chart/open-local/values.yaml
kubectl apply -f chart/open-local/crds/
helm_install open-local || panic "failed to install open-local"

kubectl -n kube-system annotate sa l-zero meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate cm l0-utils l0-pyutils meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate clusterrole l-zero-admin l-zero:cluster-role meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate clusterrolebinding l-zero-admin  meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate service l-zero l-zero-monitor-server meta.helm.sh/release-namespace=kube-system --overwrite
kubectl -n kube-system annotate deploy l-zero meta.helm.sh/release-namespace=kube-system --overwrite
kubectl replace --force -f chart/l-zero/crds/
helm_install l-zero || panic "failed to install l-zero"

helm_install csi-hostpath || panic "failed to install csi-hostpath"

kubectl -n acs-system annotate CronJob backup-etcd meta.helm.sh/release-namespace=kube-system --overwrite

helm_install etcd-backup || panic "failed to install etcd-backup"

kubectl -n acs-system annotate opstask meta.helm.sh/release-namespace=kube-system --overwrite --all
helm_install l-zero-library || panic "failed to install l-zero-library"

# install optional addons
IFS=,
for addon in ${Addons};do
  if [ "$addon" == "kube-prometheus-stack" ];then
    addon="kube-prometheus-crds"
  fi
  helm_install ${addon} || utils_info "failed to install ${addon}"
done
IFS="
"

kubectl create ns cluster-local || true

# sleep for hybridnet webhook ready
if kubectl get subnet init-2;then
  exit 0
fi

if [ "$IPv6DualStack" == "true" ];then
  secondFamily=6
  if [ "$HostIPFamily" == "6" ];then
    secondFamily=4
  fi
  cat >/tmp/subnet2.yaml <<EOF
---
apiVersion: networking.alibaba.com/v1
kind: Subnet
metadata:
  name: init-2
  labels:
    webhook.hybridnet.io/ignore: "true"
spec:
  config:
    autoNatOutgoing: true
  network: network-0
  range:
    cidr: ${PodCIDR##*,}
    version: "${secondFamily}"
EOF
  for i in `seq 1 16`;do
    kubectl apply -f /tmp/subnet2.yaml && break
    sleep 30
  done
  if [ $? -ne 0 ];then
    echo "failed to run kubectl apply -f /tmp/subnet2.yaml, ignore this, please apply it by yourself"
  fi

  kubectl -n kube-system delete pod -lk8s-app=kube-dns
fi

docker rm trident-registry || true

for f in admin.conf controller-manager.conf scheduler.conf;do
  cp -n /etc/kubernetes/${f} /var/lib/sealer/data/my-cluster/rootfs/
done
cp -rn /etc/kubernetes/pki /var/lib/sealer/data/my-cluster/rootfs/


gatewayAddress=${gatewayDomain}
if [ "$gatewayExposeMode" == "ip" ];then
  if [[ ${gatewayExternalIP} =~ ":" ]];then
    gatewayAddress=[${gatewayExternalIP}]
  else
    gatewayAddress=${gatewayExternalIP}
  fi
fi

# generate cluster info
if [ "$GenerateClusterInfo" == "true" ];then
  cat >/tmp/clusterinfo-cm.yaml <<EOF
---
apiVersion: v1
data:
  deployMode: "${deployMode}"
  gatewayExposeMode: "${gatewayExposeMode}"
  gatewayAddress: "${gatewayAddress}"
  gatewayDomain: "${gatewayDomain}"
  gatewayExternalIP: "${gatewayExternalIP}"
  gatewayInternalIP: "${gatewayInternalIP}"
  gatewayPort: "${gatewayPort}"
  gatewayAPIServerPort: "${gatewayAPIServerPort}"
  ingressAddress: "${ingressAddress}"
  ingressExternalIP: "${ingressExternalIP}"
  ingressInternalIP: "${ingressInternalIP}"
  ingressHttpPort: "${ingressHttpPort}"
  ingressHttpsPort: "${ingressHttpsPort}"
  harborAddress: "${harborAddress}"
  vcnsOssAddress: "${vcnsOssAddress}"
  clusterDomain: "${DNSDomain}"
  registryURL: "${LocalRegistryURL}"
  registryExternalURL: "${LocalRegistryDomain}:5001"
  RegistryURL: "${LocalRegistryURL}"
  platformType: "${PlatformType}"
  clusterName: "cluster-local"
kind: ConfigMap
metadata:
  name: clusterinfo
  namespace: kube-public
EOF

  kubectl apply -f /tmp/clusterinfo-cm.yaml
fi

if [ "${ComponentToInstall}" != "" ];then
  ComponentToInstallFlag="--component-to-install ${ComponentToInstall}"
fi
if [ "${PlatformCAPath}" != "" ];then
  PlatformCAFlag="--ca-path ${PlatformCAPath} --key-path ${PlatformCAKeyPath}"
fi
trident on-sealer -f /root/.sealer/Clusterfile --sealer --dump-managed-cluster ${GenerateCAFlag} ${ComponentToInstallFlag} ${PlatformCAFlag}
if [ $? -ne 0 ];then
  exit 1
fi

# set default storageclass and snapshot
kubectl annotate storageclass ${DefaultStorageClass} snapshot.storage.kubernetes.io/is-default-class="true" --overwrite
kubectl annotate storageclass ${DefaultStorageClass} storageclass.kubernetes.io/is-default-class="true" --overwrite
