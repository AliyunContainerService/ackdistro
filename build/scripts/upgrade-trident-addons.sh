#! /bin/bash

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

set -x

source "${scripts_path}"/default_values.sh

helm_install_hybridnet() {
  for i in `seq 1 3`;do
    sleep 1
    helm -n kube-system upgrade -i --reuse-values $1 chart/$1 -f /tmp/ackd-helmconfig.yaml --set init=null --set daemon.enableFelixPolicy=true --set typha.serverPort=5473 --set images.hybridnet.image=ecp_builder/hybridnet --set images.hybridnet.tag=v0.8.5 && return 0
  done
  return 1
}

# Apply yamls
sed "s/##DNSDomain##/${DNSDomain}/g" ack-distro-yamls/coredns-cm.yaml | sed "s/##REGISTRY_IP##/${RegistryIP}/g" | sed "s/##REGISTRY_DOMAIN##/${RegistryDomain}/g" | kubectl apply -f -
kubectl apply -f ack-distro-yamls/apiserver-lb-svc.yaml
kubectl apply -f ack-distro-yamls/clusters.open-cluster-management.io_managedclusters.crd.yaml

# Prepare helm config
prepare_helm_config

# create etcd secret
create_etcd_secret || exit 1

if [ "${Network}" == "calico" ];then
  helm -n default upgrade calico --reuse-values /root/workspace/ecp/kube-current/addons/net-plugins/calico --set images.calicocni.image=ecp_builder/calico-cni  --set images.calicoflexvol.image=ecp_builder/calico-pod2daemon-flexvol --set images.caliconode.image=ecp_builder/calico-node --set images.calicocontrollers.image=ecp_builder/calico-kube-controllers
else
  if helm -n kube-system status hybridnet &>/dev/null;then
    # for vivo
    if [ "${HasRecreateOldHybridnet}" == "true" ] && [ "${UpgradeHybridnet}" == "true" ];then
      kubectl apply -f chart/hybridnet/crds/
      for i in `seq 1 3`;do
        sleep 1
        helm -n kube-system upgrade -i --reuse-values hybridnet chart/hybridnet -f /tmp/ackd-helmconfig.yaml --set init=null --set daemon.enableFelixPolicy=true --set typha.serverPort=5473 --set images.hybridnet.image=ecp_builder/hybridnet --set images.hybridnet.tag=v0.8.5 --set defaultIPRetain=false && break
      done
      if [ $? -ne 0 ]; then
        panic "failed to install hybridnet"
      fi
    else
      echo "HasRecreateOldHybridnet or UpgradeHybridnet not true, skipping upgrade hybridnet"
    fi
  elif helm -n default status hybridnet &>/dev/null || helm -n default status rama &>/dev/null;then
    kubectl -n kube-system annotate sa hybridnet meta.helm.sh/release-namespace=kube-system --overwrite
    kubectl -n kube-system annotate sa hybridnet meta.helm.sh/release-name=hybridnet --overwrite
    kubectl -n kube-system annotate clusterrole system:hybridnet meta.helm.sh/release-namespace=kube-system --overwrite
    kubectl -n kube-system annotate clusterrole system:hybridnet meta.helm.sh/release-name=hybridnet --overwrite
    kubectl -n kube-system annotate clusterrolebinding hybridnet meta.helm.sh/release-namespace=kube-system --overwrite
    kubectl -n kube-system annotate clusterrolebinding hybridnet meta.helm.sh/release-name=hybridnet --overwrite
    kubectl -n kube-system annotate cm hybridnet-cni-conf meta.helm.sh/release-namespace=kube-system --overwrite
    kubectl -n kube-system annotate cm hybridnet-cni-conf meta.helm.sh/release-name=hybridnet --overwrite

    kubectl -n kube-system delete ds hybridnet-daemon hybridnet-manager hybridnet-webhook
    kubectl -n kube-system delete svc hybridnet-webhook
    kubectl -n kube-system delete deploy hybridnet-manager hybridnet-webhook || true
    kubectl delete MutatingWebhookConfiguration hybridnet-mutating-webhook
    kubectl delete ValidatingWebhookConfiguration hybridnet-validating-webhook
    kubectl apply -f chart/hybridnet/crds/

    cat > /tmp/hybridnet-manager-0.5.yaml <<EOF
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
    kubectl apply -f /tmp/hybridnet-manager-0.5.yaml
    suc=false
    for i in `seq 1 24`;do
      sleep 5
      updatedReplicas=`kubectl -n kube-system get deploy hybridnet-manager -ojsonpath='{.status.updatedReplicas}'`
      availableReplicas=`kubectl -n kube-system get deploy hybridnet-manager -ojsonpath='{.status.availableReplicas}'`
      readyReplicas=`kubectl -n kube-system get deploy hybridnet-manager -ojsonpath='{.status.readyReplicas}'`
      if [ "$updatedReplicas" == "1" ] && [ "$availableReplicas" == "1" ] && [ "$readyReplicas" == "1" ];then
        suc=true
        break
      fi
    done

    if [ "$suc" != "true" ];then
      echo "failed to update hybridnet to v0.5.1"
      exit 1
    fi
    sleep 60
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
kubectl create ns cluster-local || true

if helm -n default status yoda;then
  helm -n default delete yoda
fi
kubectl delete crd nodelocalstorageinitconfigs.storage.yoda.io nodelocalstorages.storage.yoda.io || true
kubectl delete crd nodelocalstorageinitconfigs.csi.aliyun.com nodelocalstorages.csi.aliyun.com || true
kubectl apply -f chart/open-local/crds/
helm_install open-local || panic "failed to install open-local"
# set default storageclass and snapshot
kubectl annotate storageclass ${DefaultStorageClass} snapshot.storage.kubernetes.io/is-default-class="true" --overwrite
kubectl annotate storageclass ${DefaultStorageClass} storageclass.kubernetes.io/is-default-class="true" --overwrite

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

if helm -n default status etcd-backup;then
  helm -n default delete etcd-backup
fi
helm_install etcd-backup || panic "failed to install etcd-backup"

if helm -n default status cluster-operator;then
  helm -n default delete cluster-operator
fi

kubectl -n acs-system annotate opstask meta.helm.sh/release-namespace=kube-system --overwrite --all
helm_install l-zero-library || panic "failed to install l-zero-library"

# install optional addons
install_optional_addons ${Addons}

if [ "$Network" == "hybridnet" ] || [ "$Network" == "rama" ];then
  create_subnet "${HostIPFamily}" "$PodCIDR" "network-0" || exit 1
fi

for f in admin.conf controller-manager.conf scheduler.conf;do
  cp -n /etc/kubernetes/${f} /var/lib/sealer/data/my-cluster/rootfs/
done
cp -rn /etc/kubernetes/pki /var/lib/sealer/data/my-cluster/rootfs/

process_taints_labels "$RemoveMasterTaint" "$PlatformType" || exit 1

# generate cluster info
if [ "$GenerateClusterInfo" == "true" ];then
  gen_clusterinfo || exit 1
  GenerateCAFlag="--generate-ca"
fi

trident_process_init "$ComponentToInstall" "$PlatformCAPath" "$PlatformCAKeyPath" "$GenerateCAFlag"
if [ $? -ne 0 ];then
  exit 1
fi
