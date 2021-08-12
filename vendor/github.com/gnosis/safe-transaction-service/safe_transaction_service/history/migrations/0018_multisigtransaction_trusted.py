# Generated by Django 3.0.6 on 2020-05-25 15:23

from django.db import migrations, models


def set_confirmed_txs_trusted(apps, schema_editor):
    MultisigTransaction = apps.get_model('history', 'MultisigTransaction')
    MultisigTransaction.objects.exclude(confirmations__isnull=True).update(trusted=True)


class Migration(migrations.Migration):

    dependencies = [
        ('history', '0017_safecontractdelegate'),
    ]

    operations = [
        migrations.AddField(
            model_name='multisigtransaction',
            name='trusted',
            field=models.BooleanField(db_index=True, default=False),
        ),
        migrations.RunPython(set_confirmed_txs_trusted, reverse_code=migrations.RunPython.noop),
    ]
