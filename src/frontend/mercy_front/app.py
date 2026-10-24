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
