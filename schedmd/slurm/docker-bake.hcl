// SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
// SPDX-License-Identifier: Apache-2.0

variable "DOCKER_BAKE_REGISTRY" {}

variable "DOCKER_BAKE_SUFFIX" {}

variable "DOCKER_BAKE_DEBUG_IMAGE" {
  default = "0"
}

function "format_name" {
  params = [stage, version, flavor]
  // Remove [:punct:] from string before joining elements
  // NOTE: function library does not seem to support any character classes, have to regex manually
  result = join("_", [regex_replace(stage, "[!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~.]", ""), regex_replace(version, "[!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~.]", ""), regex_replace(flavor, "[!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~.]", "")])
}

function "format_tag" {
  params = [registry, stage, version, flavor, suffix]
  result = format("%s:%s", join("/", compact(["${registry}", "${stage}"])), join("-", compact(["${version}", "${flavor}", "${suffix}"])))
}

group "default" {
  targets = ["_default"]
}

target "_default" {
  name = format_name("${stage}", "${version}", "${flavor}")
  context = "${flavor}/"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "${stage}", "${version}", "${flavor}", "${DOCKER_BAKE_SUFFIX}"),
  ]
  matrix = {
    stage = [
      "slurmctld",
      "slurmd",
      "slurmdbd",
      "slurmrestd",
      "sackd",
    ]
    version = [
      "master",
      "24.05",
    ]
    flavor = [
      "rockylinux-9",
      "ubuntu-24.04",
    ]
  }
  args = {
    DEBUG = "${DOCKER_BAKE_DEBUG_IMAGE}"
    SLURM_VERSION = "${version}"
  }
  target = stage
}

group "master" {
  targets = [
    "master_rockylinux9",
    "master_ubuntu2404",
  ]
}

group "2405" {
  targets = [
    "2405_rockylinux9",
    "2405_ubuntu2404",
  ]
}

group "rockylinux" {
  targets = [
    "master_rockylinux9",
    "2405_rockylinux9",
  ]
}

group "ubuntu" {
  targets = [
    "master_ubuntu2404",
    "2405_ubuntu2404",
  ]
}

target "master_rockylinux9" {
  name = format_name("${stage}", "${version}", "${flavor}")
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
    ]
    version = [
      "master",
    ]
    flavor = [
      "rockylinux-9",
    ]
  }
}

target "2405_rockylinux9" {
  name = format_name("${stage}", "${version}", "${flavor}")
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
    ]
    version = [
      "24.05",
    ]
    flavor = [
      "rockylinux-9",
    ]
  }
}

target "master_ubuntu2404" {
  name = format_name("${stage}", "${version}", "${flavor}")
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
    ]
    version = [
      "master",
    ]
    flavor = [
      "ubuntu-24.04",
    ]
  }
}

target "2405_ubuntu2404" {
  name = format_name("${stage}", "${version}", "${flavor}")
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
    ]
    version = [
      "24.05",
    ]
    flavor = [
      "ubuntu-24.04",
    ]
  }
}
