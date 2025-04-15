#!/bin/bash

# Thanks to clhex for the script (Github username: clhexftw)

kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
anykernel=$HOME/anykernel
builddir="${kernel_dir}/build"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image
kernel_name="GoreKernel_Vayu_nonksu"
zip_name="$kernel_name$(date +"%Y%m%d").zip"
CLANG_DIR=tc/clang
GCC64_DIR=tc/gcc64
GCC32_DIR=tc/gcc32
export CONFIG_FILE="vayu_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=@adams4d13
export KBUILD_BUILD_USER=arch-linux

export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"

# ZyC Clang 21.0
if ! [ -d "$CLANG_DIR" ]; then
    echo "Clonando ZyC Clang 21.0..."
    if ! git clone --depth=1 https://github.com/ZyCromerZ/clang.git -b 19.0.0git-20240306 $CLANG_DIR; then
        echo "¡Fallo al clonar ZyC Clang 21.0!"
        exit 1
    fi
fi

# GCC64
if ! [ -d "$GCC64_DIR" ]; then
    echo "Clonando GCC64..."
    git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git $GCC64_DIR
fi

# GCC32
if ! [ -d "$GCC32_DIR" ]; then
    echo "Clonando GCC32..."
    git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git $GCC32_DIR
fi

# Colores
NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'

make_defconfig()
{   
    START=$(date +"%s")
    echo -e ${LGR} "########### Generando Defconfig ############${NC}"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc --all)
}

compile()
{
    cd ${kernel_dir}
    echo -e ${LGR} "######### Compilando kernel #########${NC}"
   make -j$(nproc --all) \
  O=out \
  ARCH=arm64 \
  SUBARCH=arm64 \
  CC="ccache clang" \
  CLANG_TRIPLE=aarch64-linux-gnu- \
  CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
  CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
  OBJCOPY=llvm-objcopy \
  OBJDUMP=llvm-objdump \
  LD=ld.lld \
  AR=llvm-ar \
  NM=llvm-nm \
  LLVM=1 \
  LLVM_IAS=1 \
}

completion()
{
    cd ${objdir}
    COMPILED_IMAGE=arch/arm64/boot/Image
    COMPILED_DTBO=arch/arm64/boot/dtbo.img
    if [[ -f ${COMPILED_IMAGE} && ${COMPILED_DTBO} ]]; then
        git clone -q https://github.com/GXC2356/AnyKernel3.git -b master $anykernel
        mv -f $ZIMAGE ${COMPILED_DTBO} $anykernel
        cd $anykernel
        zip -r AnyKernel.zip *
        mv AnyKernel.zip $zip_name
        mv $anykernel/$zip_name $HOME/$zip_name
        rm -rf $anykernel
        echo -e ${LGR} "#### build completed successfully ####"
        exit 0
    else
        echo -e ${LGR} "#### failed to build some targets ####"
    fi
}

make_defconfig
compile | tee out/log.txt
completion
cd ${kernel_dir}
