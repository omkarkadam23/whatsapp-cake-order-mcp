# Build Stage
FROM golang:1.24.2-bullseye AS builder
WORKDIR /app
# Install dependencies and clone repositories
RUN apt-get update && apt-get install -y git gcc g++ musl-dev sqlite3 \
    && git clone https://github.com/sivadurga-web/whatsapp-mcp.git \
    && git clone https://github.com/cashfree/cashfree-mcp.git \
    && cd /app/cashfree-mcp \
    && git checkout disable-endpoints
WORKDIR /app/whatsapp-mcp/whatsapp-bridge
# Download Go modules and build the binary
ENV GOINSECURE=* \
    GOPROXY=direct \
    GIT_SSL_NO_VERIFY=true
RUN go mod download -x \
    && CGO_ENABLED=1 GOOS=linux go build -o whatsapp-bridge-main main.go
# Runtime Stage
FROM node:18-bullseye
# Install runtime dependencies
RUN apt-get update && apt-get install -y python3 python3-pip ca-certificates \
    && pip install uv \
    && update-ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
# Create user and group
RUN addgroup --system cfgrp && adduser --system --ingroup cfgrp cf
WORKDIR /app
# Set environment variables
ENV CASHFREE_PATH=/app/cashfree-mcp
ENV UV_PATH=/usr/local/bin
ENV WHATSAPP_SERVER_PATH=/app/whatsapp-mcp/whatsapp-mcp-server
ENV GODEBUG=x509ignoreCN=0
# Copy files from the builder stage and the current directory
COPY --from=builder /app/whatsapp-mcp/whatsapp-bridge /app/whatsapp-bridge
COPY --from=builder /app/cashfree-mcp /app/cashfree-mcp
COPY --from=builder /app/whatsapp-mcp/whatsapp-mcp-server /app/whatsapp-mcp-server
COPY ./ /app
# Set permissions for the cf user
RUN chown -R cf:cfgrp /app \
    && chmod +x /app/whatsapp-bridge/whatsapp-bridge-main \
    && chmod +x /app/start.sh
RUN cd /app/cashfree-mcp && npm install
# Switch to the cf user
USER cf
# Expose the application port
EXPOSE 8000
# Set the entrypoint to the start script
ENTRYPOINT ["sh", "/app/start.sh"]