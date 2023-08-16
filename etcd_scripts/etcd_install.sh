#!/bin/bash

set -eu

BASE_DIR=$(cd $(dirname ${0});pwd)
source "${BASE_DIR}/tools"

VERSION='3.4.20'
ETCD_ARCHIVE_NAME="etcd-v${VERSION}-linux-amd64.tar.gz"
ETCD_ARCHIVE_PATH="${BASE_DIR}/${ETCD_ARCHIVE_NAME}"
INSTALL_DIR='/usr/local/bin'

cd ${BASE_DIR}
log_output 'step.' "正在解压 ${ETCD_ARCHIVE_PATH}"
tar -xvf ${ETCD_ARCHIVE_NAME} >/dev/null
log_output 'ok' "解压成功"

log_output 'step.' "正在安装"
mv "etcd-v${VERSION}-linux-amd64"/etcd* ${INSTALL_DIR} 2>>/dev/null
log_output 'ok' "安装成功"

log_output 'step.' "正在创建 etcd 用户和运行所需目录"
useradd -M -s /sbin/nologin etcd
mkdir -p /etc/etcd/
mkdir -p /var/lib/etcd
chown -R etcd:etcd /var/lib/etcd/
log_output 'ok' "etcd 运行所需用户和目录创建完成"

log_output 'step.' "正在创建默认配置文件"
{
tee /etc/etcd/etcd.conf <<-'EOF'
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://172.5.1.110:2380"
ETCD_LISTEN_CLIENT_URLS="https://172.5.1.110:2379"
ETCD_NAME="etcd-01"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://172.5.1.110:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://172.5.1.110:2379"
ETCD_INITIAL_CLUSTER="etcd-01=https://172.5.1.110:2380,etcd-02=https://172.5.1.111:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
#[Security]
ETCD_CERT_FILE="/k8s_cert/etcd/etcd-server.pem"
ETCD_KEY_FILE="/k8s_cert/etcd/etcd-server-key.pem"
ETCD_TRUSTED_CA_FILE="/k8s_cert/ca.pem"
ETCD_PEER_CERT_FILE="/k8s_cert/etcd/etcd-server.pem"
ETCD_PEER_KEY_FILE="/k8s_cert/etcd/etcd-server-key.pem"
ETCD_PEER_TRUSTED_CA_FILE="/k8s_cert/ca.pem"
EOF
} >/dev/null
log_output 'ok' "默认配置文件创建成功"

log_output 'step.' "正在创建 unit 服务管理文件"
{
tee /etc/systemd/system/etcd.service <<-'EOF'
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
User=etcd
# 3.4 之前的版本需要指定加载的变量
# ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/local/bin/etcd --name=\"${ETCD_NAME}\" --data-dir=\"${ETCD_DATA_DIR}\" --listen-client-urls=\"${ETCD_LISTEN_CLIENT_URLS}\""
# 3.4 及之后的版本会自动识别加载的变量
ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/local/bin/etcd"
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
} >/dev/null
log_output 'ok' "unit 服务管理文件创建成功"
log_output 'end' "etcd 部署完成"
