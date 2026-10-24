#!/usr/bin/env bash
set -euo pipefail

# --- Versiones (verificadas 2026-10-20; «verificar» = confirmar a mano) ---
PY_VERSION="3.14.8"                        # 3.15.0 existe, pero Django 6.1 soporta hasta 3.14
UV_IMAGE="ghcr.io/astral-sh/uv:0.12.1"     # «verificar» última 0.12.x
PG_IMAGE="postgres:18"                     # «verificar» tag

[ -f AGENTS.md ] || { echo "Ejecuta desde la raíz del proyecto (con git y plantillas)."; exit 1; }

# --- Helpers ---
append_block() { grep -qF "$2" "$1" || { printf '\n' >> "$1"; cat >> "$1"; }; }
add_script() {
  grep -qE "^$2 *=" "$1" && return 0
  if grep -q '^\[project.scripts\]' "$1"; then
    sed -i "/^\[project.scripts\]/a $2 = \"$3\"" "$1"
  else
    printf '\n[project.scripts] # scaffold\n%s = "%s"\n' "$2" "$3" >> "$1"
  fi
}
render() { sed -e "s|__PY__|$PY_VERSION|g" -e "s|__UV__|$UV_IMAGE|g" -e "s|__PORT__|$2|g" -e "s|__ENV__|$3|g" > "$1"; }

docker_files() {   # $1 = puerto, $2 = ENV extra del servicio
  [ -e Dockerfile ] || render Dockerfile "$1" "$2" <<'EOF'
# syntax=docker/dockerfile:1
ARG PY=__PY__
FROM __UV__ AS uv
FROM python:${PY}-slim AS build
ENV UV_PYTHON_DOWNLOADS=never
COPY --from=uv /uv /bin/uv
WORKDIR /src
COPY . .
RUN mkdir /dist \
 && uv export --frozen --no-dev --no-emit-project --no-hashes -o /dist/requirements.txt \
 && uv build --wheel --out-dir /dist

FROM python:${PY}-slim
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 APP_ENV=prod __ENV__
RUN useradd --create-home --uid 1000 app
WORKDIR /app
COPY --from=build /dist /dist
RUN --mount=from=uv,source=/uv,target=/bin/uv \
    uv pip install --system --no-cache -r /dist/requirements.txt /dist/*.whl
COPY --chmod=755 entrypoint.sh ./
RUN chown app:app /app
USER app
EXPOSE __PORT__
ENTRYPOINT ["./entrypoint.sh"]
EOF
  [ -e Dockerfile.dev ] || render Dockerfile.dev "$1" "$2" <<'EOF'
# syntax=docker/dockerfile:1
ARG PY=__PY__
FROM __UV__ AS uv
FROM python:${PY}-slim
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 APP_ENV=dev __ENV__ \
    UV_PROJECT_ENVIRONMENT=/opt/venv UV_PYTHON_DOWNLOADS=never PATH="/opt/venv/bin:$PATH"
COPY --from=uv /uv /bin/uv
RUN useradd --create-home --uid 1000 app && mkdir /opt/venv /app \
 && chown app:app /opt/venv /app
WORKDIR /app
USER app
COPY --chown=app:app pyproject.toml uv.lock .python-version ./
RUN uv sync --frozen --no-install-project
COPY --chown=app:app . .
RUN uv sync --frozen
EXPOSE __PORT__
ENTRYPOINT ["./entrypoint.sh"]
EOF
  [ -e .dockerignore ] || cat > .dockerignore <<'EOF'
.venv
__pycache__
*.pyc
.git
.env*
.pytest_cache
.ruff_cache
.mypy_cache
dist
build
*.egg-info
staticfiles
Dockerfile*
docker-compose*
.dockerignore
tests/
*.md
EOF
}

# --- Raíz: .gitignore y .gitattributes ---
[ -e .gitignore ] || cat > .gitignore <<'EOF'
.env
.venv/
__pycache__/
*.pyc
.pytest_cache/
.ruff_cache/
.mypy_cache/
dist/
staticfiles/
src/backups/
EOF
[ -e .gitattributes ] || printf '*.sh text eol=lf\n' > .gitattributes

mkdir -p src && cd src
SRC="$(pwd)"
mkdir -p backend frontend scripts

# ============================ BACKEND ============================
cd "$SRC/backend"
export SECRET_KEY="scaffold-temporal" DEBUG="true"    # solo para los generadores
[ -e pyproject.toml ] || uv init --bare --package --build-backend hatch --name mercy-backend
grep -q '^\[build-system\]' pyproject.toml || { echo "uv init no generó [build-system]"; exit 1; }
uv python pin "$PY_VERSION"
append_block pyproject.toml '[tool.hatch.build.targets.wheel]' <<'EOF'
[tool.hatch.build.targets.wheel] # scaffold
packages = ["config", "apps"]

[tool.uv] # scaffold
prerelease = "disallow"

[tool.pytest.ini_options] # scaffold
DJANGO_SETTINGS_MODULE = "config.settings"
python_files = ["tests/test_*.py"]

[tool.mypy] # scaffold
ignore_missing_imports = true
EOF
add_script pyproject.toml manage "config.cli:manage"
add_script pyproject.toml serve "config.cli:serve"
uv add --no-sync django django-ninja "psycopg[binary]" gunicorn whitenoise
uv add --no-sync --dev pytest pytest-django ruff mypy
uv lock
uv sync --no-install-project
[ -e manage.py ] || uv run --no-sync django-admin startproject config .
mkdir -p apps && touch apps/__init__.py
[ -e config/cli.py ] || cat > config/cli.py <<'EOF'
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
EOF
uv sync
for app in core accounts inventory sales; do
  if [ ! -d "apps/$app" ]; then
    mkdir "apps/$app" && uv run manage startapp "$app" "apps/$app"
  fi
  grep -q "name = \"apps\.$app\"" "apps/$app/apps.py" || \
    sed -i -E "s/name = ['\"]$app['\"]/name = \"apps.$app\"/" "apps/$app/apps.py"
done
for app in accounts inventory sales; do
  rm -f "apps/$app/tests.py"
  mkdir -p "apps/$app/tests" && touch "apps/$app/tests/__init__.py"
  for f in services schemas api; do [ -e "apps/$app/$f.py" ] || touch "apps/$app/$f.py"; done
done
append_block config/settings.py '# scaffold: entorno' <<'EOF'
# scaffold: entorno
import os  # noqa: E402

SECRET_KEY = os.environ["SECRET_KEY"]
DEBUG = os.environ.get("DEBUG", "false") == "true"
ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "localhost").split(",")
INSTALLED_APPS += ["apps.core", "apps.accounts", "apps.inventory", "apps.sales"]
AUTH_USER_MODEL = "accounts.User"
MIDDLEWARE.insert(1, "whitenoise.middleware.WhiteNoiseMiddleware")
STATIC_ROOT = BASE_DIR / "staticfiles"
LANGUAGE_CODE, TIME_ZONE = "es-co", "America/Bogota"
DATABASES = {"default": {
    "ENGINE": "django.db.backends.postgresql",
    "NAME": os.environ.get("POSTGRES_DB", "mercyventas"),
    "USER": os.environ.get("POSTGRES_USER", "mercy"),
    "PASSWORD": os.environ.get("POSTGRES_PASSWORD", ""),
    "HOST": os.environ.get("POSTGRES_HOST", "localhost"),
    "PORT": os.environ.get("POSTGRES_PORT", "5432"),
}}
EOF
append_block config/urls.py '# scaffold: /health' <<'EOF'
# scaffold: /health
from django.http import JsonResponse  # noqa: E402
from django.urls import path  # noqa: E402

urlpatterns += [path("health", lambda request: JsonResponse({"status": "ok"}))]
EOF
# El modelo de usuario debe existir antes de la primera migración (la tarea T04 lo revisa)
append_block apps/accounts/models.py '# scaffold' <<'EOF'
# scaffold: usuario de auth personalizado, definido antes de la primera migración
from django.contrib.auth.models import AbstractUser  # noqa: E402


class User(AbstractUser):
    pass
EOF
uv run manage makemigrations accounts
[ -e entrypoint.sh ] || cat > entrypoint.sh <<'EOF'
#!/bin/sh
set -e
echo "==> Aplicando migraciones"
manage migrate --noinput
if [ "${APP_ENV:-prod}" != "dev" ]; then
  echo "==> Recolectando estáticos"
  manage collectstatic --noinput
fi
echo "==> Iniciando servidor"
exec serve
EOF
chmod +x entrypoint.sh
docker_files 8000 "DJANGO_SETTINGS_MODULE=config.settings"

# ============================ FRONTEND ============================
cd "$SRC/frontend"
[ -e pyproject.toml ] || uv init --bare --package --build-backend hatch --name mercy-frontend
grep -q '^\[build-system\]' pyproject.toml || { echo "uv init no generó [build-system]"; exit 1; }
uv python pin "$PY_VERSION"
append_block pyproject.toml '[tool.hatch.build.targets.wheel]' <<'EOF'
[tool.hatch.build.targets.wheel] # scaffold
packages = ["mercy_front"]

[tool.uv] # scaffold
prerelease = "disallow"

[tool.mypy] # scaffold
ignore_missing_imports = true
EOF
add_script pyproject.toml serve "mercy_front.cli:serve"
uv add --no-sync streamlit httpx
uv add --no-sync --dev pytest ruff mypy
uv lock
mkdir -p mercy_front/pages tests          # sin generador: mkdir/touch
touch mercy_front/__init__.py mercy_front/api_client.py tests/__init__.py
[ -e mercy_front/cli.py ] || cat > mercy_front/cli.py <<'EOF'
"""Arranque del frontend: solo arranca Streamlit, sin lógica de negocio."""
import os
from pathlib import Path


def serve() -> None:
    app = str(Path(__file__).parent / "app.py")
    args = ["streamlit", "run", app, "--server.address=0.0.0.0", "--server.port=8501",
            "--server.headless=true", "--browser.gatherUsageStats=false"]
    if os.environ.get("APP_ENV", "prod") == "dev":
        args.append("--server.runOnSave=true")
    os.execvp("streamlit", args)
EOF
[ -e mercy_front/app.py ] || cat > mercy_front/app.py <<'EOF'
import os

import httpx
import streamlit as st

BACKEND_URL = os.environ.get("BACKEND_URL", "http://backend:8000")

st.set_page_config(page_title="MercyVentas")
st.title("MercyVentas")
try:
    r = httpx.get(f"{BACKEND_URL}/health", timeout=3)
    st.success(f"Backend: {r.json()['status']}")
except httpx.HTTPError:
    st.error("El backend no responde")
EOF
uv sync
[ -e entrypoint.sh ] || cat > entrypoint.sh <<'EOF'
#!/bin/sh
set -e
echo "==> Iniciando frontend"
exec serve
EOF
chmod +x entrypoint.sh
docker_files 8501 ""

# ============================ COMPOSE Y ENTORNO ============================
cd "$SRC"
[ -e .env.example ] || cat > .env.example <<'EOF'
POSTGRES_DB=mercyventas
POSTGRES_USER=mercy
POSTGRES_PASSWORD=cambia-esto
POSTGRES_HOST=db
POSTGRES_PORT=5432
SECRET_KEY=cambia-esto
DEBUG=false
ALLOWED_HOSTS=localhost,127.0.0.1,backend
BACKEND_URL=http://backend:8000
APP_ENV=prod
EOF
if [ ! -e .env ]; then
  cp .env.example .env
  sed -i "s|^SECRET_KEY=.*|SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')|" .env
fi
[ -e docker-compose.yml ] || sed "s|__PG__|$PG_IMAGE|" > docker-compose.yml <<'EOF'
name: mercyventas
services:
  db:
    image: __PG__
    env_file: .env
    volumes: ["pgdata:/var/lib/postgresql"]   # ruta de PostgreSQL 18 «verificar»
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 5s
      retries: 10
    restart: unless-stopped
  backend:
    build: ./backend
    env_file: .env
    ports: ["127.0.0.1:8000:8000"]
    depends_on: {db: {condition: service_healthy}}
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request as u; u.urlopen('http://localhost:8000/health')"]
      interval: 10s
      retries: 10
      start_period: 20s
    restart: unless-stopped
  frontend:
    build: ./frontend
    env_file: .env
    ports: ["8501:8501"]
    depends_on: {backend: {condition: service_healthy}}
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request as u; u.urlopen('http://localhost:8501/_stcore/health')"]
      interval: 10s
      retries: 10
      start_period: 20s
    restart: unless-stopped
volumes:
  pgdata:
EOF
[ -e docker-compose.dev.yml ] || sed "s|__PG__|$PG_IMAGE|" > docker-compose.dev.yml <<'EOF'
name: mercyventas-dev
services:
  db:
    image: __PG__
    env_file: .env
    ports: ["5433:5432"]
    volumes: ["pgdata:/var/lib/postgresql"]   # ruta de PostgreSQL 18 «verificar»
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 5s
      retries: 10
    restart: unless-stopped
  backend:
    build: {context: ./backend, dockerfile: Dockerfile.dev}
    env_file: .env
    environment: {APP_ENV: dev, DEBUG: "true"}
    volumes: ["./backend:/app"]
    ports: ["127.0.0.1:8000:8000"]
    depends_on: {db: {condition: service_healthy}}
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request as u; u.urlopen('http://localhost:8000/health')"]
      interval: 10s
      retries: 10
      start_period: 20s
    restart: unless-stopped
  frontend:
    build: {context: ./frontend, dockerfile: Dockerfile.dev}
    env_file: .env
    environment: {APP_ENV: dev}
    volumes: ["./frontend:/app"]
    ports: ["8501:8501"]
    depends_on: {backend: {condition: service_healthy}}
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request as u; u.urlopen('http://localhost:8501/_stcore/health')"]
      interval: 10s
      retries: 10
      start_period: 20s
    restart: unless-stopped
volumes:
  pgdata:
EOF

cat <<'MSG'

Listo. No se hizo commit.
  Producción : cd src && docker compose up --build -d
  Desarrollo : cd src && docker compose -f docker-compose.dev.yml up --build
  (levanta UNO a la vez: comparten los puertos 8000 y 8501)
Verificar    : docker compose ps   (todo healthy)
               curl -fsS localhost:8000/health
               curl -fsS localhost:8501/_stcore/health
MSG
