Cómo agregar algo nuevo

Caso	Dónde	Comando generador	Qué registrar
Nuevo dominio	src/backend/apps/<x>/	cd src/backend && mkdir apps/x && uv run manage startapp x apps/x	name = "apps.x" en su apps.py, agregar a INSTALLED_APPS, touch services.py schemas.py api.py, mkdir tests, router en config/api.py
Nuevo modelo	apps/<x>/models.py	cd src/backend && uv run manage makemigrations x	Heredar de BaseModel, registrar en admin.py
Nueva ruta	apps/<x>/api.py	(sin generador)	Schemas en schemas.py, lógica en services.py, router en config/api.py
Nueva dependencia	pyproject.toml	cd src/backend && uv add <paquete> (dev: uv add --dev)	Regenera uv.lock; reconstruir imágenes prod y dev
Nueva variable de entorno	src/.env.example	(sin generador)	.env.example y ambos compose; leerla en settings
Nuevo comando	[project.scripts]	(sin generador)	Entrada en pyproject, función en cli.py, reconstruir prod y dev
Nueva página del frontend	mercy_front/pages/<x>.py	(sin generador)	Registrarla en st.navigation de app.py, llamar al backend solo vía api_client.py
