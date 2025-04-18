#!/bin/bash

# Kernel build script for Vayu (Poco X3 Pro)

kernel_dir="${PWD}"
objdir="${kernel_dir}/out"
output_dir="${kernel_dir}/output"
anykernel_dir="tc/anykernel"  # Ruta explícita para AnyKernel
kernel_name="GoreKernel_Vayu_nonksu"
zip_name="$kernel_name$(date +"%Y%m%d").zip"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image
CLANG_DIR="tc/clang"
GCC64_DIR="tc/gcc64"
GCC32_DIR="tc/gcc32"
MKDTBOIMG="tc/libufdt/utils/src/mkdtboimg.py"

export CONFIG_FILE="vayu_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=@adams4d13
export KBUILD_BUILD_USER=arch-linux
export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"

clone_tools() {
    [ -d "$CLANG_DIR" ] || {
        echo -e "${LYW}Cloning Crdroid Clang...${NC}"
        git clone -q --depth=1 --single-branch \
            https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git \
            -b 15.0 $CLANG_DIR || return 1
    }

    [ -d "$GCC64_DIR" ] || {
        echo -e "${LYW}Cloning GCC64...${NC}"
        git clone -q --depth=1 --single-branch \
            https://github.com/mvaisakh/gcc-arm64.git $GCC64_DIR || return 1
    }

    [ -d "$GCC32_DIR" ] || {
        echo -e "${LYW}Cloning GCC32...${NC}"
        git clone -q --depth=1 --single-branch \
            https://github.com/mvaisakh/gcc-arm.git $GCC32_DIR || return 1
    }

    [ -f "$MKDTBOIMG" ] || {
        echo -e "${LYW}Cloning libufdt...${NC}"
        git clone -q --depth=1 \
            https://android.googlesource.com/platform/system/libufdt tc/libufdt || return 1
    }
}

make_defconfig() {
    echo -e "${LGR}Generating Defconfig${NC}"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc)
}

compile() {
    echo -e "${LGR}######### Compilando kernel #########${NC}"
    make -j$(nproc) -l$(nproc) \
        O=out \
        ARCH=arm64 \
        CC="ccache clang" \
        SUBARCH=arm64 \
        DTC_EXT=dtc \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE=aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
        CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
        AR=llvm-ar \
        STRIP=llvm-strip \
        OBJCOPY=llvm-objcopy \
        OBJDUMP=llvm-objdump \
        READELF=llvm-readelf \
        HOSTCC=clang \
        HOSTCXX=clang++ \
        HOSTAR=llvm-ar \
        HOSTLD=ld.lld \
        LLVM_NM=llvm-nm \
        LD=ld.lld \
        NM=llvm-nm \
        LLVM=1 \
        LLVM_IAS=1
}

create_images() {
    python3 $MKDTBOIMG create $anykernel_dir/dtbo.img --page_size=4096 \
        out/arch/arm64/boot/dts/qcom/vayu-sm8150-overlay.dtbo
    find out/arch/arm64/boot/dts/qcom -name 'sm8150-v2*.dtb' -exec cat {} + > $anykernel_dir/dtb
    python3 $MKDTBOIMG create $anykernel_dir/dtbo-miui.img --page_size=4096 \
        out/arch/arm64/boot/dts/qcom/vayu-sm8150-overlay.dtbo
}

finalize_build() {
    cd ${objdir}
    ZIMAGE=arch/arm64/boot/Image
    COMPILED_DTBO=arch/arm64/boot/dtbo.img
    if [[ -f "${ZIMAGE}" && -f "${COMPILED_DTBO}" ]]; then
        echo -e "${LGR}Build successful!${NC}"
        
        if [ ! -d "$anykernel_dir" ]; then
            echo -e "${LYW}Cloning AnyKernel3 to tc/anykernel...${NC}"
            git clone -q https://github.com/adamspaini/AnyKernel3.git -b master $anykernel_dir
        else
            echo -e "${LYW}Updating AnyKernel in tc/anykernel...${NC}"
            (cd $anykernel_dir && git pull -q)
        fi

        cp -v "${ZIMAGE}" "${COMPILED_DTBO}" "$anykernel_dir/"
        
        mkdir -p "$output_dir"
        (cd "$anykernel_dir" && zip -r9 "$output_dir/${zip_name}" *)
        #!/bin/bash

# Kernel build script for Vayu (Poco X3 Pro)

kernel_dir="${PWD}"
objdir="${kernel_dir}/out"
output_dir="${kernel_dir}/output"
anykernel_dir="tc/anykernel"  # Ruta explícita para AnyKernel
kernel_name="GoreKernel_Vayu_nonksu"
zip_name="$kernel_name$(date +"%Y%m%d").zip"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image
CLANG_DIR="tc/clang"
GCC64_DIR="tc/gcc64"
GCC32_DIR="tc/gcc32"
MKDTBOIMG="tc/libufdt/utils/src/mkdtboimg.py"

export CONFIG_FILE="vayu_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=@adams4d13
export KBUILD_BUILD_USER=arch-linux
export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"

clone_tools() {
    [ -d "$CLANG_DIR" ] || {
        echo -e "${LYW}Cloning Crdroid Clang...${NC}"
        git clone -q --depth=1 --single-branch \
            https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git \
            -b 15.0 $CLANG_DIR || return 1
    }

    [ -d "$GCC64_DIR" ] || {
        echo -e "${LYW}Cloning GCC64...${NC}"
        git clone -q --depth=1 --single-branch \
            https://github.com/mvaisakh/gcc-arm64.git $GCC64_DIR || return 1
    }

    [ -d "$GCC32_DIR" ] || {
        echo -e "${LYW}Cloning GCC32...${NC}"
        git clone -q --depth=1 --single-branch \
            https://github.com/mvaisakh/gcc-arm.git $GCC32_DIR || return 1
    }

    [ -f "$MKDTBOIMG" ] || {
        echo -e "${LYW}Cloning libufdt...${NC}"
        git clone -q --depth=1 \
            https://android.googlesource.com/platform/system/libufdt tc/libufdt || return 1
    }
}

make_defconfig() {
    echo -e "${LGR}Generating Defconfig${NC}"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc)
}

compile() {
    echo -e "${LGR}######### Compilando kernel #########${NC}"
    make -j$(nproc) -l$(nproc) \
        O=out \
        ARCH=arm64 \
        CC="ccache clang" \
        SUBARCH=arm64 \
        DTC_EXT=dtc \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE=aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
        CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
        AR=llvm-ar \
        STRIP=llvm-strip \
        OBJCOPY=llvm-objcopy \
        OBJDUMP=llvm-objdump \
        READELF=llvm-readelf \
        HOSTCC=clang \
        HOSTCXX=clang++ \
        HOSTAR=llvm-ar \
        HOSTLD=ld.lld \
        LLVM_NM=llvm-nm \
        LD=ld.lld \
        NM=llvm-nm \
        LLVM=1 \
        LLVM_IAS=1
}

create_images() {
    python3 $MKDTBOIMG create $anykernel_dir/dtbo.img --page_size=4096 \
        out/arch/arm64/boot/dts/qcom/vayu-sm8150-overlay.dtbo
    find out/arch/arm64/boot/dts/qcom -name 'sm8150-v2*.dtb' -exec cat {} + > $anykernel_dir/dtb
    python3 $MKDTBOIMG create $anykernel_dir/dtbo-miui.img --page_size=4096 \
        out/arch/arm64/boot/dts/qcom/vayu-sm8150-overlay.dtbo
}

finalize_build() {
    cd ${objdir}
    ZIMAGE=arch/arm64/boot/Image
    COMPILED_DTBO=arch/arm64/boot/dtbo.img
    if [[ -f "${ZIMAGE}" && -f "${COMPILED_DTBO}" ]]; then
        echo -e "${LGR}Build successful!${NC}"
        
        if [ ! -d "$anykernel_dir" ]; then
            echo -e "${LYW}Cloning AnyKernel3 to tc/anykernel...${NC}"
            git clone -q https://github.com/adamspaini/AnyKernel3.git -b master $anykernel_dir
        else
            echo -e "${LYW}Updating AnyKernel in tc/anykernel...${NC}"
            (cd $anykernel_dir && git pull -q)
        fi

        cp -v "${ZIMAGE}" "${COMPILED_DTBO}" "$anykernel_dir/"
        
        mkdir -p "$output_dir"
        (cd "$anykernel_dir" && zip -r9 "$output_dir/${zip_name}" *)
        
        echo -e "${LGR}Kernel ZIP: $output_dir/${zip_name}${NC}"
    else
        echo -e "${RED}Build failed! Missing:${NC}"
        [ -f "${ZIMAGE}" ] || echo -e "${RED}- ${ZIMAGE}${NC}"
        [ -f "${COMPILED_DTBO}" ] || echo -e "${RED}- ${COMPILED_DTBO}${NC}"
        exit 1
    fi
}

# Color definitions
NC='\033[0m'
RED='\033[0;31m'
LGR='\033[1;32m'
LYW='\033[1;33m'

echo -e "${LYW}Cleaning up space...${NC}"
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache 2>/dev/null

clone_tools || exit 1
make_defconfig
compile
create_images
finalize_build
cd ${kernel_dir}
        echo -e "${LGR}Kernel ZIP: $output_dir/${zip_name}${NC}"
    else
        echo -e "${RED}Build failed! Missing:${NC}"
        [ -f "${ZIMAGE}" ] || echo -e "${RED}- ${ZIMAGE}${NC}"
        [ -f "${COMPILED_DTBO}" ] || echo -e "${RED}- ${COMPILED_DTBO}${NC}"
        exit 1
    fi
}

# Color definitions
NC='\033[0m'
RED='\033[0;31m'
LGR='\033[1;32m'
LYW='\033[1;33m'

echo -e "${LYW}Cleaning up space...${NC}"
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache 2>/dev/null

clone_tools || exit 1
make_defconfig
compile
create_images
finalize_build
cd ${kernel_dir}
