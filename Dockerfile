FROM golang:alpine as builder

WORKDIR /app

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s"  -o myexec cmd/launch/main.go

FROM scratch

WORKDIR /app

COPY --from=builder /app/myexec /usr/bin/

ENTRYPOINT ["myexec"]