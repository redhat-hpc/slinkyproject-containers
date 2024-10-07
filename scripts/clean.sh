#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

CONTAINER_DIR="schedmd/"
REGISTRY=""
IMAGE_SUFFIX=""
SLURM_VERSION="24.05"
BUILD_TARGET="slurm"

# shellcheck disable=SC1091
source "$(dirname "$0")/_common.sh"

function clean() {
	local dockerfiles=("$@")
	local container_image=""
	local container_images=()

	for dockerfile_path in "${dockerfiles[@]}"; do
		container_image="$(common::convert_to_tag "$dockerfile_path" "$REGISTRY" "$BUILD_TARGET" "$SLURM_VERSION" "$IMAGE_SUFFIX")"

		readarray -t -d $'\n' container_images <<<"$(docker images --format '{{.Repository}}:{{.Tag}}' --filter reference="$container_image")"
		if ((${#container_images[@]} > 0)) && [ -n "${container_images[*]}" ]; then
			echo "container_images=${container_images[*]}"
			eval "docker rmi ${container_images[*]}"
		fi
	done
}

function main::help() {
	cat <<EOF
$(basename "$0") - Clean up container images

	usage: $(basename "$0") [OPTIONS]... [CONTAINER_DIR]

ARGUMENTS:
	CONTAINER_DIR       The directory to recursively clean based on.
	                      (default: "$CONTAINER_DIR")

OPTIONS:
	--registry=<reg>    The registry to prefix the images with.
	--slurm-version=<ver> Override the Slurm version to build
	                      (default: "$SLURM_VERSION").
	--suffix=<sfx>      The suffix to append onto the images.
	--target=<stage>    The multi-build stage to build
	                      (default "$BUILD_TARGET").
	-h, --help          Show this help message.

EOF
}

function main() {
	local dockerfiles=()
	local dockerfiles_json=""

	readarray -t -d $'\n' dockerfiles <<<"$(common::get_dockerfiles_dir "$CONTAINER_DIR" | tr ' ' '\n')"

	dockerfiles_json="$(printf "%s\n" "${dockerfiles[@]}" | jq -R . | jq -cs .)"
	echo "dockerfiles=${dockerfiles_json}"

	clean "${dockerfiles[@]}"
}

SHORT="+h"
LONG="registry:,slurm-version:,suffix:,target:,help"
OPTS="$(getopt -a --options "$SHORT" --longoptions "$LONG" -- "$@")"
eval set -- "${OPTS}"
while :; do
	case "$1" in
	--registry)
		REGISTRY="$2"
		shift 2
		;;
	--slurm-version)
		SLURM_VERSION="$2"
		shift 2
		;;
	--suffix)
		IMAGE_SUFFIX="$2"
		shift 2
		;;
	--target)
		BUILD_TARGET="${2-"$BUILD_TARGET"}"
		CONTAINER_BUILD_FLAGS="${CONTAINER_BUILD_FLAGS} --target=$BUILD_TARGET"
		shift 2
		;;
	-h | --help)
		main::help
		shift
		exit 0
		;;
	--)
		shift
		CONTAINER_DIR="${1-"$CONTAINER_DIR"}"
		break
		;;
	*)
		log::error "Unknown option: $1"
		exit 1
		;;
	esac
done

main
