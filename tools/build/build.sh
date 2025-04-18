#!/bin/bash

# Thanks to Adam Spaini for the script (@adams4d13)


kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
output_dir="${kernel_dir}/output"
anykernel=$HOME/anykernel
builddir="${kernel_dir}/build"
kernel_name="GoreKernel_Vayu_nonksu"
zip_name="$kernel_name$(date +"%Y%m%d").zip"
ZIMAGE="${objdir}/arch/arm64/boot/Image"
DTBO_IMG="${objdir}/arch/arm64/boot/dtbo.img"
CLANG_DIR="tc/clang"
GCC64_DIR="tc/gcc64"
GCC32_DIR="tc/gcc32"
MKDTBOIMG_DIR="tc/libufdt"
MKDTBOIMG="${MKDTBOIMG_DIR}/utils/src/mkdtboimg.py"
DISPLAY="arch/arm64/boot/dts/qcom/xiaomi/overlay/common/display"

export CONFIG_FILE="vayu_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=@adams4d13
export KBUILD_BUILD_USER=arch-linux
export KBUILD_BUILD_FEATURES="Dev-Adam"

export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"


clone_tools() {
    if ! [ -d "$CLANG_DIR" ]; then
        echo -e "${LYW}Clonando Crdroid Clang...${NC}"
        git clone -q --depth=1 --single-branch https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git -b 15.0 $CLANG_DIR || {
            echo -e "${RED}Error al clonar Clang${NC}"
            exit 1
        }
    fi

    if ! [ -d "$GCC64_DIR" ]; then
        echo -e "${LYW}Clonando GCC64...${NC}"
        git clone -q --depth=1 --single-branch https://github.com/mvaisakh/gcc-arm64.git $GCC64_DIR || {
            echo -e "${RED}Error al clonar GCC64${NC}"
            exit 1
        }
    fi

    if ! [ -d "$GCC32_DIR" ]; then
        echo -e "${LYW}Clonando GCC32...${NC}"
        git clone -q --depth=1 --single-branch https://github.com/mvaisakh/gcc-arm.git $GCC32_DIR || {
            echo -e "${RED}Error al clonar GCC32${NC}"
            exit 1
        }
    fi

    if ! [ -d "$MKDTBOIMG_DIR" ]; then
        echo -e "${LYW}Clonando libufdt para mkdtboimg...${NC}"
        git clone -q --depth=1 https://android.googlesource.com/platform/system/libufdt $MKDTBOIMG_DIR || {
            echo -e "${RED}Error al clonar libufdt${NC}"
            exit 1
        }

        if [ -d "$MKDTBOIMG_DIR" ]; then
            echo -e "${LYW}Compilando mkdtboimg...${NC}"
            cd "${MKDTBOIMG_DIR}/utils/src" && make || {
                echo -e "${LYW}No se pudo compilar mkdtboimg, se usará el script Python directamente${NC}"
            }
            cd "$kernel_dir"
        fi
    fi
}

make_defconfig() {
    echo -e "${LGR}########### Generando Defconfig ############${NC}"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc) -l$(nproc)
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

miui() {
    echo -e "${LYW}######### Aplicando ajustes para MIUI #########${NC}"
    sed -i 's/<70>/<695>/g'   $DISPLAY/dsi-panel-j20s-36-02-0a-lcd-dsc-vid.dtsi
    sed -i 's/<154>/<1546>/g' $DISPLAY/dsi-panel-j20s-36-02-0a-lcd-dsc-vid.dtsi
    sed -i 's/<70>/<695>/g'   $DISPLAY/dsi-panel-j20s-42-02-0b-lcd-dsc-vid.dtsi
    sed -i 's/<154>/<1546>/g' $DISPLAY/dsi-panel-j20s-42-02-0b-lcd-dsc-vid.dtsi
}

restore() {
    echo -e "${LYW}######### Restaurando archivos originales #########${NC}"
    git restore $DISPLAY/dsi-panel-j20s-36-02-0a-lcd-dsc-vid.dtsi
    git restore $DISPLAY/dsi-panel-j20s-42-02-0b-lcd-dsc-vid.dtsi
}


sdk() {
    echo -e "${LYW}######### Generando imágenes para SDK #########${NC}"
    
    if [ -f "$MKDTBOIMG" ]; then
        python3 "$MKDTBOIMG" create "$anykernel/dtbo.img" --page_size=4096 "$objdir"/arch/arm64/boot/dts/qcom/vayu-sm8150-overlay.dtbo
        find "$objdir"/arch/arm64/boot/dts/qcom -name 'sm8150-v2*.dtb' -exec cat {} + > "$anykernel/dtb"
        python3 "$MKDTBOIMG" create "$anykernel/dtbo-miui.img" --page_size=4096 "$objdir"/arch/arm64/boot/dts/qcom/vayu-sm8150-overlay.dtbo
    else
        echo -e "${RED}Error: No se encontró mkdtboimg.py para generar imágenes SDK${NC}"
    fi
}

completion() {
    echo -e "${LGR}#### Verificando archivos compilados ####${NC}"
    if [[ -f "${ZIMAGE}" && -f "${DTBO_IMG}" ]]; then
        echo -e "${LGR}############################################"
        echo -e "${LGR}############# OkThisIsEpic!  ##############"
        echo -e "${LGR}############################################${NC}"

        git clone -q https://github.com/adamspaini/AnyKernel3.git -b master $anykernel || {
            echo -e "${LYW}AnyKernel ya existe, actualizando...${NC}"
            cd $anykernel && git pull -q
            cd $kernel_dir
        }

        echo -e "${LGR}Copiando archivos a AnyKernel...${NC}"
        cp -v "${ZIMAGE}" "${DTBO_IMG}" "$anykernel/"

        cd "$anykernel"
        zip -r9 AnyKernel.zip * || {
            echo -e "${RED}Error al crear el zip${NC}";
            exit 1;
        }

        mkdir -p "$output_dir"
        mv -v AnyKernel.zip "$output_dir/${zip_name}"

        echo -e "${LGR}#### Kernel compilado correctamente ####${NC}"
        echo -e "${LGR}ZIP: $output_dir/${zip_name}${NC}"
        exit 0
    else
        echo -e "${RED}############################################"
        echo -e "${RED}##         This Is Not Epic :'(           ##"
        echo -e "${RED}############################################${NC}"
        [[ -f "${ZIMAGE}" ]] || echo -e "${RED} - Falta: ${ZIMAGE}${NC}"
        [[ -f "${DTBO_IMG}" ]] || echo -e "${RED} - Falta: ${DTBO_IMG}${NC}"
        exit 1
    fi
}

NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'
LYW='\033[1;33m'

echo -e "${LYW}Liberando espacio...${NC}"
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache || true
df -h

clone_tools
make_defconfig
compile
miui
sdk
restore
completion
