# syntax=docker/dockerfile:1
# SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
# SPDX-License-Identifier: Apache-2.0

################################################################################

ARG SLURM_VERSION=25.11-latest
ARG SLURM_VERSION_MICRO=1
ARG SLURM_DIR=slurm
ARG PARENT_IMAGE=registry.access.redhat.com/ubi9:latest
ARG BUILD_IMAGE=quay.io/centos/centos:stream9

################################################################################
FROM ${BUILD_IMAGE} AS build

SHELL ["bash", "-c"]

ARG SLURM_VERSION
ENV SLURM_VERSION=${SLURM_VERSION}
ARG SLURM_DIR

USER root
WORKDIR /tmp/

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
# build setup
dnf -q -y install --setopt='install_weak_deps=False' \
  '@Development' rpm-build 'dnf-command(builddep)' 'dnf-command(config-manager)' https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --enable crb || dnf -q config-manager --enable codeready-builder-for-rhel-9-*
dnf config-manager --disable *source*,*debug*,*eus* || true
EOR

RUN <<EOR
# build munge
git clone https://src.fedoraproject.org/rpms/munge.git munge
cd munge
git checkout f44

dnf builddep -y --define "_sourcedir $(pwd)" munge.spec
rpmbuild --nocheck --define 'autorelease 1' --define "_disable_source_fetch 0" --define "_sourcedir $(pwd)" -ba munge.spec
EOR

RUN <<EOR
# build http-parser
git clone https://src.fedoraproject.org/rpms/http-parser.git http-parser
cd http-parser
git checkout f44

dnf builddep -y --define "_sourcedir $(pwd)" http-parser.spec
rpmbuild --nocheck --define 'autorelease 1' --define "_disable_source_fetch 0" --define "_sourcedir $(pwd)" -ba http-parser.spec
EOR

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
# Build Slurm
set -xeuo pipefail
ARCH=$(uname -m)

rpm -ivh --nodeps http://repos.openhpc.community/OpenHPC/3/EL_9/${ARCH}/ohpc-release-3-1.el9.${ARCH}.rpm
dnf -q -y upgrade
## Build
curl -Lo ohpc.tar.gz https://github.com/openhpc/ohpc/archive/refs/tags/v3.3.1.GA.tar.gz
mkdir source
tar --strip-components=1 -C source -xf ohpc.tar.gz
cp source/components/OHPC_macros source/components/rms/slurm/SOURCES/
sed -i "s/Version:[[:space:]]*[0-9][0-9.]*/Version: $SLURM_VERSION/" source/components/rms/slurm/SPECS/slurm.spec
sed -i 's/ NEWS README\.rst RELEASE_NOTES//g' source/components/rms/slurm/SPECS/slurm.spec
sed -i "s/^Release:[[:space:]]*[^[:space:]]*/Release: 1/" source/components/rms/slurm/SPECS/slurm.spec
# the only way to remove freeipmi requirements is to remove the declaration?? I tried --without or --define and nothing worked
sed -i '/^%global[[:space:]]\+_with_freeipmi.*$/d' source/components/rms/slurm/SPECS/slurm.spec
dnf builddep -y \
  --define "_sourcedir $(pwd)/source/components/rms/slurm/SOURCES" \
  source/components/rms/slurm/SPECS/slurm.spec
set +u
# not sure why we need to manually source this?
source /etc/bashrc
set -u
rpmbuild \
  --define "_disable_source_fetch 0" \
  --define "_sourcedir $(pwd)/source/components/rms/slurm/SOURCES" \
  -ba source/components/rms/slurm/SPECS/slurm.spec
EOR

################################################################################
FROM ${PARENT_IMAGE} AS base

SHELL ["bash", "-c"]

ARG SLURM_VERSION
ENV SLURM_VERSION=${SLURM_VERSION}

USER root
WORKDIR /tmp/

ARG SLURM_USER=slurm
ARG SLURM_USER_UID=401
ARG SLURM_USER_GID=401

RUN <<EOR
# Create SlurmUser
set -xeuo pipefail
groupadd --system --gid=${SLURM_USER_GID} ${SLURM_USER}
useradd --system --no-log-init --uid=${SLURM_USER_UID} --gid=${SLURM_USER_GID} --shell=/usr/sbin/nologin ${SLURM_USER}
EOR

RUN <<EOR
# Remove Users
set -xeuo pipefail
for user in $(ls /home/); do
  userdel --remove $user
done
EOR

COPY --from=build /root/rpmbuild/RPMS/**/*.rpm /tmp/

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
# Install Dependencies
set -xeuo pipefail

# For: Slurm RPM Dependencies
dnf config-manager --set-disabled rhel-9* || true
dnf config-manager --enable ubi-9-codeready-builder-rpms

dnf -q -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf -q -y upgrade
# Init System
dnf -q -y install --setopt='install_weak_deps=False' \
  supervisor tini
# Debug
dnf -q -y install --setopt='install_weak_deps=False' \
  procps-ng iputils ncurses
EOR

################################################################################
FROM base AS base-extra

SHELL ["bash", "-c"]

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
# Install Extra Packages
set -xeuo pipefail
ARCH=$(uname -m)

# required for now: https://github.com/openhpc/ohpc/issues/2347
curl "http://obs.openhpc.community:82/OpenHPC3:/3.5:/Factory/EL_9/OpenHPC3:3.5:Factory.repo" -o /etc/yum.repos.d/obs.repo

# Install OpenHPC
dnf -q makecache --refresh
dnf -q -y install openssl-devel libevent-devel perl-devel libcurl-devel python3-devel bzip2-devel \
    python3 python3-pip procps-ng git vim-enhanced hostname man-db libevent iproute rsync gettext iputils

# redhat-release >= 9.1 is needed by ohpc-release-3-1.el9.x86_64 but we have 9.0 in stream9
dnf -q -y install http://repos.openhpc.community/OpenHPC/3/EL_9/${ARCH}/ohpc-release-3-1.el9.${ARCH}.rpm

dnf -q -y install lmod-ohpc gnu12-compilers-ohpc spack-ohpc examples-ohpc \
  automake-ohpc autoconf-ohpc hwloc-ohpc libtool-ohpc valgrind-ohpc cmake-ohpc \
  openblas-gnu12-ohpc \
  pmix-ohpc openmpi4-pmix-gnu12-ohpc omb-gnu12-openmpi4-ohpc boost-gnu12-openmpi4-ohpc lmod-defaults-gnu12-openmpi4-ohpc
EOR

RUN <<EOR bash -l
# spack install
set -xeuo pipefail

module load spack openblas

# adding spack build cache https://cache.spack.io/tag/v0.23.1/
# spack mirror add v0.23.1 https://binaries.spack.io/v0.23.1
# spack buildcache keys --install --trust

spack compiler find --scope site
spack external find --scope site --all

# choosing Haswell-level compatibility (go with v4 for AVX512)
spack install hpl target=x86_64_v3
spack module lmod refresh -y
EOR

################################################################################
FROM base AS slurmctld

SHELL ["bash", "-c"]

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
# Install Slurm Packages
set -xeuo pipefail
dnf -q -y install --setopt='install_weak_deps=False' \
  socat \
  ./munge-[0-9]*.rpm \
  ./munge-libs-[0-9]*.rpm \
  ./http-parser-[0-9]*.rpm \
  ./slurm-slurmctld-ohpc-[0-9]*.rpm \
  ./slurm-ohpc-[0-9]*.rpm
rm *.rpm
EOR

COPY files/etc/supervisord.conf /etc/
COPY \
  files/etc/supervisord.d/slurmctld.ini \
  files/etc/supervisord.d/fakesystemd.ini \
  /etc/supervisord.d/
COPY files/usr/local/bin/fakesystemd.sh /usr/local/bin/
COPY files/usr/local/bin/slurmctld-entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 6817/tcp
ENTRYPOINT ["entrypoint.sh"]

################################################################################
FROM base-extra AS slurmd

SHELL ["bash", "-c"]

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
# Install Slurm Packages
set -xeuo pipefail
dnf -q -y install --setopt='install_weak_deps=False' \
  gawk socat \
  openssh-server \
  authselect sssd sssd-ad sssd-ldap \
  ./munge-[0-9]*.rpm \
  ./munge-libs-[0-9]*.rpm \
  ./http-parser-[0-9]*.rpm \
  ./slurm-devel-ohpc-[0-9]*.rpm \
  ./slurm-libpmi-ohpc-[0-9]*.rpm \
  ./slurm-pam_slurm-ohpc-[0-9]*.rpm \
  ./slurm-slurmd-ohpc-[0-9]*.rpm \
  ./slurm-ohpc-[0-9]*.rpm
rm *.rpm
# Configure
mkdir -p /var/spool/slurmd/
sed -i -E "s/^passwd:[[:space:]]+/&slurm /g" /etc/nsswitch.conf
sed -i -E "s/^group:[[:space:]]+/&slurm /g" /etc/nsswitch.conf
mkdir -p /etc/authselect
authselect select sssd with-mkhomedir --force
rm -f /etc/ssh/ssh_host_*
EOR

COPY files/etc/supervisord.conf /etc/
COPY \
  files/etc/supervisord.d/fakesystemd.ini \
  files/etc/supervisord.d/slurmd.ini \
  files/etc/supervisord.d/sshd.ini \
  files/etc/supervisord.d/sssd.ini \
  /etc/supervisord.d/
COPY files/usr/local/bin/fakesystemd.sh /usr/local/bin/
COPY files/usr/local/bin/slurmd-entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 6818/tcp 22/tcp
ENTRYPOINT ["entrypoint.sh"]

################################################################################
FROM base AS slurmdbd

SHELL ["bash", "-c"]

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
# Install Slurm Packages
set -xeuo pipefail
dnf -q -y install --setopt='install_weak_deps=False' \
  ./munge-[0-9]*.rpm \
  ./munge-libs-[0-9]*.rpm \
  ./http-parser-[0-9]*.rpm \
  ./slurm-slurmdbd-ohpc-[0-9]*.rpm \
  ./slurm-ohpc-[0-9]*.rpm
rm *.rpm
EOR

EXPOSE 6819/tcp
ENTRYPOINT ["tini", "-g", "--", "slurmdbd", "-D"]

################################################################################
FROM base AS slurmrestd

SHELL ["bash", "-c"]

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
# Install Slurm Packages
set -xeuo pipefail
dnf -q -y install --setopt='install_weak_deps=False' \
  ./munge-[0-9]*.rpm \
  ./munge-libs-[0-9]*.rpm \
  ./http-parser-[0-9]*.rpm \
  ./slurm-slurmrestd-ohpc-[0-9]*.rpm \
  ./slurm-ohpc-[0-9]*.rpm
rm *.rpm
EOR

EXPOSE 6820/tcp
ENTRYPOINT ["tini", "-g", "--", "slurmrestd"]
CMD ["0.0.0.0:6820"]

################################################################################
FROM base-extra AS sackd

SHELL ["bash", "-c"]

USER root
WORKDIR /tmp/

ADD https://dl.k8s.io/release/stable.txt kubernetes_stable.txt

# Ref: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
# Install kubectl
set -xeuo pipefail
VERSION="$(cat kubernetes_stable.txt | grep -Eo '^v[0-9]+\.[0-9]+')"
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${VERSION}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${VERSION}/rpm/repodata/repomd.xml.key
EOF
dnf -q -y install --setopt='install_weak_deps=False' kubectl
rm *.txt
EOR

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
# Install Slurm Packages
set -xeuo pipefail
dnf -q -y install --setopt='install_weak_deps=False' \
  socat \
  ./munge-[0-9]*.rpm \
  ./munge-libs-[0-9]*.rpm \
  ./http-parser-[0-9]*.rpm \
  ./slurm-sackd-ohpc-[0-9]*.rpm \
  ./slurm-ohpc-[0-9]*.rpm
rm *.rpm
# Prepare Directories
mkdir -p /run/slurm/
chown ${SLURM_USER}:${SLURM_USER} /run/slurm
EOR

COPY files/etc/supervisord.conf /etc/
COPY \
  files/etc/supervisord.d/sackd.ini \
  files/etc/supervisord.d/fakesystemd-slurm.ini \
  /etc/supervisord.d/
COPY files/usr/local/bin/fakesystemd.sh /usr/local/bin/
COPY files/usr/local/bin/sackd-entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

################################################################################
FROM sackd AS login

SHELL ["bash", "-c"]

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
# Install Packages
set -xeuo pipefail
dnf -q -y install --setopt='install_weak_deps=False' \
  socat \
  openssh-server \
  authselect sssd sssd-ad sssd-ldap
# Configure
mkdir -p /etc/authselect
authselect select sssd with-mkhomedir --force
rm -f /etc/ssh/ssh_host_*
EOR

COPY files/etc/supervisord.conf /etc/
COPY \
  files/etc/supervisord.d/fakesystemd-slurm.ini \
  files/etc/supervisord.d/sackd.ini \
  files/etc/supervisord.d/sshd.ini \
  files/etc/supervisord.d/sssd.ini \
  /etc/supervisord.d/
COPY files/usr/local/bin/fakesystemd.sh /usr/local/bin/
COPY files/usr/local/bin/login-entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 22/tcp
ENTRYPOINT ["entrypoint.sh"]
