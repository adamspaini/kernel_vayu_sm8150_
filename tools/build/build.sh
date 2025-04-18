#!/bin/bash

# Configuración inicial
kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
output_dir="${kernel_dir}/output"
anykernel=$HOME/anykernel
builddir="${kernel_dir}/build"
kernel_name="GoreKernel_Vayu_nonksu"
zip_name="$kernel_name$(date +"%Y%m%d").zip"
CLANG_DIR=tc/clang
GCC64_DIR=tc/gcc64
GCC32_DIR=tc/gcc32
export CONFIG_FILE="vayu_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=@adams4d13
export KBUILD_BUILD_USER=arch-linux

# Archivos importantes (usar rutas absolutas)
ZIMAGE="${objdir}/arch/arm64/boot/Image"
DTBO_IMG="${objdir}/arch/arm64/boot/dtbo.img"

export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"

# Liberar espacio en GitHub Actions
echo "Liberando espacio en el runner..."
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache || true
df -h

# Clonar herramientas
clone_tools() {
    if ! [ -d "$CLANG_DIR" ]; then
        echo "Clonando Crdroid Clang..."
        git clone -q --depth=1 --single-branch https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git -b 15.0 $CLANG_DIR
    fi

    if ! [ -d "$GCC64_DIR" ]; then
        echo "Clonando GCC64..."
        git clone -q --depth=1 --single-branch https://github.com/mvaisakh/gcc-arm64.git $GCC64_DIR
    fi

    if ! [ -d "$GCC32_DIR" ]; then
        echo "Clonando GCC32..."
        git clone -q --depth=1 --single-branch https://github.com/mvaisakh/gcc-arm.git $GCC32_DIR
    fi
}

# Colores
NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'

make_defconfig() {
    START=$(date +"%s")
    echo -e ${LGR} "########### Generando Defconfig ############${NC}"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc) -l$(nproc)
}

compile() {
    cd ${kernel_dir}
    echo -e ${LGR} "######### Compilando kernel #########${NC}"
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

completion() {
    echo -e ${LGR} "#### Verificando archivos compilados ####${NC}"
    if [[ -f "${ZIMAGE}" && -f "${DTBO_IMG}" ]]; then
        echo -e "${LGR}Archivos encontrados:${NC}"
        echo -e "${LGR} - ${ZIMAGE}${NC}"
        echo -e "${LGR} - ${DTBO_IMG}${NC}"
        
        git clone -q https://github.com/adamspaini/AnyKernel3.git -b master $anykernel
        
        echo -e "${LGR}Copiando archivos a AnyKernel...${NC}"
        cp -v "${ZIMAGE}" "${DTBO_IMG}" "$anykernel/"
        
        cd "$anykernel"
        zip -r AnyKernel.zip *
        
        mkdir -p "$output_dir"
        mv -v AnyKernel.zip "$output_dir/${zip_name}"
        
        echo -e "${LGR}#### Archivo ZIP creado en: $output_dir/${zip_name} ####${NC}"
        exit 0
    else
        echo -e "${RED}#### Archivos no encontrados: ####${NC}"
        [[ -f "${ZIMAGE}" ]] || echo -e "${RED} - Falta: ${ZIMAGE}${NC}"
        [[ -f "${DTBO_IMG}" ]] || echo -e "${RED} - Falta: ${DTBO_IMG}${NC}"
        exit 1
    fi
}

# Ejecución principal
clone_tools
make_defconfig
compile | tee "${objdir}/log.txt"
completion
