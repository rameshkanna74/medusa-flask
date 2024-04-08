# Use a lighter base image
FROM python:3.12-slim AS builder

# Set up a non-root user
RUN useradd --create-home --shell /bin/bash appuser
USER appuser

# Set environment variables for Flask
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0

# Set up a working directory for the application
WORKDIR /home/appuser/app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install dependencies
COPY --chown=appuser:appuser requirements.txt requirements.txt
RUN python -m venv /home/appuser/venv && \
    . /home/appuser/venv/bin/activate && \
    pip install --no-cache-dir -r requirements.txt

# Copy the application code into the container
COPY --chown=appuser:appuser . .


# Install ODBC for MSSQL
USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    apt-transport-https \
    gnupg && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
    msodbcsql18 \
    mssql-tools18 \
    unixodbc-dev \
    libgssapi-krb5-2 && \
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PATH="/opt/mssql-tools18/bin:${PATH}"

# Switch back to non-root user
USER appuser

# Expose port 5000 for the Flask application
EXPOSE 8080

# Set environment variables
ENV PATH=/home/appuser/venv/bin:$PATH
ENV PYTHONPATH=/home/appuser/venv/lib/python3.12/site-packages

# Start the Flask application with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
