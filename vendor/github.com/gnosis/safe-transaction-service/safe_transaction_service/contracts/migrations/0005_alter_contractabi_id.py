# Generated by Django 3.2.4 on 2021-06-07 10:07

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('contracts', '0004_auto_20210125_0925'),
    ]

    operations = [
        migrations.AlterField(
            model_name='contractabi',
            name='id',
            field=models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID'),
        ),
    ]
