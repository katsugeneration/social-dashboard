build:
	gcloud builds submit ./$(SERVICE_NAME) --tag gcr.io/$(PROJECT_ID)/social-dashboard/$(SERVICE_NAME):latest

deploy:
	gcloud run deploy $(SERVICE_NAME) --image gcr.io/$(PROJECT_ID)/social-dashboard/$(SERVICE_NAME):latest --update-env-vars GOOGLE_CLOUD_PROJECT=$(PROJECT_ID),GCLOUD_REGION=$(GCLOUD_REGION)

build_and_deploy: build deploy

trigger:
	gcloud pubsub topics publish $(SERVICE_NAME) --message=$(MESSAGE)