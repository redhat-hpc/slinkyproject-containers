# Build

## Table of Contents

<!-- mdformat-toc start --slug=github --no-anchors --maxlevel=6 --minlevel=1 -->

- [Build](#build)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Compatibility](#compatibility)
  - [Slurm](#slurm)
    - [With Custom Registry](#with-custom-registry)
  - [Development](#development)

<!-- mdformat-toc end -->

## Overview

Instructions for building images via [docker bake].

### Compatibility

| Software      |                      Minimum Version                       |
| ------------- | :--------------------------------------------------------: |
| Docker Engine | [28.1.0](https://docs.docker.com/engine/release-notes/28/) |

## Slurm

Build Slurm from the selected Slurm version and Linux flavor.

```sh
export BAKE_IMPORTS="--file ./docker-bake.hcl --file ./$VERSION/$FLAVOR/slurm.hcl"
cd ./schedmd/slurm/
docker bake $BAKE_IMPORTS --print
docker bake $BAKE_IMPORTS
```

For example:

```sh
export BAKE_IMPORTS="--file ./docker-bake.hcl --file ./25.05/rockylinux9/slurm.hcl"
cd ./schedmd/slurm/
docker bake $BAKE_IMPORTS --print
docker bake $BAKE_IMPORTS
```

### With Custom Registry

Build Slurm from the selected Slurm version and Linux flavor.

```sh
export REGISTRY="foo"
export BAKE_IMPORTS="--file ./docker-bake.hcl --file ./$VERSION/$FLAVOR/slurm.hcl"
cd ./schedmd/slurm/
docker bake $BAKE_IMPORTS --print
docker bake $BAKE_IMPORTS
```

## Development

Build Slurm from the selected repository and branch for a Slurm version and
Linux flavor.

> [!NOTE]
> The docker SSH agent is used to avoid credentials leaking into the image
> layers. You will need to add a default private key if the target repository is
> private.

```sh
ssh-add ~/.ssh/id_ed25519 # if private repo
```

Build Slurm from the selected Slurm version and Linux flavor.

```sh
export GIT_REPO=git@github.com:SchedMD/slurm.git
export GIT_BRANCH=master
export BAKE_IMPORTS="--file ./docker-bake.hcl --file ./$VERSION/$FLAVOR/slurm.hcl"
cd ./schedmd/slurm/
docker bake $BAKE_IMPORTS dev --print
docker bake $BAKE_IMPORTS dev
```

<!-- Links -->

[docker bake]: https://docs.docker.com/build/bake/introduction/
