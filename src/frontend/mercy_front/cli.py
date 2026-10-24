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
