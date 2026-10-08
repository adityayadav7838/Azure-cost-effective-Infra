import os
import psycopg2
from fastapi import FastAPI
from fastapi.responses import JSONResponse, PlainTextResponse

app = FastAPI()

DATABASE_URL = os.getenv("DATABASE_URL", "")


def check_db() -> bool:
    """Attempt a lightweight PostgreSQL connection check. Returns True if healthy."""
    try:
        conn = psycopg2.connect(DATABASE_URL, connect_timeout=3)
        conn.close()
        return True
    except Exception:
        return False


@app.get("/", response_class=PlainTextResponse)
def root():
    # Requirement 7.2
    return "Hello from Azure Kubernetes"


@app.get("/health")
def health():
    # Requirements 7.3, 7.4, 7.5
    db_ok = check_db()
    return JSONResponse(
        status_code=200,
        content={
            "application": "healthy",
            "database": "connected" if db_ok else "disconnected",
        },
    )
