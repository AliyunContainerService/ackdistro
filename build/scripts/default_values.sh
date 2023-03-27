#!/usr/bin/env bash

export Network=${Network:-hybridnet}
export DNSDomain=${DNSDomain:-cluster.local}
export HostIPFamily=${HostIPFamily:-4}
export Master0IP=${HostIP}
export RegistryIP=${RegistryIP:-${Master0IP}}
export EnableLocalDNSCache=${EnableLocalDNSCache:-true}
export MTU=${MTU:-1440}
export IPIP=${IPIP:-Always}
export IPv6DualStack=${IPv6DualStack:-true}
export IPAutoDetectionMethod=${IPAutoDetectionMethod:-can-reach=8.8.8.8}
export DisableFailureDomain=${DisableFailureDomain:-false}
export RegistryURL=${RegistryURL:-sea.hub:5000}
export SuspendPeriodHealthCheck=${SuspendPeriodHealthCheck:-false}
export SuspendPeriodBroadcastHealthCheck=${SuspendPeriodBroadcastHealthCheck:-false}
export DefaultStorageClass=${DefaultStorageClass:-yoda-lvm-default}
export GenerateClusterInfo=${GenerateClusterInfo:-true}
export deployMode=${deployMode:-offline}
export gatewayDomain=${gatewayDomain:-cnstack.local}
if [ "$DisableGateway" != "true" ]; then
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
export ClusterScale=${ClusterScale:-small}
export KUBECONFIG=/etc/kubernetes/admin.conf

if [ "$Master0IP" == "" ]; then
  echo "Master0IP is required"
  exit 1
fi
if [ "$HostIPFamily" == "6" ]; then
  export SvcCIDR=${SvcCIDR:-4408:4003:10bb:6a01:83b9:6360:c66d:0000/112,10.96.0.0/16}
  export PodCIDR=${PodCIDR:-3408:4003:10bb:6a01:83b9:6360:c66d:0000/112,100.64.0.0/16}
else
  export SvcCIDR=${SvcCIDR:-10.96.0.0/16,4408:4003:10bb:6a01:83b9:6360:c66d:0000/112}
  if ! echo "$SvcCIDR" | grep ",";then
    export SvcCIDR=${SvcCIDR},4408:4003:10bb:6a01:83b9:6360:c66d:0000/112
  fi
  if [ "$Network" == "calico" ]; then
    export PodCIDR=${PodCIDR:-100.64.0.0/16}
  else
    export PodCIDR=${PodCIDR:-100.64.0.0/16,3408:4003:10bb:6a01:83b9:6360:c66d:0000/112}
    if ! echo "$PodCIDR" | grep ",";then
      export PodCIDR=${PodCIDR},3408:4003:10bb:6a01:83b9:6360:c66d:0000/112
    fi
  fi
fi

if [ "${deployMode}" == "online" ]; then
  export gatewayExposeMode=ip
fi

export gatewayAddress=${gatewayDomain}
if [ "$gatewayExposeMode" == "ip" ]; then
  if [[ ${gatewayExternalIP} =~ ":" ]]; then
    export gatewayAddress=[${gatewayExternalIP}]
  else
    export gatewayAddress=${gatewayExternalIP}
  fi
fi

export CoreDnsIP=`trident get-indexed-ip --cidr ${SvcCIDR%,*} --index 10` || panic "failed to get coredns svc ip"
export YodaSchedulerSvcIP=`trident get-indexed-ip --cidr ${SvcCIDR%,*} --index 4` || panic "failed to get yoda svc ip"

export LocalDNSCacheIP=169.254.20.10
export VtepAddressCIDRs="0.0.0.0/0,::/0"
if [ "$HostIPFamily" == "6" ];then
  export LocalDNSCacheIP=fd00:aaaa::ffff:a
  export VtepAddressCIDRs="::/0"
fi
export NumOfMasters=$(kubectl get no -l node-role.kubernetes.io/master="" | grep -v NAME | wc -l)
export MetricsServerReplicas=2
if [ $NumOfMasters -eq 0 ] || [ "$NumOfMasters" == "" ];then
  echo "No master found, please check"
  exit 1
fi
if [ $NumOfMasters -eq 1 ];then
  export MetricsServerReplicas=1
fi

if echo "${ingressInternalIP}" | grep ",";then
  export ingressControllerVIP="${ingressInternalIP}"
elif echo "${ingressInternalIP}" | grep ":";then
  export ingressControllerVIP=",${ingressInternalIP}"
else
  export ingressControllerVIP="${ingressInternalIP},"
  if [ "$ingressControllerVIP" == "," ];then
    export ingressControllerVIP=""
  fi
fi
if echo "${apiServerInternalIP}" | grep ",";then
  export apiServerVIP="${apiServerInternalIP}"
elif echo "${apiServerInternalIP}" | grep ":";then
  export apiServerVIP=",${apiServerInternalIP}"
else
  export apiServerVIP="${apiServerInternalIP},"
  if [ "$apiServerVIP" == "," ];then
    export apiServerVIP=""
  fi
fi