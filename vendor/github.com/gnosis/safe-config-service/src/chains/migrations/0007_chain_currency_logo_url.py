# Generated by Django 3.2.5 on 2021-07-07 08:46

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("chains", "0006_change_color_default_help_text"),
    ]

    operations = [
        migrations.AddField(
            model_name="chain",
            name="currency_logo_url",
            field=models.URLField(
                default="https://cryptologos.cc/logos/ethereum-eth-logo.png"
            ),
            preserve_default=False,
        ),
    ]
