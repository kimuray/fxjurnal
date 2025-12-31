# syntax=docker/dockerfile:1

# ============================================
# Frontend builder stage
# ============================================
FROM node:22-alpine AS frontend-builder

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy source and build
COPY tsconfig.json vite.config.ts ./
COPY static/src ./static/src
RUN npm run build

# ============================================
# Python base stage
# ============================================
FROM python:3.14-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# ============================================
# Python builder stage
# ============================================
FROM base AS python-builder

# Install uv for fast dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Install dependencies
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

# ============================================
# Production stage
# ============================================
FROM base AS production

# Create non-root user for security
RUN groupadd --gid 1000 appgroup \
    && useradd --uid 1000 --gid appgroup --shell /bin/bash appuser

# Copy virtual environment from builder
COPY --from=python-builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Copy application code
COPY --chown=appuser:appgroup . .

# Copy built frontend assets
COPY --from=frontend-builder --chown=appuser:appgroup /app/static/dist ./static/dist

# Collect static files
RUN python manage.py collectstatic --noinput --clear

USER appuser

EXPOSE 8000

CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]

# ============================================
# Development stage (Python only)
# ============================================
FROM base AS development

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install all dependencies including dev
RUN uv sync --frozen --no-install-project

ENV PATH="/app/.venv/bin:$PATH"

# Copy application code
COPY . .

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
