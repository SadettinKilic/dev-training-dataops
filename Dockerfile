FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir dbt-databricks

COPY . .

RUN dbt deps --profiles-dir .

ENTRYPOINT ["dbt"]
