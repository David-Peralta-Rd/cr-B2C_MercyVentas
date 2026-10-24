# syntax=docker/dockerfile:1
ARG PY=3.14.8
FROM ghcr.io/astral-sh/uv:0.12.1 AS uv
FROM python:${PY}-slim AS build
ENV UV_PYTHON_DOWNLOADS=never
COPY --from=uv /uv /bin/uv
WORKDIR /src
COPY . .
RUN mkdir /dist \
 && uv export --frozen --no-dev --no-emit-project --no-hashes -o /dist/requirements.txt \
 && uv build --wheel --out-dir /dist

FROM python:${PY}-slim
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 APP_ENV=prod 
RUN useradd --create-home --uid 1000 app
WORKDIR /app
COPY --from=build /dist /dist
RUN --mount=from=uv,source=/uv,target=/bin/uv \
    uv pip install --system --no-cache -r /dist/requirements.txt /dist/*.whl
COPY --chmod=755 entrypoint.sh ./
RUN chown app:app /app
USER app
EXPOSE 8501
ENTRYPOINT ["./entrypoint.sh"]
