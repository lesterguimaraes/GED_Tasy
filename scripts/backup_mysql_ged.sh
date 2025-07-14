#!/bin/bash

CONTAINER_NAME="ged_db"
DB_NAME="ged"
DB_USER="usuario_banco"
DB_PASS="senha"
BACKUP_DIR="/opt/backups-mysql/"
BACKUP_DIR_SAMBA="/opt/backups-mysql"
LOG_FILE="/var/www/html/scripts/logs/log_backup_ged.log"
BACKUP_TEMP_FILE="/tmp/backup.sql"
BACKUP_FINAL_FILE="backup_ged_$(date +%d%m%Y_%H%M%S).sql"
MAX_BACKUPS=3

SAMBA_MOUNT="//Ip_servidor_Samba/Backup_Mysql"
SAMBA_USER="Usuario_samba"
SAMBA_PASS="Senha_samba"

# Garante que diretórios e arquivos de log existem
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Verifica se o compartilhamento está montado
if ! mountpoint -q "$BACKUP_DIR_SAMBA"; then
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] 🔄 Partição Samba não montada. Tentando montar..." >> "$LOG_FILE"
    mount -t cifs "$SAMBA_MOUNT" "$BACKUP_DIR_SAMBA" -o username=$SAMBA_USER,password=$SAMBA_PASS
    if [ $? -ne 0 ]; then
        echo "[$(date '+%d-%m-%Y %H:%M:%S')] ❌ Falha ao montar partição Samba $SAMBA_MOUNT" >> "$LOG_FILE"
        exit 1
    else
        echo "[$(date '+%d-%m-%Y %H:%M:%S')] ✅ Partição Samba montada com sucesso." >> "$LOG_FILE"
    fi
fi

echo "[$(date '+%d-%m-%Y %H:%M:%S')] Iniciando backup do banco '$DB_NAME'" >> "$LOG_FILE"

docker exec "$CONTAINER_NAME" sh -c "MYSQL_PWD=$DB_PASS mysqldump -u$DB_USER $DB_NAME > $BACKUP_TEMP_FILE"

if [ $? -eq 0 ]; then
  docker cp "$CONTAINER_NAME:$BACKUP_TEMP_FILE" "$BACKUP_DIR/$BACKUP_FINAL_FILE"
  docker cp "$CONTAINER_NAME:$BACKUP_TEMP_FILE" "$BACKUP_DIR_SAMBA/$BACKUP_FINAL_FILE"
  docker exec "$CONTAINER_NAME" rm -f "$BACKUP_TEMP_FILE"
  echo "[$(date '+%d-%m-%Y %H:%M:%S')] ✅ Backup gerado com sucesso: $BACKUP_FINAL_FILE" >> "$LOG_FILE"
else
  echo "[$(date '+%d-%m-%Y %H:%M:%S')] ❌ Falha ao gerar backup do banco '$DB_NAME'" >> "$LOG_FILE"
  exit 1
fi

# Limpeza local
cd "$BACKUP_DIR"
ls -1t backup_ged_*.sql 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -f

# Limpeza no samba
cd "$BACKUP_DIR_SAMBA"
ls -1t backup_ged_*.sql 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -f

echo "[$(date '+%d-%m-%Y %H:%M:%S')] 🔄 Limpeza de backups antigos concluída. Mantidos os $MAX_BACKUPS mais recentes." >> "$LOG_FILE"
