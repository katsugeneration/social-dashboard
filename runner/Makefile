build:
	gcloud builds submit ./$(SERVICE_NAME) --tag gcr.io/$(PROJECT_ID)/social-dashboard/$(SERVICE_NAME):latest

deploy: build
	gcloud run deploy $(SERVICE_NAME) --image gcr.io/$(PROJECT_ID)/social-dashboard/$(SERVICE_NAME):latest