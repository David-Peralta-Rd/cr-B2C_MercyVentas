# tasks.md — MercyVentas

Atajo: `DEVX` = `cd src && docker compose -f docker-compose.dev.yml exec backend`
Reglas: [YO] = lo escribo y estudio yo. [DELEGAR] = lo hace el agente y reviso cada diff.
Cada bloque deja algo que corre. Antes de empezar un bloque: `docker compose -f docker-compose.dev.yml up` arriba.

| Estado | ID | Tipo | Tarea | Archivos que toca | Verificación |
|---|---|---|---|---|---|
| COMPLETO | T01 | [YO] | Crear la raíz (git init + plantillas), correr `bash scaffold.sh`, levantar prod y luego dev; cambiar el título en `app.py` y ver el cambio en vivo en dev | scaffold.sh, src/** | `cd src && docker compose up --build -d && docker compose ps` (healthy); `curl -fsS localhost:8000/health`; `curl -fsS localhost:8501/_stcore/health`; repetir con `-f docker-compose.dev.yml` y comprobar el cambio |
| COMPLETO | T02 | [YO] | Revisar entrypoint.sh, cli.py, los 4 Dockerfile (multi-stage con .whl, sin CMD, uv fuera de la imagen final), que uv.lock no tenga pre-releases y el peso de la imagen final | src/backend/*, src/frontend/* | `grep '^version = ' src/backend/uv.lock` sin a/b/rc/dev; `docker image ls` |
| COMPLETO | T03 | [YO] | Escribir `BaseModel` abstracto (created_at, updated_at, con db_default) | src/backend/apps/core/models.py | `DEVX manage check` |
| COMPLETO | T04 | [YO] | Revisar el `User` (AbstractUser) y su migración generada; crear el primer admin con `DEVX manage createsuperuser` | src/backend/apps/accounts/models.py | Login en `localhost:8000/admin` |
| INCOMPLETO | T05 | [YO] | Auth: crear y verificar token firmado (`django.core.signing`, `check_password`) | src/backend/apps/accounts/services.py | Lo cubre T07 |
| INCOMPLETO | T06 | [YO] | Crear `NinjaAPI` en `/api/`, rutas `POST /api/auth/login` y `GET /api/auth/me` con `HttpBearer` | src/backend/config/api.py, config/urls.py, apps/accounts/api.py | `curl -s -X POST localhost:8000/api/auth/login -H 'Content-Type: application/json' -d '{"username":"u","password":"p"}'` devuelve token |
| INCOMPLETO | T07 | [DELEGAR] | Tests de auth: login correcto, credenciales malas, `/me` con y sin token | src/backend/apps/accounts/tests/test_auth.py | `DEVX pytest apps/accounts -q` |
| INCOMPLETO | T08 | [YO] | Modelo `Product` según DATA_MODEL y su migración: `DEVX manage makemigrations inventory` y `DEVX manage migrate` | src/backend/apps/inventory/models.py | `DEVX manage check` y tabla `inventory_product` creada |
| INCOMPLETO | T09 | [DELEGAR] | Registrar `Product` en el admin (list_display, search_fields) | src/backend/apps/inventory/admin.py | Se ve en `localhost:8000/admin` |
| INCOMPLETO | T10 | [DELEGAR] | Schemas `ProductIn` y `ProductOut` (ninja Schema) | src/backend/apps/inventory/schemas.py | `DEVX ruff check apps/inventory` |
| INCOMPLETO | T11 | [DELEGAR] | Funciones `list_products`, `create_product`, `update_product` (sin DELETE; se desactiva con `is_active`) | src/backend/apps/inventory/services.py | Lo cubre T13 |
| INCOMPLETO | T12 | [DELEGAR] | Router de productos (GET lista, POST, PATCH) protegido con `HttpBearer`, registrado en `config/api.py` | src/backend/apps/inventory/api.py, config/api.py | `curl` con token a `/api/products` |
| INCOMPLETO | T13 | [DELEGAR] | Tests de productos: crear, SKU duplicado rechazado, precio negativo rechazado | src/backend/apps/inventory/tests/test_products.py | `DEVX pytest apps/inventory -q` |
| INCOMPLETO | T14 | [DELEGAR] | Modelo `Purchase` copiando el patrón de `Product` (CHECK, UniqueConstraint parcial); `DEVX manage makemigrations inventory` | src/backend/apps/inventory/models.py | `DEVX manage migrate` sin errores |
| INCOMPLETO | T15 | [DELEGAR] | Modelo `PurchaseItem` (CHECKs, UniqueConstraint); `DEVX manage makemigrations inventory` | src/backend/apps/inventory/models.py | `DEVX manage migrate` sin errores |
| INCOMPLETO | T16 | [YO] | `receive_purchase(purchase_id)`: `transaction.atomic`, `select_for_undate`→`select_for_update`, sube stock con `F()`, actualiza `last_unit_cost`, rechaza doble recepción | src/backend/apps/inventory/services.py | Lo cubre T17 |
| INCOMPLETO | T17 | [DELEGAR] | Tests de `receive_purchase`: sube el stock, rechaza doble recepción, rechaza compra cancelada | src/backend/apps/inventory/tests/test_receive_purchase.py | `DEVX pytest apps/inventory/tests/test_receive_purchase.py -q` |
| INCOMPLETO | T18 | [DELEGAR] | Schemas de compras (`PurchaseIn` con ítems, `PurchaseOut`) | src/backend/apps/inventory/schemas.py | `DEVX ruff check apps/inventory` |
| INCOMPLETO | T19 | [DELEGAR] | Rutas de compras: listar, crear, `POST /api/purchases/{id}/receive` (llama a `receive_purchase`) | src/backend/apps/inventory/api.py | `curl` con token a `/api/purchases` |
| INCOMPLETO | T20 | [YO] | Modelo `Customer` y su migración: `DEVX manage makemigrations sales` | src/backend/apps/sales/models.py | `DEVX manage migrate` |
| INCOMPLETO | T21 | [DELEGAR] | Modelo `Sale` copiando el patrón; `DEVX manage makemigrations sales` | src/backend/apps/sales/models.py | `DEVX manage migrate` sin errores |
| INCOMPLETO | T22 | [DELEGAR] | Modelo `SaleItem` (copias de precio y costo); `DEVX manage makemigrations sales` | src/backend/apps/sales/models.py | `DEVX manage migrate` sin errores |
| INCOMPLETO | T23 | [DELEGAR] | Modelo `Shipment` (OneToOne con `Sale`); `DEVX manage makemigrations sales` | src/backend/apps/sales/models.py | `DEVX manage migrate` sin errores |
| INCOMPLETO | T24 | [YO] | `create_sale`: valida stock, copia `unit_price`/`unit_cost`, calcula `total`, descuenta stock, todo en una transacción | src/backend/apps/sales/services.py | Lo cubre T25 |
| INCOMPLETO | T25 | [DELEGAR] | Tests de `create_sale`: stock insuficiente rechaza sin cambios, copia de precios, total correcto | src/backend/apps/sales/tests/test_create_sale.py | `DEVX pytest apps/sales -q` |
| INCOMPLETO | T26 | [YO] | `cancel_sale`: cambia a `cancelled` y devuelve el stock, una sola vez | src/backend/apps/sales/services.py | `DEVX pytest apps/sales -q` (agregar caso en T25) |
| INCOMPLETO | T27 | [DELEGAR] | `update_shipment_status` y `create_shipment` (fechas shipped_at/delivered_at según estado) | src/backend/apps/sales/services.py | `DEVX pytest apps/sales -q` |
| INCOMPLETO | T28 | [DELEGAR] | Schemas de clientes, ventas y envíos | src/backend/apps/sales/schemas.py | `DEVX ruff check apps/sales` |
| INCOMPLETO | T29 | [DELEGAR] | Rutas: clientes (GET/POST), ventas (GET/POST/cancelar), envíos (POST/PATCH estado), registradas en `config/api.py` | src/backend/apps/sales/api.py, config/api.py | `curl` con token a `/api/sales` |
| INCOMPLETO | T30 | [DELEGAR] | `api_client.py`: `login`, `get`, `post`, `patch` con httpx y header `Authorization: Bearer` | src/frontend/mercy_front/api_client.py | `cd src/frontend && uv run pytest` con test de `login` con httpx mockeado |
| INCOMPLETO | T31 | [YO] | Login con `st.session_state` y navegación con `st.navigation` (decidir dónde vive el token) | src/frontend/mercy_front/app.py | Entrar con el admin en `localhost:8501` |
| INCOMPLETO | T32 | [DELEGAR] | Página de productos: tabla y formulario de alta | src/frontend/mercy_front/pages/products.py | Crear un producto desde la UI y verlo en la tabla |
| INCOMPLETO | T33 | [DELEGAR] | Página de compras: formulario con ítems y botón "Marcar recibida" | src/frontend/mercy_front/pages/purchases.py | Recibir una compra y ver subir el stock |
| INCOMPLETO | T34 | [DELEGAR] | Página de ventas: cliente, ítems, cancelar | src/frontend/mercy_front/pages/sales.py | Vender y ver bajar el stock |
| INCOMPLETO | T35 | [DELEGAR] | Página de envíos: lista por estado y cambio de estado | src/frontend/mercy_front/pages/shipments.py | Cambiar un envío a `delivered` |
| INCOMPLETO | T36 | [DELEGAR] | `monthly_summary()`: ventas y ganancia estimada del mes con `Sum` y `F()` | src/backend/apps/sales/services.py | `DEVX pytest apps/sales -q` |
| INCOMPLETO | T37 | [DELEGAR] | Ruta `GET /api/reports/summary` (ventas, ganancia, productos con stock bajo) | src/backend/apps/sales/api.py | `curl` con token |
| INCOMPLETO | T38 | [DELEGAR] | Página de panel con `st.metric` y tabla de stock bajo | src/frontend/mercy_front/pages/dashboard.py | Los números coinciden con las ventas cargadas |
| INCOMPLETO | T39 | [DELEGAR] | `backup.sh`: `docker compose exec -T db pg_dump` comprimido a `src/backups/` con fecha | src/scripts/backup.sh | `bash src/scripts/backup.sh` crea un `.sql.gz` |
| INCOMPLETO | T40 | [YO] | Poner el PC "servidor" en producción (`.env` real con `DEBUG=false`, clave y contraseña propias, IP fija en la red), probar desde un segundo dispositivo, restaurar un backup en dev | src/.env, src/docker-compose.yml | Criterios de TERMINADO 1 a 3 |
| INCOMPLETO
