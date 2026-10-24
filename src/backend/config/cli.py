"""Arranque del backend: solo arranca cosas, sin lógica de negocio."""
import os
import sys


def manage() -> None:
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
    from django.core.management import execute_from_command_line

    execute_from_command_line(sys.argv)


def serve() -> None:
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
    if os.environ.get("APP_ENV", "prod") == "dev":
        os.execvp("manage", ["manage", "runserver", "0.0.0.0:8000"])
    cmd = ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]
    os.execvp("gunicorn", cmd + ["--workers", "2"])
