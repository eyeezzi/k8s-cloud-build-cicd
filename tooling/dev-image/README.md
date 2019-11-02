# Image to be use in cloud build steps

```sh
# build image & run the image
docker build -t my-build-image .
docker run --rm -it --entrypoint bash my-build-image
go version && make -v && kubectl version

# make image available to Cloud Build
gcloud builds submit --config cloudbuild.yaml .
```