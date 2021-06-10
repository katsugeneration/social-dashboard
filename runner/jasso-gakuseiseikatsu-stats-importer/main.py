from typing import Optional
import os
import requests
import io
import pandas as pd
from google.cloud import storage
from google.cloud import datacatalog_v1
from google.cloud import bigquery
from fastapi import FastAPI, Response

try:
    from .clients import data_catalog
except:  # noqa E722
    from ..clients import data_catalog

app = FastAPI(debug=False)


def load_stats_raw(
    storage_client: storage.Client,
    datacatalog: data_catalog.Client,
    region: str,
    entry_group: datacatalog_v1.EntryGroup,
    tag_template: datacatalog_v1.TagTemplate,
) -> Optional[io.BytesIO]:
    bucket_name = "jasso-gakuseiseikatsu-stats-raw"
    bucket = storage_client.bucket(bucket_name)
    if not bucket.exists():
        bucket.create(location=region)

    entry_id = "jasso_gakuseiseikatsu_stats_raw"
    entry = datacatalog.get_entry(entry_group, entry_id)
    if entry is None:
        entry = datacatalog_v1.types.Entry()
        entry.display_name = bucket_name
        entry.gcs_fileset_spec.file_patterns.append(f"gs://{bucket_name}/*.xlsx")
        entry.type_ = datacatalog_v1.EntryType.FILESET
        entry = datacatalog.create_entry(entry_group, entry_id, entry)

    tag = datacatalog.get_tag(entry)
    if tag is None:
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
    tag = datacatalog.set_status_running(tag)

    raw_dir = bucket.blob("data18_2.xlsx")
    res = requests.get(
        "https://www.jasso.go.jp/about/statistics/gakusei_chosa/__icsFiles/afieldfile/2020/03/16/data18_2.xlsx"
    )
    content = None
    if res.status_code == 200:
        content = io.BytesIO(res.content)
    res.close()
    raw_dir.upload_from_file(content)
    tag = datacatalog.set_status_completed(tag)

    return content


def load_income_stats(
    storage_client: storage.Client,
    datacatalog: data_catalog.Client,
    region: str,
    entry_group: datacatalog_v1.EntryGroup,
    tag_template: datacatalog_v1.TagTemplate,
    content: Optional[io.BytesIO],
) -> pd.DataFrame:

    bucket_name = "jasso-gakuseiseikatsu-stats-annual-income-divide-university"

    entry_id = "jasso_gakuseiseikatsu_stats_annual_income_divide_university"
    entry = datacatalog.get_entry(entry_group, entry_id)
    if entry is None:
        entry = datacatalog_v1.types.Entry()
        entry.display_name = bucket_name
        entry.gcs_fileset_spec.file_patterns.append(f"gs://{bucket_name}/*.parquet")
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
        entry = datacatalog.create_entry(entry_group, entry_id, entry)

    tag = datacatalog.get_tag(entry)
    if tag is None:
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
    tag = datacatalog.set_status_running(tag)

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

    bucket = storage_client.bucket(bucket_name)
    if not bucket.exists():
        bucket.create(location=region)
    raw_dir = bucket.blob("year=2018/data.parquet")

    res = pd.DataFrame(data, columns=["sex", "university_type", "range", "rate"])
    content = io.BytesIO()
    res.to_parquet(content)
    content.seek(0)
    raw_dir.upload_from_file(content)
    tag = datacatalog.set_status_completed(tag)


def create_external_table(project_id: str) -> None:
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


@app.post("/")
def handler():
    storage_client = storage.Client()

    # The name for the new bucket
    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT")
    region = os.environ.get("GCLOUD_REGION")

    datacatalog = data_catalog.Client(project_id, region)
    entry_group_id = "social_data"
    tag_template_id = "data_ingestion"
    entry_group = datacatalog.get_entry_group(entry_group_id)
    tag_template = datacatalog.get_tag_template(tag_template_id)

    content = load_stats_raw(
        storage_client,
        datacatalog,
        region,
        entry_group,
        tag_template,
    )

    load_income_stats(
        storage_client,
        datacatalog,
        region,
        entry_group,
        tag_template,
        content,
    )

    create_external_table(project_id)

    return Response(status_code=200)
