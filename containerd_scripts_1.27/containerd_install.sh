#!/bin/bash

###
# options
#             -f : 强制安装 (覆盖已经安装过的版本)
#   --no-nerdctl : 不安装 nerdctl
#       --crictl : 安装 crictl ( 一般不需要安装, 安装 k8s 组件时会自动安装 crictl 工具 )
###

# 脚本初始化
set -e
cd $(dirname $0)
source "tools"

# 安装包信息
CONTAINERD_NAME="containerd-*"
CRICTL_NAME="crictl-*"
NERDCTL_NAME="nerdctl-*"
CNI_NAME="cni-*"
RUNC_NAME="runc*"

# 安装配置
INSTALL_DIR='/usr/local'
# ERROR_LOG_FILE="/tmp/$(echo $(basename ${0}))_$(date +'%F').log"

# 标记选项
FORCE=0
INSTALL_NERDCTL=1
INSTALL_CRICTL=0
LOCAL_REG=0

# 使用 if 判断参数是否定义时使用
# OPT_ARRAY=(
#     '-f'
#     '--nerdctl'
#     '--no-crictl'
# )

for opt in "$@"; do
    # 使用 if 判断参数是否定义
    # if ! [[ "${OPT_ARRAY[*]}" =~ "${opt}" ]]; then
    #     log_output 'error' "${opt} 选项未定义"
    #     exit 1
    # fi
    case ${opt} in
        '-f')
            FORCE=1
        ;;
        '--no-nerdctl')
            INSTALL_NERDCTL=0
        ;;
        '--crictl')
            INSTALL_CRICTL=1
        ;;
        *)
            # echo "${opt} 选项未定义"
            log_output 'error' "${opt} 选项未定义"
            exit 1
        ;;
    esac
done
# echo "-f : ${FORCE}"
# echo "--nerdctl : ${INSTALL_NERDCTL}"
# echo "--crictl  : ${INSTALL_CRICTL}"

if [ "${FORCE}" != '1' ] && exist_check "containerd"; then
    log_output 'error' "containerd 已经安装. 如需覆盖安装使用 -f 选项. 如果使用软件包管理器安装需要先进行卸载"
    exit 1
fi

# 消除旧的运行状态
# if systemctl is-active containerd.socket &>/dev/null; then systemctl stop containerd.socket; fi
if systemctl is-active containerd.service &>/dev/null; then systemctl stop containerd.service; fi

log_output 'step.' "部署 containerd"
tar -xvf ${CONTAINERD_NAME} -C "${INSTALL_DIR}" >/dev/null
log_output 'exit_code' "$?"
log_output 'step.' "创建 systemd 服务管理文件以及配置文件"
{
tee /usr/lib/systemd/system/containerd.service <<-'EOF'
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
# 默认读取 /etc/containerd/config.toml 配置文件，可以使用 --config 指定
ExecStart=/usr/local/bin/containerd
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
LimitMEMLOCK=infinity
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
} >/dev/null
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml
log_output 'info' "containerd 配置文件位置 /etc/containerd/config.toml"
log_output 'exit_code' "$?"
log_output 'step.' "修改配置文件 (适配 k8s)"
sed -r \
    -e "s#k8s.gcr.io|registry.k8s.io#registry.cn-hangzhou.aliyuncs.com/google_containers#g" \
    -e '/SystemdCgroup/s#false#true#g' \
    -e '/registry.mirrors\]/a[plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]\nendpoint = [\n"https://docker.mirrors.ustc.edu.cn/",\n"http://hub-mirror.c.163.com"\n]' \
    -i /etc/containerd/config.toml >/dev/null
log_output 'exit_code' "$?"

log_output 'step.' "部署 runc "
\cp ${RUNC_NAME} /usr/local/sbin/runc >/dev/null
chmod 755 /usr/local/sbin/runc
log_output 'exit_code' "$?"

if [ "${INSTALL_CRICTL}" = '1' ]; then
    log_output 'step.' "部署 crictl"
    tar -xvf ${CRICTL_NAME} -C /usr/local/bin >/dev/null
    log_output 'exit_code' "$?"
fi
log_output 'step.' "创建 crictl 配置文件"
{
tee /etc/crictl.yaml <<-'EOF'
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
} >/dev/null
log_output 'exit_code' "$?"

if [ "${INSTALL_NERDCTL}" = '1' ]; then
    log_output 'step.' "部署 cni 网络插件 ( nerdctl 使用 )"
    mkdir -p /opt/nerdctl_cni/bin
    tar -xvf ${CNI_NAME} -C /opt/nerdctl_cni/bin >/dev/null
    log_output 'exit_code' "$?"

    log_output 'step.' "创建 nerdctl 配置文件"
    mkdir -p /etc/nerdctl/
    {
tee /etc/nerdctl/nerdctl.toml <<EOF
address = "unix:///run/containerd/containerd.sock"
cni_path = "/opt/nerdctl_cni/bin"
insecure_registry = true
EOF
    } >/dev/null
    log_output 'exit_code' "$?"

    log_output 'step.' "部署 nerdctl"
    tar -xvf ${NERDCTL_NAME} -C /usr/local/bin/ >/dev/null
    log_output 'exit_code' "$?"
fi

systemctl --now enable containerd.service &>/dev/null
log_output 'exit_code' "$?"

log_output 'end' "containerd 部署成功"
