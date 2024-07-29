# Support FROM override
FROM golang:1.22 AS builder

WORKDIR /workspace

# Bring in the go dependencies before anything else so we can take
# advantage of caching these layers in future builds.

# set GOPROXY to use the goproxy.cn to speed up the build
ENV GOPROXY='https://goproxy.cn,direct'
ENV GO111MODULE=on
COPY go.mod go.mod
COPY go.sum go.sum
COPY apis/go.mod apis/go.mod
COPY apis/go.sum apis/go.sum
COPY hack/tools/go.mod hack/tools/go.mod
COPY hack/tools/go.sum hack/tools/go.sum
COPY pkg/hardwareutils/go.mod pkg/hardwareutils/go.mod
COPY pkg/hardwareutils/go.sum pkg/hardwareutils/go.sum
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GO111MODULE=on go build -a -o baremetal-operator main.go

# Copy the controller-manager into a thin image
# BMO has a dependency preventing us to use the static one,
# using the base one instead
FROM alpine:latest
WORKDIR /
COPY --from=builder /workspace/baremetal-operator .
USER nonroot:nonroot
ENTRYPOINT ["/baremetal-operator"]

LABEL io.k8s.display-name="Metal3 BareMetal Operator" \
      io.k8s.description="This is the image for the Metal3 BareMetal Operator."
