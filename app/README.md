# Sample Application

A simple server written in Go that prints the greeting provided as argument.

```bash
# run app
PORT=5555 go run src/main.go --greeting="hi"

# verify
curl http://localhost:${PORT}
// hi

curl http://localhost:${PORT}/health
# > ok

# build & run app
go build -o bin/app ./src/
./bin/app

# build & run tests
go test -c -o bin/test ./src/
./bin/test
```
