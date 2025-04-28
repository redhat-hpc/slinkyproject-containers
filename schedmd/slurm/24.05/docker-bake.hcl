// SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
// SPDX-License-Identifier: Apache-2.0

variable "DOCKER_BAKE_REGISTRY" {}

variable "DOCKER_BAKE_SUFFIX" {}

variable "DEBUG" {
  default = "0"
}

variable "SLURM_VERSION" {
  default = "24.05.7"
}

function "slurm_semantic_version" {
  params = [version]
  result = regex("^(?<major>[0-9]+)\\.(?<minor>[0-9]+)\\.(?<patch>[0-9]+)(?:-(?<rev>.+))?$", "${version}")
}

function "slurm_version" {
  params = [version]
  result = (
    length(regexall("^(?<major>[0-9]+)\\.(?<minor>[0-9]+)\\.(?<patch>[0-9]+)(?:-(?<rev>.+))?$", "${version}")) > 0
      ? "${format("%s.%s", "${slurm_semantic_version("${version}")["major"]}", "${slurm_semantic_version("${version}")["minor"]}")}"
      : "${version}"
  )
}

function "format_tag" {
  params = [registry, stage, version, flavor, suffix]
  result = format("%s:%s", join("/", compact([registry, stage])), join("-", compact([version, flavor, suffix])))
}

group "default" {
  targets = [
    "rockylinux9",
    "ubuntu2404",
  ]
}

group "rockylinux9" {
  targets = [
    "slurmctld_rockylinux9",
    "slurmd_rockylinux9",
    "slurmdbd_rockylinux9",
    "slurmrestd_rockylinux9",
    "sackd_rockylinux9",
  ]
}

target "_rockylinux9" {
  context = "rockylinux9"
  args = {
    SLURM_VERSION = "${SLURM_VERSION}"
    DEBUG = "${DEBUG}"
  }
}

target "slurmctld_rockylinux9" {
  inherits = ["_rockylinux9"]
  target = "slurmctld"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmctld", "${slurm_version("${SLURM_VERSION}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmctld", "${SLURM_VERSION}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}"),
  ]
}

target "slurmd_rockylinux9" {
  inherits = ["_rockylinux9"]
  target = "slurmd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd", "${slurm_version("${SLURM_VERSION}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd", "${SLURM_VERSION}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}"),
  ]
}

target "slurmdbd_rockylinux9" {
  inherits = ["_rockylinux9"]
  target = "slurmdbd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmdbd", "${slurm_version("${SLURM_VERSION}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmdbd", "${SLURM_VERSION}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}"),
  ]
}

target "slurmrestd_rockylinux9" {
  inherits = ["_rockylinux9"]
  target = "slurmrestd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmrestd", "${slurm_version("${SLURM_VERSION}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmrestd", "${SLURM_VERSION}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}"),
  ]
}

target "sackd_rockylinux9" {
  inherits = ["_rockylinux9"]
  target = "sackd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "sackd", "${slurm_version("${SLURM_VERSION}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "sackd", "${SLURM_VERSION}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}"),
  ]
}

group "ubuntu2404" {
  targets = [
    "slurmctld_ubuntu2404",
    "slurmd_ubuntu2404",
    "slurmdbd_ubuntu2404",
    "slurmrestd_ubuntu2404",
    "sackd_ubuntu2404",
  ]
}

target "_ubuntu2404" {
  context = "ubuntu24.04"
  args = {
    SLURM_VERSION = "${SLURM_VERSION}"
    DEBUG = "${DEBUG}"
  }
}

target "slurmctld_ubuntu2404" {
  inherits = ["_ubuntu2404"]
  target = "slurmctld"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmctld", "${slurm_version("${SLURM_VERSION}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmctld", "${SLURM_VERSION}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}"),
  ]
}

target "slurmd_ubuntu2404" {
  inherits = ["_ubuntu2404"]
  target = "slurmd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd", "${slurm_version("${SLURM_VERSION}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd", "${SLURM_VERSION}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}"),
  ]
}

target "slurmdbd_ubuntu2404" {
  inherits = ["_ubuntu2404"]
  target = "slurmdbd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmdbd", "${slurm_version("${SLURM_VERSION}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmdbd", "${SLURM_VERSION}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}"),
  ]
}

target "slurmrestd_ubuntu2404" {
  inherits = ["_ubuntu2404"]
  target = "slurmrestd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmrestd", "${slurm_version("${SLURM_VERSION}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmrestd", "${SLURM_VERSION}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}"),
  ]
}

target "sackd_ubuntu2404" {
  inherits = ["_ubuntu2404"]
  target = "sackd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "sackd", "${slurm_version("${SLURM_VERSION}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "sackd", "${SLURM_VERSION}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}"),
  ]
}
