# syntax=docker/dockerfile:1

# ============================================
# Base stage - common settings
# ============================================
FROM python:3.13-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# ============================================
# Builder stage - install dependencies
# ============================================
FROM base AS builder

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
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Copy application code
COPY --chown=appuser:appgroup . .

# Collect static files
RUN python manage.py collectstatic --noinput --clear 2>/dev/null || true

USER appuser

EXPOSE 8000

CMD ["gunicorn", "fxjurnal.wsgi:application", "--bind", "0.0.0.0:8000"]

# ============================================
# Development stage
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
