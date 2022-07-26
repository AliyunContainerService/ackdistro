#!/bin/bash

utils_version_ge() {
  test "$(echo "$@" | tr ' ' '\n' | sort -rV | head -n 1)" == "$1"
}

# This function will display the message in red, and exit immediately.
panic()
{
    set +x
    echo -e "\033[1;31mPanic error: $@, please check this panic\033[0m"
    exit 1
    set -x
}

utils_info()
{
    echo -e "\033[1;32m$@\033[0m"
}

utils_command_exists() {
    command -v "$@" > /dev/null 2>&1
}

utils_arch_env() {
    ARCH=$(uname -m)
    case $ARCH in
        armv5*) ARCH="armv5" ;;
        armv6*) ARCH="armv6" ;;
        armv7*) ARCH="armv7" ;;
        aarch64) ARCH="arm64" ;;
        x86) ARCH="386" ;;
        x86_64) ARCH="amd64" ;;
        i686) ARCH="386" ;;
        i386) ARCH="386" ;;
    esac
}

utils_os_env() {
    ubu=$(cat /etc/issue | grep -i "ubuntu" | wc -l)
    debian=$(cat /etc/issue | grep -i "debian" | wc -l)
    cet=$(cat /etc/centos-release | grep "CentOS" | wc -l)
    redhat=$(cat /etc/redhat-release | grep "Red Hat" | wc -l)
    alios=$(cat /etc/redhat-release | grep "Alibaba" | wc -l)
    kylin=$(cat /etc/kylin-release | grep -E "Kylin" | wc -l)
    anolis=$(cat /etc/anolis-release | grep -E "Anolis" | wc -l)
    if [ "$ubu" == "1" ];then
        export OS="Ubuntu"
    elif [ "$cet" == "1" ];then
        export OS="CentOS"
    elif [ "$redhat" == "1" ];then
        export OS="RedHat"
    elif [ "$debian" == "1" ];then
        export OS="Debian"
    elif [ "$alios" == "1" ];then
        export OS="AliOS"
    elif [ "$kylin" == "1" ];then
        export OS="Kylin"
    elif [ "$anolis" == 1 ];then
        export OS="Anolis"
    else
       panic "unkown os...   exit"
    fi

    case "$OS" in
        CentOS)
            export OSVersion="$(cat /etc/centos-release | awk '{print $4}')"
            ;;
        AliOS)
            export OSVersion="$(cat /etc/alios-release | awk '{print $7}')"
            ;;
        Kylin)
            export OSVersion="$(cat /etc/kylin-release | awk '{print $6}')"
            ;;
        Anolis)
            export OSVersion="$(cat /etc/anolis-release | awk '{print $4}')"
            ;;
        *)
            echo -e "Not support get OS version of ${OS}"
    esac

    if [[ "$OS" == "CentOS" ]] || [[ "$OS" == "Anolis" ]] ||  [[ "$OS" == "AliOS" ]];then
        export OSRelease="el7"
        # vague compare: 8.x.xxx
        if [[ $OSVersion =~ ^8\..*$ ]];then
            export OSRelease="el8"
        fi
    fi
}

utils_shouldMkFs() {
    if [ "$1" != "" ] && [ "$1" != "/" ] && [ "$1" != "\"/\"" ];then
        return 0
    fi
    return 1
}