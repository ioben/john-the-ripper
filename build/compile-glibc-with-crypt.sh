yum install -y gcc gcc-c++ autotools make # Build tools
yum install -y yum-utils rpm-build # RPM tools
yum install -y gd-devel libpng-devel texinfo audit-libs-devel libcap-devel nss-devel systemtap-sdt-devel libstdc++-static libselinux-devel # Glibc build dependencies

# Setup - Need these directories to patch glibc
mkdir -p ~/rpmbuild/{RPMS,SOURCES,SPECS,PATCHES,tmp}
cd ~/rpmbuild/tmp

# Download and extract glibc into rpmbuild dirs for modification
yumdownloader --source glibc-2.17-106.el7_2.4.x86_64
rpm2cpio *.src.rpm | cpio -idmv
mv *.patch *.tar.gz ../SOURCES
mv *.spec ../SPECS

# Download bcrypt patch
wget http://www.openwall.com/crypt/crypt_blowfish-1.3.tar.gz
tar -xzf crypt_blowfish-1.3.tar.gz
cd crypt_blowfish-1.3

# Apply custom patch to downloaded glibc-2.14-crypt.patch to support glibc 2.17
patch < /vagrant/contrib/glibc-crypto.patch

# Move patched glibc-2.14-crypt.patch to glibc RPM's source dir
cp glibc-2.14-crypt.diff ~/rpmbuild/SOURCES/glibc-2.17-crypt-bcrypt.patch

# Patch glibc SPEC file to use patch and include necessary files
cd ~/rpmbuild/SPECS
patch < /vagrant/contrib/glibc.spec.patch

# Rebuild glibc RPM
echo "WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!"
echo "                 Rebuilding glibc..."
echo "        This is going to take 20-30 minutes."
echo "WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!"
sleep 2

rpmbuild -ba --define "dist rc2.el7.centos" ~/rpmbuild/SPECS/glibc.spec

# Install newly patched glibc and dependencies
cd ~/rpmbuild/RPMS/x86_64
rpm -Uvh glibc-2.17-106rc2.el7.centos.4.x86_64.rpm glibc-common-2.17-106rc2.el7.centos.4.x86_64.rpm glibc-devel-2.17-106rc2.el7.centos.4.x86_64.rpm glibc-headers-2.17-106rc2.el7.centos.4.x86_64.rpm

# Download/build John the Ripper
cd ~
wget http://www.openwall.com/john/j/john-1.8.0.tar.xz
tar -xJf john-1.8.0.tar.xz

cd john-1.8.0/src
make linux-x86-64-avx

cd ../run

# TODO - Fix, john doesn't like being started in a directory other than its own.
echo 'PATH="$PATH:'"$(pwd)"'" && export PATH' >> /etc/profile.d/john-the-ripper.sh

echo "Done! Run john"
