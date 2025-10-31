FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y redis-server curl build-essential nodejs npm && rm -rf /var/lib/apt/lists/*
COPY cargo_ecommerce /app/cargo_ecommerce
COPY web2-blockchain-middleware /app/web2-blockchain-middleware
RUN pip install --upgrade pip && pip install -r /app/cargo_ecommerce/requirements.txt
RUN cd web2-blockchain-middleware && npm install
EXPOSE 8000
CMD redis-server --daemonize yes && \
    celery -A cargo_ecommerce worker --loglevel=info & \
    celery -A cargo_ecommerce beat --loglevel=info & \
    python cargo_ecommerce/manage.py migrate && \
    python cargo_ecommerce/manage.py runserver 0.0.0.0:8000 & \
    cd web2-blockchain-middleware && npm start

