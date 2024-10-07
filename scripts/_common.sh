#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

function log::info() {
	printf "%s\n" "$*"
}

function log::error() {
	printf "%s\n" "$*" 1>&2
}

function common::get_dockerfiles_dir() {
	local container_dir="${1-"schedmd/"}"
	local files=()
	local dockerfiles=()

	readarray -t -d $'\n' files <<<"$(find "$container_dir" -name "Dockerfile")"
	readarray -t -d $'\n' dockerfiles < <(echo "${files[*]}" | tr ' ' $'\n' | grep -oE ".*/Dockerfile$" | sort | uniq)

	echo "${dockerfiles[@]}"
}

function common::get_dockerfiles_sha() {
	local commit_sha="$1"
	local files_changed=()
	local dockerfiles=()

	readarray -t -d $'\n' files_changed <<<"$(git diff-tree --no-commit-id --name-only -r "$commit_sha")"
	readarray -t -d $'\n' dockerfiles < <(echo "${files_changed[*]}" | tr ' ' $'\n' | grep -oE ".*/Dockerfile$" | sort | uniq)

	echo "${dockerfiles[@]}"
}

function common::convert_to_tag() {
	local dockerfile_path="$1"
	local registry="${2-""}"
	local target="${3-""}"
	local version="${4-""}"
	local suffix="${5-""}"
	local image=""
	local tag=""

	image="$(echo "$dockerfile_path" | grep -Eo "schedmd/.*$" | sed -e 's;^schedmd/;;g' -e 's;/[^/]*/Dockerfile$;;g')"
	tag="$(echo "$dockerfile_path" | grep -Eo "schedmd/.*$" | sed -e 's;^schedmd/[^/]*/;;g' -e 's;/Dockerfile$;;g' -e 's;/;-;g')"

	if [ -n "$target" ]; then
		image="${target}"
	fi
	if [ -n "$version" ]; then
		tag="${version}-${tag}"
	fi

	local image_str="${image}:${tag}"
	if [ -n "$registry" ]; then
		image_str="${registry}/${image_str}"
	fi
	if [ -n "$suffix" ]; then
		image_str="${image_str}-${suffix}"
	fi
	echo "$image_str"
}
