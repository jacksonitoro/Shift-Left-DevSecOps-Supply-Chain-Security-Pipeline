# ==========================================
# Stage 1: Build Environment (Debian Bookworm)
# ==========================================
FROM python:3.11-slim-bookworm AS builder

WORKDIR /build

COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ==========================================
# Stage 2: Distroless Runtime (Zero Shell)
# ==========================================
FROM gcr.io/distroless/python3-debian12:nonroot

WORKDIR /app

# Copy installed dependencies and application code
COPY --from=builder /install /usr/local
COPY --chown=nonroot:nonroot ./app /app

ENV PYTHONPATH="/usr/local/lib/python3.11/site-packages"
ENV PYTHONUNBUFFERED=1

EXPOSE 8000

# Execute uvicorn via Distroless system python3 binary
ENTRYPOINT ["/usr/bin/python3", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]