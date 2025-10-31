# ===============================
# XRPL E-Commerce Full Deployment
# Backend: Django + Celery + Redis
# Middleware: Node.js XRPL bridge
# ===============================

FROM python:3.11-slim AS backend
WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    nodejs \
    npm \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

COPY cargo_ecommerce /app/cargo_ecommerce
COPY web2-blockchain-middleware /app/web2-blockchain-middleware
COPY cargo_ecommerce/requirements.txt /app/requirements.txt

RUN pip install --upgrade pip && pip install -r /app/requirements.txt
RUN cd /app/web2-blockchain-middleware && npm install

# ===============================
# Install Python dependencies
# ===============================
RUN pip install --upgrade pip && pip install -r /app/requirements.txt

# ===============================
# Install Node dependencies
# ===============================
RUN cd /app/web2-blockchain-middleware && npm install

# ===============================
# Expose web port
# ===============================
EXPOSE 8000

# ===============================
# Auto-switch startup command based on SERVICE variable
# ===============================
CMD ["sh", "-c", "\
if [ \"$SERVICE\" = 'celery' ]; then \
  celery -A cargo_ecommerce worker --loglevel=info; \
elif [ \"$SERVICE\" = 'beat' ]; then \
  celery -A cargo_ecommerce beat --loglevel=info; \
elif [ \"$SERVICE\" = 'flower' ]; then \
  celery -A cargo_ecommerce flower --port=5555 --basic_auth=admin:admin123; \
elif [ \"$SERVICE\" = 'node' ]; then \
  cd /app/web2-blockchain-middleware && npm start; \
else \
  python /app/cargo_ecommerce/manage.py runserver 0.0.0.0:8000; \
fi"]
