build:
	cp -r clients ./$(SERVICE_NAME)/clients
	gcloud builds submit ./$(SERVICE_NAME) --tag gcr.io/$(PROJECT_ID)/social-dashboard/$(SERVICE_NAME):latest
	rm -rf ./$(SERVICE_NAME)/clients

deploy:
	gcloud run deploy $(SERVICE_NAME) --image gcr.io/$(PROJECT_ID)/social-dashboard/$(SERVICE_NAME):latest --region $(GCLOUD_REGION) --update-env-vars GOOGLE_CLOUD_PROJECT=$(PROJECT_ID),GCLOUD_REGION=$(GCLOUD_REGION)

build_and_deploy: build deploy

trigger:
	gcloud pubsub topics publish $(SERVICE_NAME) --message=$(MESSAGE)

run_server:
	cp -r clients ./$(SERVICE_NAME)/clients
	docker build -t social-dashboard/$(SERVICE_NAME):latest ./$(SERVICE_NAME)
	docker run --rm -v ~/.config:/root/.config -v $(shell pwd)/$(SERVICE_NAME):/app -e GOOGLE_CLOUD_PROJECT -e GCLOUD_REGION -p 8080:8080 social-dashboard/$(SERVICE_NAME):latest main:app --reload --host 0.0.0.0 --port 8080
	rm -rf ./$(SERVICE_NAME)/clients