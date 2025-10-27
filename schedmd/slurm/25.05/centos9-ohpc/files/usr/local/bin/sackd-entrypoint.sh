#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# Additional arguments to pass to sackd.
export SACKD_OPTIONS="${SACKD_OPTIONS:-} $*"

function main() {
	mkdir -p /run/slurm/

	exec supervisord -c /etc/supervisord.conf
}
main
