from typing import Optional
import os
import requests
import io
import json
import pandas as pd
from google.cloud import storage
from google.cloud import datacatalog_v1
from google.cloud import bigquery
from google.cloud import secretmanager
from fastapi import FastAPI, Response

try:
    from clients import data_catalog
except:  # noqa E722
    from ..clients import data_catalog

app = FastAPI(debug=False)


def load_stats_raw(
    storage_client: storage.Client,
    datacatalog: data_catalog.Client,
    region: str,
    entry_group: datacatalog_v1.EntryGroup,
    tag_template: datacatalog_v1.TagTemplate,
    app_id: str,
) -> Optional[io.BytesIO]:
    bucket_name = "ja-kakei-chousa-raw"
    bucket = storage_client.bucket(bucket_name)
    if not bucket.exists():
        bucket.create(location=region)

    entry_id = "ja_kakei_chousa_raw"
    entry = datacatalog.get_entry(entry_group, entry_id)
    if entry is None:
        entry = datacatalog_v1.types.Entry()
        entry.display_name = bucket_name
        entry.gcs_fileset_spec.file_patterns.append(f"gs://{bucket_name}/*.json")
        entry.type_ = datacatalog_v1.EntryType.FILESET
        entry = datacatalog.create_entry(entry_group, entry_id, entry)

    tag = datacatalog.get_tag(entry)
    if tag is None:
        tag = datacatalog_v1.types.Tag()
        tag.template = tag_template.name
        tag.fields["data_sources"] = datacatalog_v1.types.TagField()
        tag.fields[
            "data_sources"
        ].string_value = "家計調査 https://www.e-stat.go.jp/stat-search/database?page=1&layout=datalist&toukei=00200561&tstat=000000330001&cycle=7&tclass1=000000330001&tclass2=000000330004&tclass3val=0"
        tag.fields["license"] = datacatalog_v1.types.TagField()
        tag.fields[
            "license"
        ].string_value = "利用規約に従って複製、公衆送信、翻訳・変形等の翻案等、自由に利用できます。商用利用も可能です。 https://www.e-stat.go.jp/terms-of-use"
        tag = datacatalog.create_tag(entry, tag=tag)
    tag = datacatalog.set_status_running(tag)

    raw_dir = bucket.blob("income-divide-over-two-member-2020.json")
    res = requests.get(
        "http://api.e-stat.go.jp/rest/3.0/app/json/getStatsData?appId=%s&lang=J&statsDataId=0002070005&metaGetFlg=Y&cntGetFlg=N&explanationGetFlg=Y&annotationGetFlg=Y&sectionHeaderFlg=1"
        % app_id
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
    bucket_name = "ja-kakei-chousa-income-divide-over-two-member"
    bucket = storage_client.bucket(bucket_name)
    if not bucket.exists():
        bucket.create(location=region)

    entry_id = "ja_kakei_chousa_income_divide_over_two_member"
    entry = datacatalog.get_entry(entry_group, entry_id)
    if entry is None:
        entry = datacatalog_v1.types.Entry()
        entry.display_name = bucket_name
        entry.gcs_fileset_spec.file_patterns.append(f"gs://{bucket_name}/*.parquet")
        entry.type_ = datacatalog_v1.EntryType.FILESET

        columns = []
        columns.append(
            datacatalog_v1.types.ColumnSchema(
                column="aggregatioon_category",
                type_="STRING",
                mode="REQUIRED",
                description="集計カテゴリ",
            )
        )

        columns.append(
            datacatalog_v1.types.ColumnSchema(
                column="houseshold_type",
                type_="STRING",
                mode="REQUIRED",
                description="世帯種別",
            )
        )

        columns.append(
            datacatalog_v1.types.ColumnSchema(
                column="quintile",
                type_="STRING",
                mode="REQUIRED",
                description="年間収入5分位の位置およびすべての世帯の平均のいずれか",
            )
        )

        columns.append(
            datacatalog_v1.types.ColumnSchema(
                column="value", type_="DOUBLE", mode="REQUIRED", description="各集計値"
            )
        )

        entry.schema.columns.extend(columns)
        entry = datacatalog.create_entry(entry_group, entry_id, entry)

    tag = datacatalog.get_tag(entry)
    if tag is None:
        tag = datacatalog_v1.types.Tag()
        tag.template = tag_template.name
        tag.fields["data_sources"] = datacatalog_v1.types.TagField()
        tag.fields["data_sources"].string_value = "gs://ja-kakei-chousa-raw/"
        tag.fields["license"] = datacatalog_v1.types.TagField()
        tag.fields[
            "license"
        ].string_value = "利用規約に従って複製、公衆送信、翻訳・変形等の翻案等、自由に利用できます。商用利用も可能です。 https://www.e-stat.go.jp/terms-of-use"
        tag = datacatalog.create_tag(entry, tag=tag)
    tag = datacatalog.set_status_running(tag)

    raw = json.load(content)
    classes = {}
    class_names = {}
    for c in raw["GET_STATS_DATA"]["STATISTICAL_DATA"]["CLASS_INF"]["CLASS_OBJ"]:
        if c["@id"] in ["tab", "area"]:
            continue
        classes[c["@id"]] = {}
        if c["@id"] == "cat01":
            class_names[c["@id"]] = "aggregation_type"
        if c["@id"] == "cat02":
            class_names[c["@id"]] = "houseshold_type"
        if c["@id"] == "cat03":
            class_names[c["@id"]] = "quintile"
        if c["@id"] == "time":
            class_names[c["@id"]] = "year"
        if not isinstance(c["CLASS"], list):
            code = c["CLASS"]
            classes[c["@id"]][code["@code"]] = code["@name"]
        else:
            for code in c["CLASS"]:
                classes[c["@id"]][code["@code"]] = code["@name"]
                if c["@id"] == "time":
                    classes[c["@id"]][code["@code"]] = int(
                        classes[c["@id"]][code["@code"]].rstrip("年")
                    )

    def to_num(s: str) -> float:
        if s.isdecimal():
            return float(s)
        return float("nan")

    data = []

    for v in raw["GET_STATS_DATA"]["STATISTICAL_DATA"]["DATA_INF"]["VALUE"]:
        val = []
        for c, codes in classes.items():
            if "@" + c in v:
                val.append(codes[v["@" + c]])
        val.append(to_num(v["$"]))
        data.append(val)
    columns = list(map(lambda k: class_names[k], classes.keys()))
    columns.append("value")
    df = pd.DataFrame(data, columns=columns)

    content = io.BytesIO()
    df.to_parquet(content)
    content.seek(0)
    raw_dir = bucket.blob("acquisition_year=2020/data.parquet")
    raw_dir.upload_from_file(content)
    tag = datacatalog.set_status_completed(tag)
    return df


def create_external_table(project_id: str) -> None:
    client = bigquery.Client()
    dataset_id = "social_dataset"
    dataset_ref = bigquery.DatasetReference(project_id, dataset_id)

    table_id = "ja_kakei_chousa_income_divide_over_two_member"
    table = bigquery.Table(dataset_ref.table(table_id))

    external_config = bigquery.ExternalConfig("PARQUET")
    external_config.source_uris = [
        "gs://ja-kakei-chousa-income-divide-over-two-member/*"
    ]
    external_config.autodetect = True
    hive_partitioning = bigquery.external_config.HivePartitioningOptions()
    hive_partitioning.mode = "AUTO"
    hive_partitioning.require_partition_filter = False
    hive_partitioning.source_uri_prefix = (
        "gs://ja-kakei-chousa-income-divide-over-two-member"
    )
    external_config.hive_partitioning = hive_partitioning
    table.external_data_configuration = external_config

    table = client.create_table(table, exists_ok=True)


@app.post("/")
def handler():
    storage_client = storage.Client()
    secret_manager = secretmanager.SecretManagerServiceClient()

    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT")
    region = os.environ.get("GCLOUD_REGION")
    app_id = secret_manager.access_secret_version(
        name=f"projects/{project_id}/secrets/e-stat-app-id/versions/latest"
    ).payload.data.decode("utf-8")

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
        app_id,
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
