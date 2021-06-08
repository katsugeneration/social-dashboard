import os
import datetime
import requests
import io
from google.cloud import storage
from google.cloud import datacatalog_v1
from fastapi import FastAPI, Response

app = FastAPI(debug=False)


@app.post("/")
def handler():
    storage_client = storage.Client()

    # The name for the new bucket
    bucket_name = "jasso-gakuseiseikatsu-stats-raw"
    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT")
    region = os.environ.get("GCLOUD_REGION")

    # Creates the new bucket
    bucket = storage_client.bucket(bucket_name)
    if not bucket.exists():
        bucket.create(location=region)

    datacatalog = datacatalog_v1.DataCatalogClient()
    entry_group = datacatalog.get_entry_group(
        name=datacatalog_v1.DataCatalogClient.entry_group_path(
            project_id, region, "social_data"
        )
    )
    tag_template = datacatalog.get_tag_template(
        name=datacatalog_v1.DataCatalogClient.tag_template_path(
            project_id, region, "data_ingestion"
        )
    )

    entry = datacatalog_v1.types.Entry()
    entry.display_name = bucket_name
    entry.gcs_fileset_spec.file_patterns.append(f"gs://{bucket_name}/*.xlsx")
    entry.type_ = datacatalog_v1.EntryType.FILESET
    entry = datacatalog.create_entry(
        parent=entry_group.name, entry_id="jasso_gakuseiseikatsu_stats_raw", entry=entry
    )

    tag = datacatalog_v1.types.Tag()
    tag.template = tag_template.name
    tag.fields["data_sources"] = datacatalog_v1.types.TagField()
    tag.fields[
        "data_sources"
    ].string_value = (
        "JASSO学生生活調査 https://www.jasso.go.jp/about/statistics/gakusei_chosa/index.html"
    )
    tag.fields["license"] = datacatalog_v1.types.TagField()
    tag.fields[
        "license"
    ].string_value = "日本学生支援機構が「学生生活調査」「高等専門学校生生活調査」「専修学校生生活調査」の結果として公開している情報は、出典の記載をしていただいた上で、どなたでも自由に利用できます。 https://www.jasso.go.jp/about/statistics/gakusei_chosa/riyou.html"
    tag = datacatalog.create_tag(parent=entry.name, tag=tag)

    tag.fields["latest_job_status"] = datacatalog_v1.types.TagField()
    tag.fields[
        "latest_job_status"
    ].enum_value = datacatalog_v1.types.TagField.EnumValue()
    tag.fields["latest_job_status"].enum_value.display_name = "running"
    tag.fields["latest_job_start_datetime"] = datacatalog_v1.types.TagField()
    tag.fields["latest_job_start_datetime"].timestamp_value = datetime.datetime.now()
    tag = datacatalog.update_tag(tag=tag)

    raw_dir = bucket.blob("data18_2.xlsx")
    res = requests.get(
        "https://www.jasso.go.jp/about/statistics/gakusei_chosa/__icsFiles/afieldfile/2020/03/16/data18_2.xlsx"
    )
    content = None
    if res.status_code == 200:
        content = io.BytesIO(res.content)
    res.close()
    raw_dir.upload_from_file(content)

    tag.fields["latest_job_status"] = datacatalog_v1.types.TagField()
    tag.fields[
        "latest_job_status"
    ].enum_value = datacatalog_v1.types.TagField.EnumValue()
    tag.fields["latest_job_status"].enum_value.display_name = "completed"
    tag.fields["latest_job_end_datetime"] = datacatalog_v1.types.TagField()
    tag.fields["latest_job_end_datetime"].timestamp_value = datetime.datetime.now()
    tag.fields["latest_job_run_time"] = datacatalog_v1.types.TagField()
    tag.fields["latest_job_run_time"].string_value = str(
        tag.fields["latest_job_end_datetime"].timestamp_value
        - tag.fields["latest_job_start_datetime"].timestamp_value
    )
    tag = datacatalog.update_tag(tag=tag)

    return Response(status_code=200)
