// SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
// SPDX-License-Identifier: Apache-2.0

variable "DOCKER_BAKE_REGISTRY" {}

variable "DOCKER_BAKE_SUFFIX" {}

variable "DEBUG" {
  default = "0"
}

variable "SLURM_VERSION" {
  default = "24.11.4"
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

function "sanitize" {
  params = [input]
  // Remove [:punct:] from string before joining elements
  // NOTE: function library does not seem to support any character classes, have to regex manually
  result = regex_replace(input, "[!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~.]", "")
}

function "format_name" {
  params = [stage, version, flavor]
  result = join("_", [sanitize(stage), sanitize(version), sanitize(flavor)])
}

function "format_tag" {
  params = [registry, stage, version, flavor, suffix]
  result = format("%s:%s", join("/", compact([registry, stage])), join("-", compact([version, flavor, suffix])))
}

group "default" {
  targets = ["_default"]
}

target "_default" {
  name = format_name("${stage}", "${SLURM_VERSION}", "${flavor}")
  context = "${flavor}/"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "${stage}", "${slurm_version("${SLURM_VERSION}")}", "${flavor}", "${DOCKER_BAKE_SUFFIX}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "${stage}", "${SLURM_VERSION}", "${flavor}", "${DOCKER_BAKE_SUFFIX}"),
  ]
  matrix = {
    stage = [
      "slurmctld",
      "slurmd",
      "slurmdbd",
      "slurmrestd",
      "sackd",
      "login",
    ]
    flavor = [
      "rockylinux9",
      "ubuntu24.04",
    ]
  }
  args = {
    SLURM_VERSION = "${SLURM_VERSION}"
    DEBUG = "${DEBUG}"
  }
  target = stage
}

target "rockylinux9" {
  name = format_name("${stage}", "${SLURM_VERSION}", "${flavor}")
  extends = [
    "_default",
  ]
  matrix = {
    stage = [
      "slurmctld",
      "slurmd",
      "slurmdbd",
      "slurmrestd",
      "sackd",
      "login",
    ]
    flavor = [
      "rockylinux9",
    ]
  }
}

target "ubuntu2404" {
  name = format_name("${stage}", "${SLURM_VERSION}", "${flavor}")
  extends = [
    "_default",
  ]
  matrix = {
    stage = [
      "slurmctld",
      "slurmd",
      "slurmdbd",
      "slurmrestd",
      "sackd",
      "login",
    ]
    flavor = [
      "ubuntu24.04",
    ]
  }
}
