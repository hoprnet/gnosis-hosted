# Generated by Django 3.2.3 on 2021-06-02 14:44

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="Chain",
            fields=[
                (
                    "id",
                    models.PositiveBigIntegerField(
                        primary_key=True, serialize=False, verbose_name="Chain Id"
                    ),
                ),
                ("name", models.CharField(max_length=255, verbose_name="Chain name")),
                ("rpc_url", models.URLField()),
                ("block_explorer_url", models.URLField(null=True)),
                ("currency_name", models.CharField(max_length=255, null=True)),
                ("currency_symbol", models.CharField(max_length=255)),
                ("currency_decimals", models.IntegerField(default=18)),
            ],
        ),
    ]
