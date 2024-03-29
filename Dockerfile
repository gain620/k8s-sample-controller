# Build the sidecar-injector binary
FROM golang:1.18-alpine3.16 as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download; \
    apk update; \
    apk add upx;

# Copy the go source
COPY cmd/ cmd/

# Build
RUN go fmt ./...; \
    go vet ./...; \
    go test ./... -coverprofile cover.out; \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-s -w' -o sidecar-injector ./cmd; \
    upx -9 sidecar-injector;
#    upx --lzma sidecar-injector;

FROM alpine:latest

# install curl for prestop script
RUN apk --no-cache add curl

WORKDIR /

# install binary
COPY --from=builder /workspace/sidecar-injector .

# install the prestop script
COPY ./prestop.sh .

USER 65532:65532

ENTRYPOINT ["/sidecar-injector"]
