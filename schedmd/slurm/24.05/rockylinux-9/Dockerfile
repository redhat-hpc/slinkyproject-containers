# syntax=docker/dockerfile:1
# SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
# SPDX-License-Identifier: Apache-2.0

################################################################################
ARG PARENT_IMAGE=rockylinux:9
FROM ${PARENT_IMAGE} AS build

USER root
WORKDIR /tmp/

RUN <<EOR
dnf -q makecache --refresh
# For: Slurm RPM build
dnf -q -y install --setopt='install_weak_deps=False' \
  '@Development' rpm-build 'dnf-command(builddep)' 'dnf-command(config-manager)' epel-release
dnf -q config-manager --enable crb
# For: ./scripts/
dnf -q -y install --setopt='install_weak_deps=False' \
  curl-minimal jq
dnf clean all
EOR

COPY scripts/ /tmp/scripts/
COPY patches/ patches/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#rpmbuild
ARG SLURM_VERSION="24.05"
RUN <<EOR
dnf -q makecache --refresh
/tmp/scripts/download-slurm.sh ${SLURM_VERSION}
/tmp/scripts/patch-slurm.sh /tmp/patches /tmp/slurm
dnf -q config-manager --enable crb
export SLURM_RPM_TARBALL="$(rpmspec -q /tmp/slurm/slurm.spec 2> /dev/null | grep -Eo "slurm-[[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*(-[[:alnum:]]*)?" | head -n1)"
ln -s slurm $SLURM_RPM_TARBALL
tar --dereference -caf /tmp/$SLURM_RPM_TARBALL.tar.bz2 $SLURM_RPM_TARBALL
dnf -q -y builddep -D '_with_slurmrestd 1' -D '_with_jwt 1' -D '_with_yaml 1' -D '_with_numa 1' /tmp/slurm/slurm.spec
rpmbuild -ta --with slurmrestd --with jwt /tmp/$SLURM_RPM_TARBALL.tar.bz2 >/dev/null
dnf clean all
EOR

RUN /tmp/scripts/install-kubectl.sh

# OCI Annotations
# https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
LABEL org.opencontainers.image.authors="slinky@schedmd.com" \
      org.opencontainers.image.documentation="https://slurm.schedmd.com/documentation.html" \
      org.opencontainers.image.license="GPL-2.0+" \
      org.opencontainers.image.vendor="SchedMD LLC." \
      org.opencontainers.image.version="${SLURM_VERSION}" \
      org.opencontainers.image.source="https://github.com/SlinkyProject/containers"

# HasRequiredLabel requirement from Red Hat OpenShift Software Certification
# https://access.redhat.com/documentation/en-us/red_hat_software_certification/2024/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
LABEL vendor="SchedMD LLC." \
      version="${SLURM_VERSION}" \
      release="https://github.com/SlinkyProject/containers"

################################################################################
FROM ${PARENT_IMAGE} AS base

USER root
WORKDIR /tmp/

ARG SLURM_USER=slurm
ARG SLURM_USER_UID=401
ARG SLURM_USER_GID=401
RUN <<EOR
groupadd --system --gid=${SLURM_USER_GID} ${SLURM_USER}
useradd --system --no-log-init --uid=${SLURM_USER_UID} --gid=${SLURM_USER_GID} --shell=/usr/sbin/nologin ${SLURM_USER}
EOR

## START DEBUG SECTION ###
ARG DEBUG=0
RUN <<EOR
# For: Development and Debugging
if [ "$DEBUG" = true ] || [ "$DEBUG" = 1 ]; then
  dnf -q makecache --refresh
  dnf -q -y install sudo
  echo "${SLURM_USER} ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/slurm
  dnf clean all
fi
EOR
### END DEBUG SECTION ###

# Ref: https://slurm.schedmd.com/quickstart_admin.html#rpms
COPY --from=build /root/rpmbuild/RPMS/**/*.rpm /tmp/

RUN <<EOR
dnf -q makecache --refresh
# For: Slurm RPM Dependencies
dnf -q -y install --setopt='install_weak_deps=False' \
  'dnf-command(config-manager)' epel-release
dnf config-manager --enable crb
# For: Helm Chart
dnf -q -y install --setopt='install_weak_deps=False' \
  rsync gettext iputils
dnf clean all
EOR

COPY --from=build /usr/local/bin/kubectl /usr/local/bin/kubectl

################################################################################
# SLURM: slurmctld
# BUILD: `docker build --target=slurmctld -t [<registry>/]slurmctld:<tag> .`
################################################################################
FROM base AS slurmctld

# OCI Annotations
# https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
LABEL org.opencontainers.image.title="Slurm Control Plane" \
      org.opencontainers.image.description="slurmctld - The central management daemon of Slurm" \
      org.opencontainers.image.documentation="https://slurm.schedmd.com/slurmctld.html"

# HasRequiredLabel requirement from Red Hat OpenShift Software Certification
# https://access.redhat.com/documentation/en-us/red_hat_software_certification/2024/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
LABEL name="Slurm Control Plane" \
      summary="slurmctld - The central management daemon of Slurm" \
      description="slurmctld - The central management daemon of Slurm"

USER root
WORKDIR /tmp/

RUN <<EOR
dnf -q makecache --refresh
dnf -q -y install --setopt='install_weak_deps=False' \
  ./slurm-slurmctld-[0-9]*.rpm \
  ./slurm-[0-9]*.rpm
rm *.rpm && dnf clean all
EOR

ENTRYPOINT ["slurmctld"]
CMD ["-D"]

################################################################################
# SLURM: slurmd
# BUILD: `docker build --target=slurmd -t [<registry>/]slurmd:<tag> .`
################################################################################
FROM base AS slurmd

# OCI Annotations
# https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
LABEL org.opencontainers.image.title="Slurm Worker Agent" \
      org.opencontainers.image.description="slurmd - The compute node daemon for Slurm" \
      org.opencontainers.image.documentation="https://slurm.schedmd.com/slurmd.html"

# HasRequiredLabel requirement from Red Hat OpenShift Software Certification
# https://access.redhat.com/documentation/en-us/red_hat_software_certification/2024/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
LABEL name="Slurm Worker Agent" \
      summary="slurmd - The compute node daemon for Slurm" \
      description="slurmd - The compute node daemon for Slurm"

USER root
WORKDIR /tmp/

RUN <<EOR
dnf -q makecache --refresh
dnf -q -y install --setopt='install_weak_deps=False' \
  ./slurm-devel-[0-9]*.rpm \
  ./slurm-libpmi-[0-9]*.rpm \
  ./slurm-pam_slurm-[0-9]*.rpm \
  ./slurm-slurmd-[0-9]*.rpm \
  ./slurm-[0-9]*.rpm
rm *.rpm && dnf clean all
EOR

ENTRYPOINT ["slurmd"]
CMD ["-D"]

################################################################################
# SLURM: slurmdbd
# BUILD: `docker build --target=slurmdbd -t [<registry>/]slurmd:<tag> .`
################################################################################
FROM base AS slurmdbd

# OCI Annotations
# https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
LABEL org.opencontainers.image.title="Slurm Database Agent" \
      org.opencontainers.image.description="slurmdbd - Slurm Database Daemon" \
      org.opencontainers.image.documentation="https://slurm.schedmd.com/slurmdbd.html"

# HasRequiredLabel requirement from Red Hat OpenShift Software Certification
# https://access.redhat.com/documentation/en-us/red_hat_software_certification/2024/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
LABEL name="Slurm Database Agent" \
      summary="slurmdbd - Slurm Database Daemon" \
      description="slurmdbd - Slurm Database Daemon"

USER root
WORKDIR /tmp/

RUN <<EOR
dnf -q makecache --refresh
dnf -q -y install --setopt='install_weak_deps=False' \
  ./slurm-slurmdbd-[0-9]*.rpm \
  ./slurm-[0-9]*.rpm
rm *.rpm && dnf clean all
EOR

ENTRYPOINT ["slurmdbd"]
CMD ["-D"]

################################################################################
# SLURM: slurmrestd
# BUILD: `docker build --target=slurmrestd -t [<registry>/]slurmrestd:<tag> .`
################################################################################
FROM base AS slurmrestd

# OCI Annotations
# https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
LABEL org.opencontainers.image.title="Slurm REST API Agent" \
      org.opencontainers.image.description="slurmrestd - Interface to Slurm via REST API" \
      org.opencontainers.image.documentation="https://slurm.schedmd.com/slurmrestd.html"

# HasRequiredLabel requirement from Red Hat OpenShift Software Certification
# https://access.redhat.com/documentation/en-us/red_hat_software_certification/2024/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
LABEL name="Slurm REST API Agent" \
      summary="slurmrestd - Interface to Slurm via REST API" \
      description="slurmrestd - Interface to Slurm via REST API"

USER root
WORKDIR /tmp/

RUN <<EOR
dnf -q makecache --refresh
dnf -q -y install --setopt='install_weak_deps=False' \
  ./slurm-slurmrestd-[0-9]*.rpm \
  ./slurm-[0-9]*.rpm
rm *.rpm && dnf clean all
EOR

ENTRYPOINT ["slurmrestd"]
CMD ["0.0.0.0:6820"]

################################################################################
# SLURM: sackd
# BUILD: `docker build --target=sackd -t [<registry>/]sackd:<tag> .`
################################################################################
FROM base AS sackd

# OCI Annotations
# https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
LABEL org.opencontainers.image.title="Slurm Auth/Cred Server" \
      org.opencontainers.image.description="sackd - Slurm Auth and Cred Kiosk Daemon" \
      org.opencontainers.image.documentation="https://slurm.schedmd.com/sackd.html"

# HasRequiredLabel requirement from Red Hat OpenShift Software Certification
# https://access.redhat.com/documentation/en-us/red_hat_software_certification/2024/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
LABEL name="Slurm Auth/Cred Server" \
      summary="sackd - Slurm Auth and Cred Kiosk Daemon" \
      description="sackd - Slurm Auth and Cred Kiosk Daemon"

USER root
WORKDIR /tmp/

RUN <<EOR
dnf -q makecache --refresh
dnf -q -y install --setopt='install_weak_deps=False' \
  ./slurm-sackd-[0-9]*.rpm \
  ./slurm-[0-9]*.rpm
rm *.rpm && dnf clean all
EOR

ENTRYPOINT ["sackd"]

################################################################################
# SLURM: slurm
# BUILD: `docker build --target=slurm -t [<registry>/]slurm:<tag> .`
################################################################################
FROM base AS slurm

# OCI Annotations
# https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
LABEL org.opencontainers.image.title="Slurm" \
      org.opencontainers.image.description="Contains all Slurm daemons" \
      org.opencontainers.image.documentation="https://slurm.schedmd.com/documentation.html"

# HasRequiredLabel requirement from Red Hat OpenShift Software Certification
# https://access.redhat.com/documentation/en-us/red_hat_software_certification/2024/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
LABEL name="Slurm" \
      summary="Contains all Slurm daemons" \
      description="Contains all Slurm daemons"

USER root
WORKDIR /tmp/

RUN <<EOR
dnf -q makecache --refresh
dnf -q -y install --setopt='install_weak_deps=False' \
  ./slurm-devel-[0-9]*.rpm \
  ./slurm-libpmi-[0-9]*.rpm \
  ./slurm-pam_slurm-[0-9]*.rpm \
  ./slurm-sackd-[0-9]*.rpm \
  ./slurm-slurmctld-[0-9]*.rpm \
  ./slurm-slurmd-[0-9]*.rpm \
  ./slurm-slurmdbd-[0-9]*.rpm \
  ./slurm-slurmrestd-[0-9]*.rpm \
  ./slurm-[0-9]*.rpm
rm *.rpm && dnf clean all
EOR

CMD ["bash", "--login"]
