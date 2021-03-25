# Build the manager binary
FROM golang:1.13 as builder
USER root
RUN apt-get update
RUN apt-get install -y git
#RUN git config --global url."git@github.com/q8s-io/iapetos.git:".insteadOf "https://github.com/q8s-io/iapetos.git"
git config --global url."git@github.com:".insteadOf "https://github.com/"
ARG SSH_PRIVATE_KEY
RUN mkdir /root/.ssh/
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa

RUN touch /root/.ssh/config
RUN echo "StrictHostKeyChecking no" > /root/.ssh/config
RUN echo "UserKnownHostsFile /dev/null" >> /root/.ssh/config
WORKDIR /workspace
go get github.com/q8s-io/iapetos
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -o manager main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY ./config /config
COPY --from=builder /workspace/manager .
USER nonroot:nonroot

ENTRYPOINT ["/manager"]
