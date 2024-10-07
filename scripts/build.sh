#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

CONTAINER_BUILD=1
CONTAINER_PULL=0
CONTAINER_PUSH=0
CONTAINER_DIR="$(dirname "$0")/schedmd/"
REGISTRY=""
REGISTRY_TARGET=""
IMAGE_SUFFIX=""
SLURM_VERSION="24.05"
BUILD_TARGET="slurm"
CONTAINER_BUILD_FLAGS=""

# shellcheck disable=SC1091
source "$(dirname "$0")/_common.sh"

function build() {
	local dockerfiles=("$@")
	local dockerfile_path_abs=""
	local dockerfile_dir_abs=""
	local container_image=""
	local dir=""
	local target_image=""

	dir="$(git rev-parse --show-toplevel)"
	for dockerfile_path in "${dockerfiles[@]}"; do
		dockerfile_path_abs="$dir/$dockerfile_path"
		dockerfile_dir_abs="$(dirname "$dockerfile_path_abs")"
		container_image="$(common::convert_to_tag "$dockerfile_path" "$REGISTRY" "$BUILD_TARGET" "$SLURM_VERSION" "$IMAGE_SUFFIX")"
		target_image="$container_image"

		echo "container_image=$container_image"
		echo "target_image=$target_image"
		if ((CONTAINER_PULL)); then
			docker pull "$container_image"
		fi
		if ((CONTAINER_BUILD)); then
			eval "docker build $CONTAINER_BUILD_FLAGS -t $container_image -f $dockerfile_path_abs $dockerfile_dir_abs"
		fi
		if [ -n "$REGISTRY_TARGET" ]; then
			target_image="$(common::convert_to_tag "$dockerfile_path" "$REGISTRY_TARGET" "$BUILD_TARGET" "$SLURM_VERSION" "$IMAGE_SUFFIX")"
			docker tag "$container_image" "$target_image"
		fi
		if ((CONTAINER_PUSH)); then
			docker push "$target_image"
		fi
	done
}

function main::help() {
	cat <<EOF
$(basename "$0") - Build container images

	usage: $(basename "$0") [OPTIONS]... [CONTAINER_DIR]

	Steps:
	1. Pull  - [optional] call with --pull
	2. Build - [always] skip with --no-build
	3. Tag   - [optional] call with --new-registry
	4. Push  - [optional] call with --push

ARGUMENTS:
	CONTAINER_DIR       The directory to recursively build from.
	                      (default: "$CONTAINER_DIR")

OPTIONS:
	--debug-build       Configure container build debugging mode.
	--debug-image       Set DEBUG=1 for image argument.
	--registry=<reg>    The registry to prefix the images with.
	--new-registry=<reg> Re-tag images after build step and before push step.
	--slurm-version=<ver> Override the Slurm version to build
	                      (default: "$SLURM_VERSION").
	--suffix=<sfx>      The suffix to append onto the images.
	--target=<stage>    The multi-build stage to build
	                      (default "$BUILD_TARGET").
	--no-build          Skip container image build step.
	--no-cache          Build image without cache.
	-h, --help          Show this help message.
	--pull              Pull container image before build step.
	--push              Push container image after build step,
	                      respects --new-registry=<reg>.

EOF
}

function main() {
	local dockerfiles=()
	local dockerfiles_json=""

	readarray -t -d $'\n' dockerfiles <<<"$(common::get_dockerfiles_dir "$CONTAINER_DIR" | tr ' ' '\n')"

	dockerfiles_json="$(printf "%s\n" "${dockerfiles[@]}" | jq -R . | jq -cs .)"
	echo "dockerfiles=${dockerfiles_json}"

	build "${dockerfiles[@]}"
}

SHORT="+h"
LONG="debug-build,debug-image,no-build,no-cache,target:,pull,push,registry:,new-registry:,slurm-version:,suffix:,help"
OPTS="$(getopt -a --options "$SHORT" --longoptions "$LONG" -- "$@")"
eval set -- "${OPTS}"
while :; do
	case "$1" in
	--debug-build)
		CONTAINER_BUILD_FLAGS="${CONTAINER_BUILD_FLAGS} --progress=plain"
		shift
		;;
	--debug-image)
		CONTAINER_BUILD_FLAGS="${CONTAINER_BUILD_FLAGS} --build-arg DEBUG=1"
		shift
		;;
	--no-cache)
		CONTAINER_BUILD_FLAGS="${CONTAINER_BUILD_FLAGS} --no-cache --pull"
		shift
		;;
	--no-build)
		CONTAINER_BUILD=0
		shift
		;;
	--pull)
		CONTAINER_PULL=1
		shift
		;;
	--push)
		CONTAINER_PUSH=1
		shift
		;;
	--registry)
		REGISTRY="$2"
		shift 2
		;;
	--new-registry)
		REGISTRY_TARGET="$2"
		shift 2
		;;
	--slurm-version)
		SLURM_VERSION="$2"
		CONTAINER_BUILD_FLAGS="${CONTAINER_BUILD_FLAGS} --build-arg SLURM_VERSION=$SLURM_VERSION"
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
