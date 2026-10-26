from django.db import models
from django.db.models.functions import Now


# Create your models here.
class BaseModel(models.Model):
    id = models.BigAutoField(primary_key=True, verbose_name="ID")
    created_at = models.TimeField(
        null=False, db_default=Now(), verbose_name="Fecha de Creación"
    )
    updated_at = models.TimeField(
        null=False, auto_now=True, verbose_name="Fecha de Actualización"
    )
