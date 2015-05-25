TOOLCHAIN_FILE=arm-2011.03-42-arm-none-eabi-i686-pc-linux-gnu.tar.bz2
TOOLCHAIN_DIRECTORY=arm-2011.03
TOOLCHAIN_URL=https://sourcery.mentor.com/sgpp/lite/arm/portal/package8734/public/arm-none-eabi/arm-2011.03-42-arm-none-eabi-i686-pc-linux-gnu.tar.bz2

LINUX_KERNEL_FILE=linux-2.6.39.tar.bz2
LINUX_KERNEL_DIRECTORY=linux-2.6.39
LINUX_KERNEL_URL=https://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.39.tar.bz2

TOOLCHAIN_LINUX_FILE=arm-2013.05-24-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2
TOOLCHAIN_LINUX_DIRECTORY=arm-2013.05
TOOLCHAIN_LINUX_URL=https://dl.dropboxusercontent.com/u/43077685/arm-2013.05-24-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2



DOWNLOAD_DIRECTORY=downloads

PWD=$(pwd)

sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install python-serial python-argparse openocd \
    flex bison libncurses5-dev autoconf texinfo build-essential \
    libftdi-dev libtool zlib1g-dev genromfs git-core wget zip \
    python-empy -y
sudo apt-get install package-name:i386 -y
sudo apt-get install libc6:i386 libgcc1:i386 gcc-4.6-base:i386 libstdc++5:i386 libstdc++6:i386 -y
sudo apt-get install qemu-system -y
sudo apt-get install pulseaudio -y 

if [ ! -d $DOWNLOAD_DIRECTORY ]; then
    mkdir $DOWNLOAD_DIRECTORY
fi

if [ ! -d $TOOLCHAIN_DIRECTORY ]; then

    if [ ! -f $TOOLCHAIN_FILE ]; then
        wget $TOOLCHAIN_URL
    fi
    
    tar -xjf $TOOLCHAIN_FILE
    mv $TOOLCHAIN_FILE $DOWNLOAD_DIRECTORY
fi

if [ ! -d $TOOLCHAIN_LINUX_DIRECTORY ]; then

    if [ ! -f $TOOLCHAIN_LINUX_FILE ]; then
        wget $TOOLCHAIN_LINUX_URL
    fi
    
    tar -xjf $TOOLCHAIN_LINUX_FILE
    mv $TOOLCHAIN_LINUX_FILE  $DOWNLOAD_DIRECTORY
fi

if grep -Fxq "export PATH=\$PATH:$PWD/$TOOLCHAIN_LINUX_DIRECTORY/bin" ~/.bashrc
then
    echo have
else
    echo "export PATH=\$PATH:$PWD/$TOOLCHAIN_LINUX_DIRECTORY/bin" >> ~/.bashrc
fi

if [ ! -d $LINUX_KERNEL_DIRECTORY ]; then

    if [ ! -f $LINUX_KERNEL_FILE ]; then
        wget $LINUX_KERNEL_URL
    fi
    
    tar -xjf $LINUX_KERNEL_FILE
    mv $LINUX_KERNEL_FILE  $DOWNLOAD_DIRECTORY
fi

if grep -Fxq "export PATH=\$PATH:$PWD/$TOOLCHAIN_DIRECTORY/bin" ~/.bashrc
then
    echo have
else
    echo "export PATH=\$PATH:$PWD/$TOOLCHAIN_DIRECTORY/bin" >> ~/.bashrc
fi

export PATH=$PATH:$PWD/$TOOLCHAIN_DIRECTORY/bin

cd $LINUX_KERNEL_DIRECTORY
wget http://www.pcs.usp.br/~jkinoshi/2013/config
mv config .config

rm Makefile
wget http://www.pcs.usp.br/~jkinoshi/2013/Makefile

make ARCH=arm CROSS_COMPILE=arm-none-eabi- all

cd ..

if [ ! -d linux-compiled ]; then
    mkdir linux-compiled
fi

cp $LINUX_KERNEL_DIRECTORY/arch/arm/boot/zImage ./linux-compiled/

touch hello.c
echo "#include <stdio.h>" > hello.c
echo "int main() {" >> hello.c
echo "printf(\"Hello World!\\n\");" >> hello.c
echo "while(1);" >> hello.c
echo "return 0;" >> hello.c
echo "}" >> hello.c

arm-none-linux-gnueabi-gcc -static hello.c -o hello
echo hello | cpio -o --format=newc > rootfs

qemu-system-arm -M versatilepb -m 128M -kernel zImage -initrd rootfs -append "root=/dev/ram rdinit=/hello" -nographic