from django.db import models

# Create your models here.

# scaffold: usuario de auth personalizado, definido antes de la primera migración
from django.contrib.auth.models import AbstractUser  # noqa: E402


class User(AbstractUser):
    pass
