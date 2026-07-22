# Prod compose for Backend EC2 (ECR images).
# Placeholders: __ECR_REGISTRY__ __PROJECT_NAME__ __ENVIRONMENT__ __IMAGE_TAG__
# worker/selenium intentionally omitted until ARGUS_Merge compose includes them.
services:
  zap:
    image: zaproxy/zap-stable
    container_name: argus-zap
    user: zap
    command:
      - zap.sh
      - -daemon
      - -port
      - "8090"
      - -host
      - "0.0.0.0"
      - -config
      - api.addrs.addr.name=.*
      - -config
      - api.addrs.addr.regex=true
      - -config
      - api.disablekey=true
    ports:
      - "8090:8090"
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://127.0.0.1:8090/JSON/core/view/version/ || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 18
      start_period: 40s
    restart: unless-stopped

  backend:
    image: __ECR_REGISTRY__/__PROJECT_NAME__-__ENVIRONMENT__-backend:__IMAGE_TAG__
    container_name: argus-backend
    ports:
      - "8001:8000"
    env_file:
      - /opt/argus/.env
    environment:
      CONFIG_PATH: /app/config.docker.yaml
      ZAP_PROXY: http://zap:8090
    volumes:
      - /opt/argus/data:/app/data
    depends_on:
      zap:
        condition: service_healthy
    healthcheck:
      test:
        [
          "CMD",
          "python",
          "-c",
          "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/health', timeout=3)",
        ]
      interval: 5s
      timeout: 5s
      retries: 12
      start_period: 20s
    restart: unless-stopped
