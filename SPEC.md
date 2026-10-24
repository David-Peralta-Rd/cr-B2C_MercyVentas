# SPEC — MercyVentas

## Problema
La familia compra por mayor (Temu, Shein, otros) y revende. Hoy no hay control de qué se compró, qué hay en stock, a quién se vendió ni qué se envió. Los admins (no técnicos) están en distintos PCs y necesitan ver los mismos datos.

## Usuarios
2-3 admins de la familia, no técnicos. Entran con usuario y contraseña desde el navegador.

## Dentro de alcance (v1)
- Login de admins.
- Productos (nombre, SKU, precio de venta, stock).
- Compras con ítems; al marcarlas "recibida" suben el stock.
- Clientes, ventas con ítems (precio y costo copiados al vender), cancelación de ventas.
- Envíos por venta (transportadora, guía, estado).
- Panel: ventas y ganancia estimada del mes, productos con stock bajo.
- Backup de la BD a una carpeta sincronizada con Drive.

## Fuera de alcance
Pagos en línea, tienda pública para clientes, multi-moneda, roles y permisos, tabla de proveedores, historial de movimientos de stock, app móvil, notificaciones, reportes avanzados.

## Criterios de aceptación
1. Recibir una compra de N unidades sube el stock exactamente N; recibirla dos veces se rechaza.
2. Una venta con stock insuficiente se rechaza y no cambia nada.
3. El precio y costo de una venta no cambian si luego cambia el producto.
4. Cancelar una venta devuelve su stock.
5. Dos dispositivos ven los mismos datos.
6. Sin sesión válida, ninguna ruta de `/api/` (salvo login) responde datos.
7. `scripts/backup.sh` genera un `.sql.gz` que se restaura en la BD de desarrollo.
8. `docker compose up` (prod) y `-f docker-compose.dev.yml` (dev) levantan sanos.
