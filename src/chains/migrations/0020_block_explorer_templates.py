# Generated by Django 3.2.5 on 2021-07-26 08:25
from django.db import migrations, models
from django.db.models import F


def copy_block_explorer_uri(apps, schema_editor):
    chain_model = apps.get_model("chains", "chain")
    db_alias = schema_editor.connection.alias
    chain_model.objects.using(db_alias).all().update(
        block_explorer_uri_address_template=F("block_explorer_uri"),
        block_explorer_uri_tx_hash_template=F("block_explorer_uri"),
    )


class Migration(migrations.Migration):
    dependencies = [
        ("chains", "0019_add_safe_apps_rpc"),
    ]

    operations = [
        migrations.AddField(
            model_name="chain",
            name="block_explorer_uri_address_template",
            field=models.URLField(default=""),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name="chain",
            name="block_explorer_uri_tx_hash_template",
            field=models.URLField(default=""),
            preserve_default=False,
        ),
        # Reverse means deleting the fields but this is accomplished via the reverse of AddField
        # so an empty lambda function is provided
        migrations.RunPython(copy_block_explorer_uri, lambda apps, schema_editor: None),
    ]
