# CI/CD Pipeline for K8s apps using Google Cloud Build

## Prerequisites

- Docker 19.03
- Terraform v0.12.7
- Go 1.13
- Make 3.81
- GCP Account
- DigitalOcean Account
- A purchased domain name

## Project Structure

```
.
├── README.md
├── app                                         Demo application we will be deploying called 'polite'
│   ├── Dockerfile                              Instructions on how Docker should containerize this application.
│   ├── Makefile
│   ├── README.md
│   ├── bin
│   ├── dev.cloudbuild.yaml                     Developer Pipeline: runs when PR is created/updated
│   ├── k8s                                     Contains the kubernetes resources to deploy the application.
│   ├── prod.cloudbuild.yaml                    Production Pipeline: runs when 'master' branch is tagged.
│   ├── src                                     Contains application source code.
│   └── staging.cloudbuild.yaml                 Staging Pipeline: runs when PR is merged into 'master' branch.
├── docs
│   ├── detailed-setup-steps.md
│   └── personal-cloudbuild-cicd.plantuml       A flow of how the entire CI/CD process works.
├── fe-app                                      TODO: A Next.js based frontend app to also test FE deployment.
│   ├── Makefile
│   ├── README.md
│   └── pages
├── infrastructure                              Contains Terraform files that provisions the clusters and other resources.
│   ├── README.md
│   ├── credentials                             gitignored
│   ├── do-k8s-cluster.tf                       Defines cluster and DNS resources on DigitalOcean
│   ├── gcp.tf                                  Defines service accounts on GCP
│   ├── graph.png                               A graph of all the Terraform-managed resources.
│   ├── main.tf
│   └── versions.tf
└── tooling                                     Custom helper scripts and processes to glue things together
    ├── deployer                                Instructions on how to authorize a pipeline to deploy to a cluster NS.
    ├── dev-image                               A custom cloud build image with Go1.3, Kubectl, and Make
    ├── image-pull-secret
    ├── namespaces                              Namespaces in the clusters.
    └── traefik                                 K8s resources to deploy Traefik 2.0 to a cluster.

```