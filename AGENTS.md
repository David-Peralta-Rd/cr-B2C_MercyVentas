# AGENTS.md — cr-B2C_MercyVentas

## Proyecto
Tienda de logistica para productos  y administracion de ganancias.


## Stack
- Python 3.14.8 (excepción: Django 6.1 no soporta 3.15 aún), uv (pyproject.toml y uv.lock generados por uv).
- Backend: Django 6.1 + django-ninja, PostgreSQL 18, gunicorn + whitenoise. Frontend: Streamlit, servicio aparte que habla con el backend por HTTP.
- Calidad: pytest + pytest-django, ruff, mypy.
- Docker: prod (docker-compose.yml + Dockerfile) y dev (docker-compose.dev.yml + Dockerfile.dev).

## Comandos
Atajo: `DEVX` = `cd src && docker compose -f docker-compose.dev.yml exec backend`
- Levantar prod: `cd src && docker compose up --build -d`
- Levantar dev: `cd src && docker compose -f docker-compose.dev.yml up --build` (uno a la vez, comparten puertos)
- Tests: `DEVX pytest` (frontend: `cd src/frontend && uv run pytest`)
- Lint: `cd src/backend && uv run ruff check .` (frontend igual en `src/frontend`)
- Tipos: `DEVX mypy .`
- Migraciones: `DEVX manage makemigrations <app>` y `DEVX manage migrate`
- Crear dominio: `cd src/backend && mkdir apps/x && uv run manage startapp x apps/x`, luego `name = "apps.x"` en apps.py
- Comandos de [project.scripts]: backend `manage`, `serve`; frontend `serve` (local: `uv run <comando>`)
- Reconstruir imágenes (tras uv add o cambio en scripts): `cd src && docker compose build && docker compose -f docker-compose.dev.yml build`
- Backup: `bash src/scripts/backup.sh`

## Estructura
Raíz: solo archivos de IA, README.md, .gitignore, .gitattributes, docs/ y scaffold.sh. Todo lo demás en `src/`: `backend/` (config/ y apps/{core,accounts,inventory,sales}, cada dominio con models, services, schemas, api y tests/), `frontend/` (mercy_front/ con app.py, api_client.py, pages/), docker-compose*.yml, .env.example, scripts/. La lógica de negocio vive en `services.py`, no en `api.py`.

## Nunca
- Nunca crear a mano lo que un generador produce (uv init, uv add, startproject, startapp, makemigrations).
- Nunca crear código, Dockerfiles, entrypoints, .dockerignore, .env ni scripts fuera de `src/`.
- Nunca usar CMD en un Dockerfile si el entrypoint.sh puede hacerlo.
- Nunca meter un comando largo en el entrypoint si cabe en [project.scripts].
- Nunca poner lógica de negocio en cli.py.
- Nunca editar un Dockerfile sin revisar su par Dockerfile.dev, ni un compose sin el otro.
- Nunca montar volúmenes de código en docker-compose.yml (solo en dev).
- Nunca pinear versiones de paquetes a mano ni usar pre-releases.
- Nunca tocar autenticación, secretos o migraciones destructivas sin que lo revise el dueño ([YO]).

## Cómo trabajas
1. Lee `SPEC.md` y `tasks.md`.
2. Trabaja UNA tarea marcada [DELEGAR]; propón un plan corto antes de escribir código.
3. Corre tests, linter y tipos.
4. Muestra el diff y explica qué cambió y por qué. No hagas commit sin revisión.
