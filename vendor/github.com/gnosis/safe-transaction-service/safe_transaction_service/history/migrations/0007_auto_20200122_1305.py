# Generated by Django 3.0.2 on 2020-01-22 13:05

from django.db import migrations, models

import gnosis.eth.django.models


class Migration(migrations.Migration):

    dependencies = [
        ('history', '0006_auto_20200113_1204'),
    ]

    operations = [
        migrations.AlterField(
            model_name='safestatus',
            name='address',
            field=gnosis.eth.django.models.EthereumAddressField(db_index=True),
        ),
        migrations.CreateModel(
            name='WebHook',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('address', gnosis.eth.django.models.EthereumAddressField(db_index=True)),
                ('url', models.URLField()),
                ('new_confirmation', models.BooleanField(default=True)),
                ('pending_outgoing_transaction', models.BooleanField(default=True)),
                ('new_executed_outgoing_transaction', models.BooleanField(default=True)),
                ('new_incoming_transaction', models.BooleanField(default=True)),
            ],
            options={
                'unique_together': {('address', 'url')},
            },
        ),
    ]
