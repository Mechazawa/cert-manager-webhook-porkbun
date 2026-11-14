FROM --platform=$BUILDPLATFORM golang:1.27.4-alpine3.24 AS build

ARG TARGETOS TARGETARCH

WORKDIR /workspace

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags '-s -w' -o webhook .

FROM gcr.io/distroless/static-debian13

COPY --from=build /workspace/webhook /usr/local/bin/webhook

ENTRYPOINT ["webhook"]
