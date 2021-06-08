import os
import datetime
import requests
import io
import pandas as pd
from google.cloud import storage
from google.cloud import datacatalog_v1
from google.cloud import bigquery
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
    entry_group_id = "social_data"
    entry_group = datacatalog.get_entry_group(
        name=datacatalog_v1.DataCatalogClient.entry_group_path(
            project_id, region, entry_group_id
        )
    )
    tag_template = datacatalog.get_tag_template(
        name=datacatalog_v1.DataCatalogClient.tag_template_path(
            project_id, region, "data_ingestion"
        )
    )

    entry_id = "jasso_gakuseiseikatsu_stats_raw"
    entry = datacatalog.get_entry(
        name=datacatalog_v1.DataCatalogClient.entry_path(
            project_id, region, entry_group_id, entry_id
        )
    )
    if entry is None:
        entry = datacatalog_v1.types.Entry()
        entry.display_name = bucket_name
        entry.gcs_fileset_spec.file_patterns.append(f"gs://{bucket_name}/*.xlsx")
        entry.type_ = datacatalog_v1.EntryType.FILESET
        entry = datacatalog.create_entry(
            parent=entry_group.name, entry_id=entry_id, entry=entry
        )

    tags = list(datacatalog.list_tags(parent=entry.name))
    if len(tags) != 0:
        tag = tags[0]
    else:
        tag = datacatalog_v1.types.Tag()
        tag.template = tag_template.name
        tag.fields["data_sources"] = datacatalog_v1.types.TagField()
        tag.fields[
            "data_sources"
        ].string_value = "JASSO学生生活調査 https://www.jasso.go.jp/about/statistics/gakusei_chosa/index.html"
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

    entry_id = "jasso_gakuseiseikatsu_stats_annual_income_divide_university"
    entry = datacatalog.get_entry(
        name=datacatalog_v1.DataCatalogClient.entry_path(
            project_id, region, entry_group_id, entry_id
        )
    )
    if entry is None:
        entry = datacatalog_v1.types.Entry()
        entry.display_name = (
            "jasso-gakuseiseikatsu-stats-annual-income-divide-university"
        )
        entry.gcs_fileset_spec.file_patterns.append(
            "gs://jasso-gakuseiseikatsu-stats-annual-income-divide-university/*.parquet"
        )
        entry.type_ = datacatalog_v1.EntryType.FILESET

        columns = []
        columns.append(
            datacatalog_v1.types.ColumnSchema(
                column="year",
                type_="INTEGER",
                mode="REQUIRED",
                description="Data Ingestion Year",
            )
        )

        columns.append(
            datacatalog_v1.types.ColumnSchema(
                column="sex", type_="STRING", mode="REQUIRED", description="Sex Type"
            )
        )

        columns.append(
            datacatalog_v1.types.ColumnSchema(
                column="university_type",
                type_="STRING",
                mode="REQUIRED",
                description="University Type",
            )
        )

        columns.append(
            datacatalog_v1.types.ColumnSchema(
                column="range",
                type_="STRING",
                mode="REQUIRED",
                description="Income Range",
            )
        )

        columns.append(
            datacatalog_v1.types.ColumnSchema(
                column="rate",
                type_="DOUBLE",
                mode="REQUIRED",
                description="Income Range Rate at specfic Sex and University type",
            )
        )

        entry.schema.columns.extend(columns)

        entry = datacatalog.create_entry(
            parent=entry_group.name,
            entry_id=entry_id,
            entry=entry,
        )

    tags = list(datacatalog.list_tags(parent=entry.name))
    if len(tags) != 0:
        tag = tags[0]
    else:
        tag = datacatalog_v1.types.Tag()
        tag.template = tag_template.name
        tag.fields["data_sources"] = datacatalog_v1.types.TagField()
        tag.fields[
            "data_sources"
        ].string_value = (
            "gs://jasso-gakuseiseikatsu-stats-annual-income-divide-university"
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

    df = pd.read_excel(content, sheet_name=8)
    data = []
    row_num = {
        "男": {
            "国立": 4,
            "公立": 5,
            "私立": 6,
        },
        "女": {
            "国立": 7,
            "公立": 8,
            "私立": 9,
        },
        "平均": {
            "国立": 11,
            "公立": 13,
            "私立": 15,
            "平均": 17,
        },
    }
    df.iloc[2] = df.iloc[2].str.replace("\s", "", regex=True)
    for s in ["男", "女", "平均"]:
        for g in ["国立", "公立", "私立", "平均"]:
            if g not in row_num[s]:
                continue
            ic = row_num[s][g]
            for i in range(3, 18):
                k = df.iloc[2, i]
                data.append((s, g, k, df.iloc[ic, i]))

    bucket_name = "jasso-gakuseiseikatsu-stats-annual-income-divide-university"

    bucket = storage_client.bucket(bucket_name)
    if not bucket.exists():
        bucket.create(location=region)
    raw_dir = bucket.blob("year=2018/data.parquet")

    res = pd.DataFrame(data, columns=["sex", "university_type", "range", "rate"])
    content = io.BytesIO()
    res.to_parquet(content)
    content.seek(0)
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

    client = bigquery.Client()
    dataset_id = "social_dataset"
    dataset_ref = bigquery.DatasetReference(project_id, dataset_id)

    table_id = "jasso_gakuseiseikatsu_stats_annual_income_divide_university"
    table = bigquery.Table(dataset_ref.table(table_id))

    external_config = bigquery.ExternalConfig("PARQUET")
    external_config.source_uris = [
        "gs://jasso-gakuseiseikatsu-stats-annual-income-divide-university/*"
    ]
    external_config.autodetect = True
    hive_partitioning = bigquery.external_config.HivePartitioningOptions()
    hive_partitioning.mode = "AUTO"
    hive_partitioning.require_partition_filter = False
    hive_partitioning.source_uri_prefix = (
        "gs://jasso-gakuseiseikatsu-stats-annual-income-divide-university"
    )
    external_config.hive_partitioning = hive_partitioning
    table.external_data_configuration = external_config

    table = client.create_table(table, exists_ok=True)

    return Response(status_code=200)
