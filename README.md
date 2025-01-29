# konflux-ci/paketo

This project contains the information used by [cachi2](containerbuildsystem), executed part of the Konflux `prefetch-dependencies` task (see the prefetch-input `parameter` of the [pipelinerun](.tekton/paketo-container-push.yaml)), to download the go modules needed to build the binary of the different applications.

Such applications are declared as [git submodules](.gitmodules) and listed hereafter

- [pack](https://github.com/redhat-buildpacks/fork-pack),
- [jam](https://github.com/redhat-buildpacks/fork-jam),
- [create-package](https://github.com/redhat-buildpacks/fork-libpak),
- [toml](https://github.com/pelletier/go-toml) lib
- [dockerfile-json](https://github.com/keilerkonzept/dockerfile-json)

The commands to build them, to move the binary within the `/usr/bin` folder, etc. are declared part of the [Dockerfile](Containerfile).
Such a Dockerfile is build using the konflux [pipeline](.tekton/build-pipeline.yaml) - see task `build-container`.

The RPMs which should also be installed to build the project or within the final image created top of a fedora image
are listed part of the file [rpms.in.yaml](rpms.in.yaml). The rpm urls are populated using the [tool](https://github.com/konflux-ci/rpm-lockfile-prototype) within the lock file: [rpms.lock.yaml](rpms.lock.yaml) and their [ubi.repo](ubi.repo).

The image generated `quay.io/redhat-user-workloads/cmoullia-tenant/paketo-container/paketo-container` by konflux 
is pushed on the quay registry: https://quay.io/repository/redhat-user-workloads/cmoullia-tenant/paketo-container/paketo-container?tab=tags&tag=latest

You can check locally the availability of the tools by running this command:
```bash
podman run -it quay.io/redhat-user-workloads/cmoullia-tenant/paketo-container/paketo-container:<TAG> pack
podman run -it -v "$(pwd):/source:Z" quay.io/redhat-user-workloads/cmoullia-tenant/paketo-container/paketo-container:$TAG tomljson /source/builder.toml
```

# How to guide

This section details what you should do as developer to design a project able to create an image packaging the executable that you need
and that you will next use on konflux to build your own artefacts in a hermetic environment. You will then be able to replace the default `buildah` image with yours
within the task: `build-container`.

To get the [rpms.lock.yaml](rpms.lock.yaml) it is needed to install the following python tool: `rpm-lockfile-prototype` on a rhel/fedora machine:
```bash
sudo dnf install skopeo

python -m venv venv --system-site-packages
. venv/bin/activate
pip install --user https://github.com/konflux-ci/rpm-lockfile-prototype/archive/refs/heads/main.zip
git clone git@github.com:konflux-ci/paketo-container.git && cd paketo-container
rpm-lockfile-prototype rpms.in.yaml
```
**Note**: Upstream documentation: https://konflux-ci.dev/docs/how-tos/configuring/prefetching-dependencies/#enabling-prefetch-builds-for-rpm

OR to run the tool using a container on macOS/Windows machines

```bash
container_dir=./work
podman run --rm -v $PWD:$container_dir quay.io/svghadi/rpm-lockfile-prototype:latest --outfile=$container_dir/rpms.lock.yaml $container_dir/rpms.in.yaml
```






