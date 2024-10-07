# Quickstart

## Table of Contents

<!-- mdformat-toc start --slug=github --no-anchors --maxlevel=6 --minlevel=1 -->

- [Quickstart](#quickstart)
  - [Table of Contents](#table-of-contents)
  - [Docker Buildx Bake](#docker-buildx-bake)

<!-- mdformat-toc end -->

## Docker Buildx Bake

```bash
cd ./schedmd/slurm
export DOCKER_BAKE_REGISTRY="<REGISTRY>"
docker buildx bake --print
docker buildx bake <TARGET>
docker buildx bake --push
```
