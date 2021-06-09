# social-dashboard
Social Data Dashboard and Data Processing


# Develop
## Up develop environment

```shell
export AWS_PROFILE={profile}
export AWS_DEFAULT_REGION={region}
make build
make updev
```

## Down develop environment

```shell
make downdev
```

## Development
First time, you set following variables to github secrets for CI/CD on githuba actions
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- GCP_PROJECT_ID
- GCLOUD_REGION
- GCP_SERVICE_ACCOUNT_KEY

### terraform
First time, you set gcp service account credential file to your local environment, and set file path toenvironmant variable `GOOGLE_APPLICATION_CREDENTIALS`.

And you also set aws access information in your local machine.

### dbt
First time, you set gloud token to `~/.config/gcloud` directory in your local machine

```shell
gcloud auth application-default login
```

After, you set poetry environment for running dbt
```shell
poetry shell
```

For check configuration, you run under command
```shell
dbt debug --project-dir dbt/ --profiles-dir dbt/ --vars '{bq_dataset_name: <BQ_DATASET_NAME>}'
```

### runner
First time, you set gcp service account credential file to your local environment, and set file path toenvironmant variable `GOOGLE_APPLICATION_CREDENTIALS`, and install gcloud.

Runners are build on Cloud Build and deployed and ran on Cloud Runner. So, you create cloud run service and pub/sub whose names are same as runner by terraform topic before deploy and run.

## CI
Check terraform and dbt script when You create pull request. Check details are following.
- terraform
    - check for formot and actual diff by `terraform plan`
- dbt
    - check configuration and parse jinja by `dbt debug` and `dbt parse`
- runner
    - check build is successed by `gcloud builds submit`

## CD
Deploy terraform and dbt script when You create pull request. Deploy details are following.
- terraform
    - deploy diff by `terraform apply`
    - check diff is nothing by `terraform plam`
- dbt
    - Deploay sata model by `dbt run`
    - Check deploy results by `dbt test`
- runner
    - deploy to cloud run service by `gcloud run deploy`