FROM registry.fedoraproject.org/fedora:40 as builder

RUN dnf -y install golang gcc

# Build dockerfile-json tool
WORKDIR /go/src/buildpacks/dockerfile-json
COPY dockerfile-json/ .
RUN CGO_ENABLED=0 GOTOOLCHAIN=go1.23.0 go build -ldflags "-s -w" -o dockerfile-json .

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

FROM registry.fedoraproject.org/fedora:40
RUN dnf -y install gettext jq podman buildah python pip

# Install the Python modules collected by cachi2
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY --from=builder /go/src/buildpacks/dockerfile-json/dockerfile-json   /usr/bin/dockerfile-json
COPY --from=builder /go/src/buildpacks/toml/tomljson                     /usr/bin/tomljson
COPY --from=builder /go/src/buildpacks/pack/pack                         /usr/bin/pack
COPY --from=builder /go/src/buildpacks/jam/jam                           /usr/bin/jam
COPY --from=builder /go/src/buildpacks/create-package/create-package     /usr/bin/create-package

WORKDIR /workdir

RUN \
  groupadd -g 1000 paketo; \
  useradd -u 1000 -g paketo -s /bin/sh -d /home/paketo paketo

RUN chown -R paketo:paketo /workdir

USER paketo
COPY scripts/run /usr/bin/run

ENTRYPOINT ["/usr/bin/run"]
