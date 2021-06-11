import datetime
from google.cloud import datacatalog_v1


class Client:
    def __init__(self, project_id: str, region: str) -> None:
        self.client = datacatalog_v1.DataCatalogClient()
        self.project_id = project_id
        self.region = region

    def get_entry_group(self, entry_group_id: str) -> datacatalog_v1.EntryGroup:
        return self.client.get_entry_group(
            name=self.client.entry_group_path(
                self.project_id, self.region, entry_group_id
            )
        )

    def get_tag_template(self, tag_template_id: str) -> datacatalog_v1.TagTemplate:
        return self.client.get_tag_template(
            name=self.client.tag_template_path(
                self.project_id, self.region, tag_template_id
            )
        )

    def get_entry(
        self, entry_group: datacatalog_v1.EntryGroup, entry_id: str
    ) -> datacatalog_v1.Entry:
        entries = self.client.list_entries(parent=entry_group.name)
        name = f"{entry_group.name}/entries/{entry_id}"
        entry = None
        for e in entries:
            if e.name == name:
                entry = e
                break
        return entry

    def get_tag(self, entry: datacatalog_v1.Entry) -> datacatalog_v1.Tag:
        tags = self.client.list_tags(parent=entry.name)
        tag = None
        for t in tags:
            tag = t
            break
        return tag

    def create_entry(
        self,
        entry_group: datacatalog_v1.EntryGroup,
        entry_id: str,
        entry: datacatalog_v1.Entry,
    ) -> datacatalog_v1.Entry:
        return self.client.create_entry(
            parent=entry_group.name, entry_id=entry_id, entry=entry
        )

    def create_tag(
        self, entry: datacatalog_v1.Entry, tag: datacatalog_v1.Tag
    ) -> datacatalog_v1.Tag:
        return self.client.create_tag(parent=entry.name, tag=tag)

    def set_status_running(self, tag: datacatalog_v1.Tag) -> datacatalog_v1.Tag:
        tag.fields["latest_job_status"] = datacatalog_v1.types.TagField()
        tag.fields[
            "latest_job_status"
        ].enum_value = datacatalog_v1.types.TagField.EnumValue()
        tag.fields["latest_job_status"].enum_value.display_name = "running"
        tag.fields["latest_job_start_datetime"] = datacatalog_v1.types.TagField()
        tag.fields[
            "latest_job_start_datetime"
        ].timestamp_value = datetime.datetime.now()
        return self.client.update_tag(tag=tag)

    def set_status_completed(self, tag: datacatalog_v1.Tag) -> datacatalog_v1.Tag:
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
        return self.client.update_tag(tag=tag)
