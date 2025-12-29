# Stage 1: Builder
# UPDATED: Using Python 3.11 to support '|' syntax
FROM python:3.11-slim as builder

WORKDIR /app
COPY requirements.txt .

# Install dependencies into a temporary directory
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Final Runtime
# UPDATED: Using Python 3.11
FROM python:3.11-slim

WORKDIR /app

# Create a non-root user
RUN adduser --disabled-password --gecos '' --uid 1001 appuser

# Copy the installed dependencies from the builder stage
COPY --from=builder /install /usr/local

# Copy application code
COPY ./app ./app

# Fix permissions
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER 1001

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]