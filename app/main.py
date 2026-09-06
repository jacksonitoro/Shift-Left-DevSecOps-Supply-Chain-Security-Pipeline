import os
from fastapi import FastAPI

app = FastAPI(
    title="Secure Microservice API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url=None
)

@app.get("/healthz", status_code=200)
def health_check():
    return {
        "status": "healthy",
        "environment": os.getenv("APP_ENV", "production")
    }

@app.get("/api/v1/data", status_code=200)
def read_data():
    return {
        "message": "Secure payload served from a distroless container runtime.",
        "compliance": "SLSA Level 2 Compatible"
    }