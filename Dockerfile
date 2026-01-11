# Base image - matches PYTHON_VERSION in Makefile.env
FROM python:3.11-slim-bookworm

# OCI standard labels
LABEL org.opencontainers.image.title="PyRays"
LABEL org.opencontainers.image.description="A GitHub template for Python projects using uv"
LABEL org.opencontainers.image.authors="Fabio Calefato <fcalefato@gmail.com>"
LABEL org.opencontainers.image.license="MIT"
LABEL org.opencontainers.image.source="https://github.com/bateman/PyRays"

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY pyrays/src pyrays
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Create non-root user and switch to it
RUN groupadd -r appuser && \
    useradd -r -g appuser -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import pyrays" || exit 1

# Run start script
ENTRYPOINT ["./entrypoint.sh"]
