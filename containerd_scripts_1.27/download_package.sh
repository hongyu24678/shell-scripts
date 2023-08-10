#!/bin/bash

set -eux
cd "$(dirname $0)"

# 下载 cni 网络插件
# https://github.com/containernetworking/plugins
# wget "https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz"
wget "https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz"

# 下载 containerd
# https://github.com/containerd/containerd
# wget "https://github.com/containerd/containerd/releases/download/v1.7.0/containerd-1.7.0-linux-amd64.tar.gz"
wget "https://github.com/containerd/containerd/releases/download/v1.7.3/containerd-1.7.3-linux-amd64.tar.gz"

# 下载 crictl
# https://github.com/kubernetes-sigs/cri-tools
# wget "https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.26.1/crictl-v1.26.1-linux-amd64.tar.gz"
wget "https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.27.1/crictl-v1.27.1-linux-amd64.tar.gz"

# 下载 nerdctl
# https://github.com/containerd/nerdctl
# wget "https://github.com/containerd/nerdctl/releases/download/v1.3.1/nerdctl-1.3.1-linux-amd64.tar.gz"
wget "https://github.com/containerd/nerdctl/releases/download/v1.5.0/nerdctl-1.5.0-linux-amd64.tar.gz"

# 下载 runc
# https://github.com/opencontainers/runc
# wget "https://github.com/opencontainers/runc/releases/download/v1.1.6/runc.amd64"
wget "https://github.com/opencontainers/runc/releases/download/v1.1.8/runc.amd64"
