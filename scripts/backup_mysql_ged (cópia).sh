#!/bin/bash

CONTAINER_NAME="ged_db"
DB_NAME="ged"
DB_USER="backupuser"
DB_PASS="backup123"
BACKUP_DIR="/opt/ged/scripts/backup_banco"
BACKUP_DIR_SAMBA="/opt/backups-mysql"
LOG_FILE="/opt/ged/logs/log_backup.log"
BACKUP_TEMP_FILE="/tmp/backup.sql"
BACKUP_FINAL_FILE="backup_ged_$(date +%d%m%Y_%H%M%S).sql"
MAX_BACKUPS=5

## mount -t cifs //192.168.25.6/Backup_Mysql/ /opt/backups-mysql/ -o username=hbm,password=SENHA_SAMBA

mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date '+%d-%m-%Y %H:%M:%S')] Iniciando backup do banco '$DB_NAME'" >> "$LOG_FILE"

docker exec "$CONTAINER_NAME" sh -c "MYSQL_PWD=$DB_PASS mysqldump -u$DB_USER $DB_NAME > $BACKUP_TEMP_FILE"

if [ $? -eq 0 ]; then
  # Copia o arquivo do container para o diretório de backup no host
  docker cp "$CONTAINER_NAME:$BACKUP_TEMP_FILE" "$BACKUP_DIR/$BACKUP_FINAL_FILE"

  # Copia o arquivo do container para o diretório montado no samba com mount \\hbm\backup_mysql
  docker cp "$CONTAINER_NAME:$BACKUP_TEMP_FILE" "$BACKUP_DIR_SAMBA/$BACKUP_FINAL_FILE"

  # Remove o backup temporário de dentro do container
  docker exec "$CONTAINER_NAME" rm -f "$BACKUP_TEMP_FILE"

  echo "[$(date '+%d-%m-%Y %H:%M:%S')] ✅ Backup gerado com sucesso: $BACKUP_FINAL_FILE" >> "$LOG_FILE"
else
  echo "[$(date '+%d-%m-%Y %H:%M:%S')] ❌ Falha ao gerar backup do banco '$DB_NAME'" >> "$LOG_FILE"
  exit 1
fi

# Limpeza: mantém apenas os $MAX_BACKUPS mais recentes
cd "$BACKUP_DIR"
ls -1t backup_ged_*.sql 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -f

# Limpeza: mantém apenas os $MAX_BACKUPS mais recentes no mount do samba \\hbm\backup_mysql
cd "$BACKUP_DIR_SAMBA"
ls -1t backup_ged_*.sql 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -f

echo "[$(date '+%d-%m-%Y %H:%M:%S')] 🔄 Limpeza de backups antigos concluída. Mantidos os $MAX_BACKUPS mais recentes." >> "$LOG_FILE"

