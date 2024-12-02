#FROM registry.access.redhat.com/ubi9/ubi:latest@sha256:b00d5990a00937bd1ef7f44547af6c7fd36e3fd410e2c89b5d2dfc1aff69fe99 as builder
FROM registry.fedoraproject.org/fedora:42 as builder

RUN dnf -y install golang gcc

# Build toml: Go mod version: 1.22.0
WORKDIR /go/src/buildpacks/toml
COPY toml/ .
RUN CGO_ENABLED=0 GOTOOLCHAIN=go1.22.0 go build -ldflags "-s -w" -a ./cmd/tomljson

# Build pack: Go mod version: 1.22.0
WORKDIR /go/src/buildpacks/pack
COPY pack/ .
RUN CGO_ENABLED=0 GOTOOLCHAIN=go1.22.0 go build -ldflags "-s -w" -a ./cmd/pack

# Build jam: Go mod version: 1.18
WORKDIR /go/src/buildpacks/jam
COPY jam/ .
RUN CGO_ENABLED=0 go build -ldflags "-X github.com/paketo-buildpacks/jam/v2/commands.jamVersion=v2.9.0" -o jam main.go

# Build create-package. Go mod version: 1.23
WORKDIR /go/src/buildpacks/create-package
COPY create-package/ .
RUN CGO_ENABLED=0 GOTOOLCHAIN=go1.23.0 go build -ldflags="-s -w" -o create-package -a ./cmd/create-package/main.go

# Rebase on ubi9
#FROM registry.access.redhat.com/ubi9:latest@sha256:9e6a89ab2a9224712391c77fab2ab01009e387aff42854826427aaf18b98b1ff
FROM registry.fedoraproject.org/fedora:42
RUN dnf -y install gettext jq podman

COPY --from=builder /go/src/buildpacks/toml/tomljson                   /usr/bin/tomljson
COPY --from=builder /go/src/buildpacks/pack/pack                       /usr/bin/pack
COPY --from=builder /go/src/buildpacks/jam/jam                         /usr/bin/jam
COPY --from=builder /go/src/buildpacks/create-package/create-package   /usr/bin/create-package

WORKDIR /workdir

RUN \
  groupadd -g 1000 paketo; \
  useradd -u 1000 -g paketo -s /bin/sh -d /home/paketo paketo

RUN chown -R paketo:paketo /workdir

USER paketo
COPY scripts/run /usr/bin/run

ENTRYPOINT ["/usr/bin/run"]
