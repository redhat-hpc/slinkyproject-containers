ARG PARENT_IMAGE=quay.io/centos/centos:stream9

FROM ${PARENT_IMAGE}

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
set -xeuo pipefail

dnf -q -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
rpm -ivh --nodeps --force http://repos.openhpc.community/OpenHPC/3/EL_9/x86_64/ohpc-release-3-1.el9.x86_64.rpm

# required for now: https://github.com/openhpc/ohpc/issues/2347
curl "http://obs.openhpc.community:82/OpenHPC3:/3.5:/Factory/EL_9/OpenHPC3:3.5:Factory.repo" -o /etc/yum.repos.d/obs.repo

dnf -q -y install --setopt='install_weak_deps=False' \
  lmod-ohpc gnu12-compilers-ohpc spack-ohpc examples-ohpc \
  hwloc-ohpc libtool-ohpc cmake-ohpc \
  openblas-gnu12-ohpc \
  pmix-ohpc openmpi4-pmix-gnu12-ohpc omb-gnu12-openmpi4-ohpc boost-gnu12-openmpi4-ohpc lmod-defaults-gnu12-openmpi4-ohpc \
  make autoconf perl-File-Compare perl-File-Copy \
  yq vim-enhanced
EOR

COPY fix-spack-packages.sh /usr/local/libexec

RUN <<EOR bash -l
# spack install
set -xeuo pipefail

module load spack openblas

spack compiler find --scope site
spack external find --scope site --all

chmod +x /usr/local/libexec/fix-spack-packages.sh
/usr/local/libexec/fix-spack-packages.sh

# choosing Haswell-level compatibility (go with v4 for AVX512)
spack install hpl target=x86_64
spack module lmod refresh -y
EOR
