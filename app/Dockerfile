FROM golang:alpine as builder
ADD ./src /app
WORKDIR /app 
RUN CGO_ENABLED=0 go build -o main .

# FROM scratch
FROM gcr.io/distroless/static
COPY --from=builder /app/main /main
ENTRYPOINT [ "/main" ]