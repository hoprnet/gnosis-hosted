# Generated by Django 3.1.3 on 2020-11-12 15:47

from django.db import migrations
from django.db.migrations import RunPython
from django.db.models.expressions import F, OuterRef, RawSQL, Subquery


def delete_errored_internal_txs(apps, schema_editor):
    """
    Previously all traces were stored, even the errored ones. This method will delete old errored traces still present
    on the database
    :param apps:
    :param schema_editor:
    :return:
    """
    InternalTx = apps.get_model('history', 'InternalTx')

    parent_errored_query = InternalTx.objects.annotate(
        child_trace_address=RawSQL('"history_internaltx"."trace_address"', tuple())
        #  Django bug, so we use RawSQL instead of: child_trace_address=OuterRef('trace_address')
    ).filter(
        child_trace_address__startswith=F('trace_address'),
        ethereum_tx=OuterRef('ethereum_tx'),
    ).exclude(
        error=None
    )

    InternalTx.objects.annotate(
        parent_errored=Subquery(parent_errored_query.values('pk')[:1])
    ).exclude(
        parent_errored=None,
    ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('history', '0026_auto_20201030_1355'),
    ]

    operations = [
        RunPython(delete_errored_internal_txs, reverse_code=migrations.RunPython.noop)
    ]
