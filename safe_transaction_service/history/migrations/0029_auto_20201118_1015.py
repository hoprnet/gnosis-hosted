# Generated by Django 3.1.3 on 2020-11-18 10:15

import django.contrib.postgres.fields
from django.db import migrations, models

import gnosis.eth.django.models


class Migration(migrations.Migration):

    dependencies = [
        ('history', '0028_auto_20201112_1613'),
    ]

    operations = [
        migrations.AlterField(
            model_name='safestatus',
            name='owners',
            field=django.contrib.postgres.fields.ArrayField(base_field=gnosis.eth.django.models.EthereumAddressField(), db_index=True, size=None),
        ),
        migrations.AddIndex(
            model_name='safestatus',
            index=models.Index(fields=['address', '-nonce'], name='history_saf_address_aa71bd_idx'),
        ),
    ]
