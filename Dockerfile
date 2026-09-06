# ==========================================
# Stage 1: Build Environment
# ==========================================
FROM python:3.11-alpine AS builder

WORKDIR /build

RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache gcc musl-dev libffi-dev

COPY app/requirements.txt .

# Install application dependencies into isolated target directory
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ==========================================
# Stage 2: Hardened Production Runtime
# ==========================================
FROM python:3.11-alpine

WORKDIR /app

# Upgrade OS base packages
RUN apk update && apk upgrade --no-cache

# Remove default base Python build tools (setuptools, wheel, pip) from production runtime
RUN rm -rf /usr/local/lib/python3.11/site-packages/setuptools* \
           /usr/local/lib/python3.11/site-packages/wheel* \
           /usr/local/lib/python3.11/site-packages/pip*

# Create unprivileged application user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy solely the application dependencies and code
COPY --from=builder /install /usr/local
COPY --chown=appuser:appgroup ./app /app

# Drop to non-root user
USER appuser

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

ENTRYPOINT ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]