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

# Archivos importantes
ZIMAGE="${objdir}/arch/arm64/boot/Image"
DTBO_IMG="${objdir}/arch/arm64/boot/dtbo.img"
DTBO_DIR="${objdir}/arch/arm64/boot/dts/vendor/qcom"  # Ajusta según tu dispositivo

export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"

# --------------------------------------------
# Script mkdtboimg.py integrado (Python 3)
# --------------------------------------------
cat > "${kernel_dir}/mkdtboimg.py" << 'EOL'
#!/usr/bin/env python3
import argparse
import struct
import os

DTBO_MAGIC = b"dtbo\0\0\0\0"
DTBO_HEADER_FORMAT = "8I"

class DtboImage:
    def __init__(self):
        self.header = {
            'magic': DTBO_MAGIC,
            'total_size': 0,
            'header_size': struct.calcsize(DTBO_HEADER_FORMAT),
            'dt_entry_size': 32,
            'dt_entry_count': 0,
            'dt_entries_offset': 0,
            'page_size': 2048,
            'reserved': 0
        }
        self.dt_entries = []

    def add_dtbo(self, dtbo_file):
        with open(dtbo_file, 'rb') as f:
            dtbo_data = f.read()
        
        dt_entry = {
            'dt_size': len(dtbo_data),
            'dt_offset': 0,
            'dtbo_data': dtbo_data
        }
        self.dt_entries.append(dt_entry)
        self.header['dt_entry_count'] += 1

    def write(self, output_file):
        self.header['dt_entries_offset'] = self.header['header_size']
        current_offset = self.header['dt_entries_offset'] + (self.header['dt_entry_count'] * self.header['dt_entry_size'])
        current_offset = (current_offset + self.header['page_size'] - 1) & ~(self.header['page_size'] - 1)
        
        for entry in self.dt_entries:
            entry['dt_offset'] = current_offset
            current_offset += entry['dt_size']
            current_offset = (current_offset + self.header['page_size'] - 1) & ~(self.header['page_size'] - 1)
        
        self.header['total_size'] = current_offset

        with open(output_file, 'wb') as f:
            f.write(self.header['magic'])
            f.write(struct.pack(
                DTBO_HEADER_FORMAT,
                self.header['total_size'],
                self.header['header_size'],
                self.header['dt_entry_count'],
                self.header['dt_entry_size'],
                self.header['dt_entries_offset'],
                self.header['page_size'],
                0, 0
            ))
            for entry in self.dt_entries:
                f.write(struct.pack("4I", entry['dt_size'], entry['dt_offset'], 0, 0))
            for entry in self.dt_entries:
                f.seek(entry['dt_offset'])
                f.write(entry['dtbo_data'])
                pad_size = (self.header['page_size'] - (entry['dt_size'] % self.header['page_size'])) % self.header['page_size']
                f.write(b'\0' * pad_size)

def main():
    parser = argparse.ArgumentParser(description='Crea dtbo.img')
    parser.add_argument('command', choices=['create'], help='Acción')
    parser.add_argument('output_file', help='Archivo de salida')
    parser.add_argument('dtbo_files', nargs='+', help='Archivos .dtbo')
    args = parser.parse_args()

    dtbo_image = DtboImage()
    for dtbo_file in args.dtbo_files:
        dtbo_image.add_dtbo(dtbo_file)
    dtbo_image.write(args.output_file)

if __name__ == '__main__':
    main()
EOL

chmod +x "${kernel_dir}/mkdtboimg.py"

# --------------------------------------------
# Funciones del build.sh
# --------------------------------------------

# Colores
NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'
LYW='\033[1;33m'

clone_tools() {
    if ! [ -d "$CLANG_DIR" ]; then
        echo -e "${LYW}Clonando Crdroid Clang...${NC}"
        git clone -q --depth=1 --single-branch https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git -b 15.0 $CLANG_DIR
    fi

    if ! [ -d "$GCC64_DIR" ]; then
        echo -e "${LYW}Clonando GCC64...${NC}"
        git clone -q --depth=1 --single-branch https://github.com/mvaisakh/gcc-arm64.git $GCC64_DIR
    fi

    if ! [ -d "$GCC32_DIR" ]; then
        echo -e "${LYW}Clonando GCC32...${NC}"
        git clone -q --depth=1 --single-branch https://github.com/mvaisakh/gcc-arm.git $GCC32_DIR
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

build_dtbo() {
    echo -e "${LGR}######### Compilando dtbo.img #########${NC}"
    
    # Intento 1: Compilación estándar
    if ! make -j$(nproc) -l$(nproc) O=out ARCH=arm64 dtbo.img; then
        echo -e "${LYW}Falló la compilación estándar, intentando método alternativo...${NC}"
        
        # Intento 2: Generar manualmente con dtc
        mkdir -p "${objdir}/dtbo_tmp"
        for dts_file in $(find "${DTBO_DIR}" -name "*.dts"); do
            dtbo_file="${objdir}/dtbo_tmp/$(basename ${dts_file%.*}).dtbo"
            dtc -I dts -O dtb -o "${dtbo_file}" "${dts_file}" || {
                echo -e "${RED}Error al compilar ${dts_file}${NC}";
                continue;
            }
        done
        
        # Crear dtbo.img con el script python
        python3 "${kernel_dir}/mkdtboimg.py" create "${DTBO_IMG}" "${objdir}"/dtbo_tmp/*.dtbo || {
            echo -e "${RED}Error al crear dtbo.img${NC}";
            return 1;
        }
        
        echo -e "${LGR}dtbo.img generado manualmente con éxito${NC}"
    fi
}

completion() {
    echo -e "${LGR}#### Verificando archivos compilados ####${NC}"
    if [[ -f "${ZIMAGE}" && -f "${DTBO_IMG}" ]]; then
        echo -e "${LGR}Archivos encontrados:${NC}"
        echo -e "${LGR} - ${ZIMAGE}${NC}"
        echo -e "${LGR} - ${DTBO_IMG}${NC}"

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
        echo -e "${RED}#### Archivos no encontrados: ####${NC}"
        [[ -f "${ZIMAGE}" ]] || echo -e "${RED} - Falta: ${ZIMAGE}${NC}"
        [[ -f "${DTBO_IMG}" ]] || echo -e "${RED} - Falta: ${DTBO_IMG}${NC}"
        exit 1
    fi
}

# --------------------------------------------
# Ejecución principal
# --------------------------------------------

# Limpieza inicial
echo -e "${LYW}Liberando espacio...${NC}"
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache || true
df -h

# Proceso de compilación
clone_tools
make_defconfig
compile | tee "${objdir}/log.txt"
build_dtbo
completion
