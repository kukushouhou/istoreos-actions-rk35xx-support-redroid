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
    
    # --- 目标 1：Cgroup 基础配置（移除 Android 特有的 schedtune） ---
    sed -i '/CONFIG_CGROUP_SCHED/d' $KCONFIG
    echo "CONFIG_CGROUP_SCHED=y" >> $KCONFIG

    # --- 目标 2：Android Binder 和共享内存支持 ---
    sed -i '/CONFIG_ANDROID/d' $KCONFIG
    sed -i '/CONFIG_ASHMEM/d' $KCONFIG
    sed -i '/CONFIG_DMABUF_HEAPS/d' $KCONFIG
    sed -i '/CONFIG_UDMABUF/d' $KCONFIG
    echo "CONFIG_ANDROID=y" >> $KCONFIG
    echo "CONFIG_ANDROID_BINDER_IPC=y" >> $KCONFIG
    echo "CONFIG_ANDROID_BINDERFS=y" >> $KCONFIG
    echo "CONFIG_ANDROID_BINDER_DEVICES=\"binder,hwbinder,vndbinder\"" >> $KCONFIG
    echo "CONFIG_ASHMEM=y" >> $KCONFIG
    echo "CONFIG_DMABUF_HEAPS=y" >> $KCONFIG
    echo "CONFIG_DMABUF_HEAPS_CMA=y" >> $KCONFIG
    echo "CONFIG_UDMABUF=y" >> $KCONFIG

    # --- 目标 3：内存管理配置 (ashmem 和 dma-buf heaps) ---
    echo "CONFIG_IKCONFIG=y" >> $KCONFIG
    echo "CONFIG_IKCONFIG_PROC=y" >> $KCONFIG
    echo "CONFIG_MEMFD_CREATE=y" >> $KCONFIG
    echo "CONFIG_DMABUF_HEAPS=y" >> $KCONFIG
    
    # --- 目标 4：KVM 虚拟化支持 ---
    sed -i '/CONFIG_VIRTUALIZATION/d' $KCONFIG
    sed -i '/CONFIG_KVM/d' $KCONFIG
    sed -i '/CONFIG_VHOST_NET/d' $KCONFIG
    sed -i '/CONFIG_VHOST_VSOCK/d' $KCONFIG
    sed -i '/CONFIG_NVHE_EL2_DEBUG/d' $KCONFIG
    echo "CONFIG_VIRTUALIZATION=y" >> $KCONFIG
    echo "CONFIG_KVM=y" >> $KCONFIG
    echo "CONFIG_VHOST_NET=y" >> $KCONFIG
    echo "CONFIG_VHOST_VSOCK=y" >> $KCONFIG
    echo "# CONFIG_NVHE_EL2_DEBUG is not set" >> $KCONFIG
    
    echo "内核参数注入成功！"
else
    echo "警告: 未找到 $KCONFIG，请检查内核版本或路径！"
fi

# 3. 同时在 .config 中添加内核选项（确保编译时启用）
if [ -f ".config" ]; then
    echo "正在检查并注入 .config 内核选项..."
    
    # 检查是否需要添加配置（避免重复）
    NEED_ANDROID=0
    NEED_CGROUP=0
    NEED_KVM=0
    
    grep -q "CONFIG_KERNEL_ANDROID=y" .config || NEED_ANDROID=1
    grep -q "CONFIG_KERNEL_CGROUP_SCHED=y" .config || NEED_CGROUP=1
    grep -q "CONFIG_KERNEL_KVM=y" .config || NEED_KVM=1
    
    if [ $NEED_ANDROID -eq 1 ] || [ $NEED_CGROUP -eq 1 ] || [ $NEED_KVM -eq 1 ]; then
        echo "检测到缺少内核配置，正在注入..."
        
        # 删除旧的配置（如果有）
        sed -i '/CONFIG_KERNEL_ANDROID/d' .config
        sed -i '/CONFIG_KERNEL_CGROUP_SCHED/d' .config
        sed -i '/CONFIG_KERNEL_IKCONFIG/d' .config
        sed -i '/CONFIG_KERNEL_VIRTUALIZATION/d' .config
        sed -i '/CONFIG_KERNEL_KVM/d' .config
        
        # 添加完整的内核选项
        echo "CONFIG_KERNEL_ANDROID=y" >> .config
        echo "CONFIG_KERNEL_ANDROID_BINDER_IPC=y" >> .config
        echo "CONFIG_KERNEL_ANDROID_BINDERFS=y" >> .config
        echo "CONFIG_KERNEL_ASHMEM=y" >> .config
        
        echo "CONFIG_KERNEL_CGROUP_SCHED=y" >> .config
        
        echo "CONFIG_KERNEL_IKCONFIG=y" >> .config
        echo "CONFIG_KERNEL_IKCONFIG_PROC=y" >> .config
        
        echo "CONFIG_KERNEL_VIRTUALIZATION=y" >> .config
        echo "CONFIG_KERNEL_KVM=y" >> .config
        echo "CONFIG_KERNEL_VHOST_NET=y" >> .config
        echo "CONFIG_KERNEL_VHOST_VSOCK=y" >> .config
        
        echo ".config 注入成功！"
    else
        echo ".config 中已包含所需内核配置，跳过注入。"
    fi
fi