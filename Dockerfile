# Base image - matches PYTHON_VERSION in Makefile.env
FROM python:3.12-slim-bookworm

# OCI standard labels
LABEL org.opencontainers.image.title="PyRays"
LABEL org.opencontainers.image.description="A GitHub template for Python projects using uv"
LABEL org.opencontainers.image.authors="Fabio Calefato <fcalefato@gmail.com>"
LABEL org.opencontainers.image.license="MIT"
LABEL org.opencontainers.image.source="https://github.com/bateman/PyRays"

# Install uv
COPY --from=astral/uv:latest /uv /usr/local/bin/uv

# Set working directory
WORKDIR /app

# Copy project files for dependency installation (cache layer)
COPY pyproject.toml uv.lock ./

# Install dependencies using uv (no dev dependencies, no project yet)
RUN uv sync --frozen --no-dev --no-install-project

# Copy application files
COPY pyrays pyrays

# Install the project itself
RUN uv sync --frozen --no-dev

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Create non-root user with home directory and switch to it
RUN groupadd -r appuser && \
    useradd -r -g appuser -u 1000 -m appuser && \
    chown -R appuser:appuser /app

USER appuser

# Disable uv cache for runtime (dependencies already installed)
ENV UV_NO_CACHE=1

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD uv run python -c "import pyrays" || exit 1

# Run start script
ENTRYPOINT ["./entrypoint.sh"]
