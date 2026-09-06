# ==========================================
# Stage 1: Build Environment
# ==========================================
FROM python:3.11-alpine AS builder

WORKDIR /build

RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache gcc musl-dev libffi-dev

COPY app/requirements.txt .

# Install dependencies into isolated directory without caching build wheels
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

# Remove setuptools, pip, and wheel from /install to eliminate build-tool CVE residue
RUN rm -rf /install/lib/python3.11/site-packages/pip* \
           /install/lib/python3.11/site-packages/setuptools* \
           /install/lib/python3.11/site-packages/wheel* \
           /install/lib/python3.11/site-packages/easy_install*

# ==========================================
# Stage 2: Hardened Runtime
# ==========================================
FROM python:3.11-alpine

WORKDIR /app

# Upgrade base packages to ensure libuuid / util-linux patches are applied
RUN apk update && apk upgrade --no-cache

# Create non-root unprivileged service account
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy solely the sanitized runtime dependencies and code
COPY --from=builder /install /usr/local
COPY --chown=appuser:appgroup ./app /app

# Drop to unprivileged user
USER appuser

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

ENTRYPOINT ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]