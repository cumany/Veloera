# ------- 1. 前端构建 -------
FROM oven/bun:latest AS builder
WORKDIR /build
COPY web/package.json bun.lockb ./
RUN bun install --frozen-lockfile
COPY ./web ./
COPY ./VERSION ./
RUN DISABLE_ESLINT_PLUGIN=true \
    VITE_REACT_APP_VERSION=$(cat VERSION) \
    bun run build

# ------- 2. Go 后端构建 -------
FROM golang:alpine AS builder2
ENV GO111MODULE=on CGO_ENABLED=0 GOOS=linux
WORKDIR /build

COPY go.mod go.sum ./
RUN go env -w GOPROXY=https://goproxy.cn,direct && go mod download

COPY . ./
COPY --from=builder /build/dist ./web/dist
RUN go build -ldflags "-s -w -X 'veloera/common.Version=$(cat VERSION)'" -o veloera

# ------- 3. 运行时 -------
FROM alpine
RUN apk add --no-cache ca-certificates tzdata ffmpeg && update-ca-certificates
COPY --from=builder2 /build/veloera /
EXPOSE 3000
WORKDIR /data
ENTRYPOINT ["/veloera"]