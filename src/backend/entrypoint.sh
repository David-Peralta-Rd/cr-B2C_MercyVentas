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
