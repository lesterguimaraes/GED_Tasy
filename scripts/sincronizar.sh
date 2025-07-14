#!/bin/bash

echo "Executando sincronização: $(date)" >> /opt/ged/logs/sincronizar.log

CONTAINER="ged"

if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER$"; then
    docker exec "$CONTAINER" python3 -c "from app import sincronizar_pacientes_oracle_para_mysql; sincronizar_pacientes_oracle_para_mysql()" >> /opt/ged/logs/sincronizar.log 2>&1
else
    echo "Container $CONTAINER não está em execução." >> /opt/ged/logs/sincronizar.log
fi
