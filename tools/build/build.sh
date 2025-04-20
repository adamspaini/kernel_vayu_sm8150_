#!/bin/bash

# Thanks to Adam Spaini for the script (@adams4d13)

kernel_dir="${PWD}"
objdir="${kernel_dir}/out"
output_dir="${kernel_dir}/output"
anykernel_dir="${kernel_dir}/tc/anykernel"
kernel_name="GoreKernel_vayu_ksu"
zip_name="$kernel_name$(date +"%Y%m%d").zip"
ZIMAGE="${objdir}/arch/arm64/boot/Image"
CLANG_DIR="${kernel_dir}/tc/clang"
GCC64_DIR="${kernel_dir}/tc/gcc64"
GCC32_DIR="${kernel_dir}/tc/gcc32"
MKDTBOIMG="${kernel_dir}/tc/libufdt/utils/src/mkdtboimg.py"
DTBO_IMG="${anykernel_dir}/dtbo.img"
DISPLAY="arch/arm64/boot/dts/qcom/xiaomi/overlay/common/display"

export CONFIG_FILE="vayu_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=adams4d13
export KBUILD_BUILD_USER=arch-linux
export PATH="${CLANG_DIR}/bin:${GCC64_DIR}/bin:${GCC32_DIR}/bin:${PATH}"

# Colores
NC='\033[0m'
RED='\033[0;31m'
LGR='\033[1;32m'
LYW='\033[1;33m'

clone_tools() {
    echo -e "${LYW}Setting up toolchains...${NC}"
    
    mkdir -p "${kernel_dir}/tc"

    [ -d "$CLANG_DIR" ] || {
        echo -e "${LYW}Cloning Crdroid Clang...${NC}"
        git clone -q --depth=1 --single-branch \
            https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git \
            -b 15.0 "$CLANG_DIR"
    }

    [ -d "$GCC64_DIR" ] || {
        echo -e "${LYW}Cloning GCC64...${NC}"
        git clone -q --depth=1 --single-branch \
            https://github.com/mvaisakh/gcc-arm64.git "$GCC64_DIR"
    }

    [ -d "$GCC32_DIR" ] || {
        echo -e "${LYW}Cloning GCC32...${NC}"
        git clone -q --depth=1 --single-branch \
            https://github.com/mvaisakh/gcc-arm.git "$GCC32_DIR"
    }

    [ -f "$MKDTBOIMG" ] || {
        echo -e "${LYW}Cloning libufdt...${NC}"
        git clone -q --depth=1 \
            https://android.googlesource.com/platform/system/libufdt "${kernel_dir}/tc/libufdt"
    }

    if [ ! -d "$anykernel_dir" ]; then
        echo -e "${LYW}Cloning AnyKernel3 to tc/anykernel...${NC}"
        git clone -q https://github.com/adamspaini/AnyKernel3.git -b master "$anykernel_dir"
    else
        echo -e "${LYW}Updating AnyKernel in tc/anykernel...${NC}"
        (cd "$anykernel_dir" && git pull -q)
    fi

    # Integrar xusfs4Ksu
    echo -e "${LYW}Integrando xusfs4Ksu...${NC}"
    if [ ! -d "${kernel_dir}/xusfs4Ksu" ]; then
        git clone -q https://github.com/sluonquan/xusfs4Ksu.git "${kernel_dir}/xusfs4Ksu"
        bash "${kernel_dir}/xusfs4Ksu/install.sh" "${kernel_dir}"
    else
        echo -e "${LYW}xusfs4Ksu ya está integrado${NC}"
    fi

    # Aplicar parche de KernelSU
    git config --global user.email "bagaskara815@gmail.com"
    git config --global user.name "bagaskara815"
    echo -e "${LYW}Aplicando parche de KernelSU...${NC}"
    curl -sSL "https://gist.githubusercontent.com/bagaskara815/5aeb07f0d9031189871ffa362591b20f/raw/ksu.patch" -o "${kernel_dir}/ksu.patch"
    git -C "$kernel_dir" am ksu.patch || { echo "Fallo al aplicar el parche"; exit 1; }

    # Agregar KernelSU Next
    echo -e "${LYW}Integrando KernelSU Next...${NC}"
    curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next/kernel/setup.sh" | bash -

    # Agregar KernelSU Next-SUSFS
    echo -e "${LYW}Integrando KernelSU Next-SUSFS...${NC}"
    curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next-susfs/kernel/setup.sh" | bash -s next-susfs
}

make_defconfig() { ... }
compile() { ... }
miui() { ... }
create_images() { ... }
restore() { ... }
finalize_build() { ... }

echo -e "${LYW}Cleaning up space...${NC}"
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache 2>/dev/null

clone_tools
make_defconfig
compile
create_images
finalize_build

cd "${kernel_dir}"
