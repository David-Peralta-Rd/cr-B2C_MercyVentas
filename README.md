# cr-B2C_MercyVentas

Tienda de logistica para productos  y administracion de ganancias.

# Estructura de carpetas:
```text
(raíz del repo)
├── AGENTS.md · CLAUDE.md · SPEC.md · tasks.md · README.md   # archivos de IA y docs
├── .gitignore · .gitattributes                               # ignorados y finales de línea LF
├── scaffold.sh                                               # crea todo lo de src/
├── docs/DATA_MODEL.md · docs/adr/                            # modelo de datos y decisiones
└── src/
    ├── docker-compose.yml                                    # producción (sin volúmenes de código)
    ├── docker-compose.dev.yml                                # desarrollo (bind mounts, recarga)
    ├── .env.example                                          # plantilla; .env local sin versionar
    ├── scripts/backup.sh                                     # pg_dump a carpeta sincronizada con Drive
    ├── backend/
    │   ├── pyproject.toml · uv.lock · .python-version        # generados por uv
    │   ├── Dockerfile · Dockerfile.dev                       # prod multi-stage .whl / dev en vivo
    │   ├── entrypoint.sh · .dockerignore                     # arranque real y exclusiones de build
    │   ├── manage.py                                         # generado por startproject (intacto)
    │   ├── config/                                           # settings, urls, wsgi, asgi (generados)
    │   ├── config/cli.py                                     # comandos manage y serve
    │   ├── config/api.py                                     # NinjaAPI y routers (a mano, tarea T06)
    │   └── apps/
    │       ├── core/models.py                                # BaseModel abstracto (columnas base)
    │       ├── accounts/                                     # startapp + services.py schemas.py api.py tests/
    │       ├── inventory/                                    # idem: Product, Purchase, PurchaseItem
    │       └── sales/                                        # idem: Customer, Sale, SaleItem, Shipment
    └── frontend/
        ├── pyproject.toml · uv.lock · .python-version        # generados por uv
        ├── Dockerfile · Dockerfile.dev                       # mismo patrón que backend
        ├── entrypoint.sh · .dockerignore                     # solo `exec serve`
        ├── mercy_front/cli.py                                # comando serve (Streamlit)
        ├── mercy_front/app.py                                # login y navegación
        ├── mercy_front/api_client.py                         # único lugar que habla HTTP con el backend
        ├── mercy_front/pages/                                # products, purchases, sales, shipments, dashboard
        └── tests/                                            # pruebas del api_client
```

## Cómo correrlo

```bash
docker compose up
```
