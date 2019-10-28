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

## Build and Push Application Image to Google Container Registry (GCR)

Requires enabling *Container Registry API* on the Project.

```bash
# Use 'gcloud' tool to login to GCP project.
gcloud init
# > follow steps

# Make docker use gcloud for registry auth.
gcloud auth configure-docker

# build application image
PROJECT_ID=k8s-cicd-251209 \
IMAGE=polite \
TAG=v2 && \
docker build -t gcr.io/${PROJECT_ID}/${IMAGE}:${TAG} .

# push image to registry
PROJECT_ID=k8s-cicd-251209 \
IMAGE=polite \
TAG=v2 && \
docker push gcr.io/${PROJECT_ID}/${IMAGE}:${TAG}

# List images in GCR
gcloud container images list
```

## Other commands

```bash
# Test a service without exposing it to the internet yet.
# link a local port to a service port
kubectl -n $NAMESPACE port-forward services/$NAME $LOCAL:$REMOTE
```

## Change Management

### To test your changes

Open a PR for your feature branch.

### To deploy a feature to Staging

Merge the feature PR to `master`.

### To promote the feature from Staging to Production

Tag the merge commit on `master` with `vMAJOR.MINOR.PATCH`.

```
git tag --list
git tag [-f] v0.0.1 <branch|commit|object>
git push [-f] --tags
```