// SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
// SPDX-License-Identifier: Apache-2.0

################################################################################

slurm_version = "24.05.8"
linux_flavor = "rockylinux9"

################################################################################

group "all" {
  targets = [
    "core",
  ]
}

group "core" {
  targets = [
    "slurmctld",
    "slurmd",
    "slurmdbd",
    "slurmrestd",
    "sackd",
  ]
}

group "extras" {
  targets = []
}

group "extras-dev" {
  targets = []
}
