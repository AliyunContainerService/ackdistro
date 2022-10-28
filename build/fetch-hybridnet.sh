#!/usr/bin/env bash

# Pull hybridnet helm charts
export HYBRIDNET_CHART_VERSION=0.5.7

helm repo add hybridnet https://alibaba.github.io/hybridnet/
helm repo update
helm pull hybridnet/hybridnet --version=$HYBRIDNET_CHART_VERSION
tar -zxvf hybridnet-$HYBRIDNET_CHART_VERSION.tgz
rm -f hybridnet-$HYBRIDNET_CHART_VERSION.tgz
