# ==========================================
# Stage 1: Build Environment
# ==========================================
FROM python:3.11-alpine AS builder

WORKDIR /build

RUN apk add --no-cache gcc musl-dev libffi-dev

COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ==========================================
# Stage 2: Hardened Runtime (Non-Root User)
# ==========================================
FROM python:3.11-alpine

WORKDIR /app

# Create a non-privileged user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy dependencies and application code
COPY --from=builder /install /usr/local
COPY --chown=appuser:appgroup ./app /app

# Drop root privileges
USER appuser

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

ENTRYPOINT ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]