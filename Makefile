PROJECTNAME=$(shell basename "$(PWD)")
MAKEFLAGS += --silent

# Docker/ECR variables
ECR_REGISTRY=721041513556.dkr.ecr.eu-central-1.amazonaws.com
ECR_REGION=eu-central-1
IMAGE_NAME=$(PROJECTNAME)
TAG?=$(shell git rev-parse --abbrev-ref HEAD)
AWS_PROFILE?=production

## build: Builds the project binary `bin/pact-contractor`
build:
	go build -o bin/$(PROJECTNAME) main.go

## run: Run given command. e.g; make run cmd="push -b my-bucket"
run:
	go run main.go $(cmd)

## docker-login: Authenticate with AWS ECR. Usage: make docker-login [AWS_PROFILE=production]
docker-login:
	@echo "Authenticating with ECR..."
	AWS_PROFILE=$(AWS_PROFILE) aws ecr get-login-password --region $(ECR_REGION) | docker login --username AWS --password-stdin $(ECR_REGISTRY)

## docker-build: Build Docker image. Usage: make docker-build [TAG=branch-name]
docker-build:
	@echo "Building Docker image: $(IMAGE_NAME):$(TAG)"
	docker build -t $(IMAGE_NAME):$(TAG) -f Dockerfile .

## docker-tag: Tag Docker image for ECR. Usage: make docker-tag [TAG=branch-name]
docker-tag:
	@echo "Tagging image for ECR: $(ECR_REGISTRY)/$(IMAGE_NAME):$(TAG)"
	docker tag $(IMAGE_NAME):$(TAG) $(ECR_REGISTRY)/$(IMAGE_NAME):$(TAG)

## docker-push: Push Docker image to ECR. Usage: make docker-push [TAG=branch-name]
docker-push:
	@echo "Pushing image to ECR: $(ECR_REGISTRY)/$(IMAGE_NAME):$(TAG)"
	docker push $(ECR_REGISTRY)/$(IMAGE_NAME):$(TAG)

## docker-all: Build, tag and push Docker image to ECR. Usage: make docker-all [TAG=branch-name] [AWS_PROFILE=production]
docker-all: docker-login docker-build docker-tag docker-push
	@echo "✅ Docker image successfully pushed to ECR: $(ECR_REGISTRY)/$(IMAGE_NAME):$(TAG)"

## release: Releases new version of the binary and submits to GitHub. Remember to have the GITHUB_TOKEN env var present. Provide VERSION to set the released version. E.g. make release VERSION=v0.1.1
release:
	git tag -fa $(VERSION)
	git push -f origin $(VERSION)
	goreleaser --rm-dist

## revert-tag: Removes tag from local and origin to reissue release again
revert-tag:



.PHONY: help
all: help
help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo