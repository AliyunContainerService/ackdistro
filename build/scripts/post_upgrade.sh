#!/usr/bin/env bash

set -x

if [ "${SkipHealthCheck}" = "true" ];then
  exit 0
fi
sleep 15
trident health-check
if [ $? -eq 0 ];then
  exit 0
fi
echo "First time health check fail, sleep 30 and try again"
sleep 30
trident health-check --trigger-mode OnlyUnsuccessful
if [ $? -eq 0 ];then
  exit 0
fi
echo "Second time health check fail, sleep 60 and try again"
sleep 60
trident health-check --trigger-mode OnlyUnsuccessful
exit $?