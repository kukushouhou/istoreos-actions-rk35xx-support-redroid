#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 修改openwrt登陆地址,把下面的 192.168.10.1 修改成你想要的就可以了
#sed -i 's/192.168.100.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# 修改主机名字，把 iStore OS 修改你喜欢的就行（不能纯数字或者使用中文）
# sed -i 's/OpenWrt/iStore OS/g' package/base-files/files/bin/config_generate

# ttyd 自动登录
# sed -i "s?/bin/login?/usr/libexec/login.sh?g" ${GITHUB_WORKSPACE}/openwrt/package/feeds/packages/ttyd/files/ttyd.config

# 添加自定义软件包
# echo '
# CONFIG_PACKAGE_luci-app-mosdns=y
# CONFIG_PACKAGE_luci-app-adguardhome=y
# CONFIG_PACKAGE_luci-app-openclash=y
# ' >> .config

# ==================== Redroid Android 支持配置 ====================
# 注入内核参数以支持 Android 容器运行

# 1. 确定内核配置文件路径 (针对 R68S/RK35xx)
KCONFIG="target/linux/rockchip/armv8/config-6.6"

# 2. 注入 Redroid 核心内核参数
if [ -f "$KCONFIG" ]; then
    echo "找到内核配置文件: $KCONFIG，正在注入 Android 支持参数..."
    
    # --- 目标 1：进程调度与 Cgroup ---
    sed -i '/CONFIG_CGROUP_SCHED/d' $KCONFIG
    echo "CONFIG_CGROUP_SCHED=y" >> $KCONFIG
    echo "CONFIG_CPUCTL=y" >> $KCONFIG
    echo "CONFIG_SCHEDTUNE=y" >> $KCONFIG
    echo "CONFIG_UCLAMP_TASK=y" >> $KCONFIG
    echo "CONFIG_UCLAMP_TASK_GROUP=y" >> $KCONFIG

    # --- 目标 2：Binder 原生集成 (原文已有部分，此处做强制确认) ---
    sed -i '/CONFIG_ANDROID_BINDER/d' $KCONFIG
    echo "CONFIG_ANDROID=y" >> $KCONFIG
    echo "CONFIG_ANDROID_BINDER_IPC=y" >> $KCONFIG
    echo "CONFIG_ANDROID_BINDERFS=y" >> $KCONFIG
    echo "CONFIG_ANDROID_BINDER_DEVICES=\"binder,hwbinder,vndbinder\"" >> $KCONFIG

    # --- 目标 3：内存与配置导出 (解决 zgrep 报错) ---
    echo "CONFIG_IKCONFIG=y" >> $KCONFIG
    echo "CONFIG_IKCONFIG_PROC=y" >> $KCONFIG
    echo "CONFIG_MEMFD_CREATE=y" >> $KCONFIG
    
    # --- 目标 4：KVM 虚拟化支持 ---
    echo "CONFIG_VIRTUALIZATION=y" >> $KCONFIG
    echo "CONFIG_KVM=y" >> $KCONFIG
    echo "CONFIG_VHOST_NET=y" >> $KCONFIG
    echo "CONFIG_VHOST_VSOCK=y" >> $KCONFIG
    
    echo "内核参数注入成功！"
else
    echo "警告: 未找到 $KCONFIG，请检查内核版本或路径！"
fi