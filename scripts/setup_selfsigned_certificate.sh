#!/bin/bash

set -e

# 1. Comprobar que Apache está instalado
if ! dpkg -s apache2 >/dev/null 2>&1; then
    echo "Apache no está instalado. Ejecuta antes install_apache.sh."
    exit 1
fi

# 2. Localizar el repositorio y leer el archivo .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "No existe $ENV_FILE. Crea el archivo .env antes de continuar."
    exit 1
fi

source "$ENV_FILE"

# Comprobar que están definidas todas las variables necesarias
for VAR in COUNTRY STATE LOCALITY ORGANIZATION ORGANIZATIONAL_UNIT DOMAIN ELASTIC_IP EMAIL CERT_DAYS KEY_PATH CERT_PATH HTTP_CONF_PATH HTTPS_CONF_PATH; do
    if [ -z "${!VAR:-}" ]; then
        echo "Falta definir la variable $VAR en .env"
        exit 1
    fi
done

# Comprobar que existen las plantillas
if [ ! -f "$REPO_DIR/conf/000-default.conf" ] ||
   [ ! -f "$REPO_DIR/conf/practica-https-ssl.conf" ]; then
    echo "No se encuentran las plantillas de la carpeta conf/."
    exit 1
fi

# 3. Crear el certificado autofirmado y la clave privada
mkdir -p "$(dirname "$KEY_PATH")"
mkdir -p "$(dirname "$CERT_PATH")"

openssl req -x509 -nodes -days "$CERT_DAYS" -newkey rsa:2048 \
    -keyout "$KEY_PATH" \
    -out "$CERT_PATH" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$DOMAIN/emailAddress=$EMAIL" \
    -addext "subjectAltName=DNS:$DOMAIN,IP:$ELASTIC_IP"

# Proteger la clave privada
chmod 600 "$KEY_PATH"
chmod 644 "$CERT_PATH"

# 4. Copiar las plantillas sustituyendo sus marcadores
sed "s|__DOMAIN__|$DOMAIN|g" \
    "$REPO_DIR/conf/000-default.conf" > "$HTTP_CONF_PATH"

sed -e "s|__DOMAIN__|$DOMAIN|g" \
    -e "s|__CERT_PATH__|$CERT_PATH|g" \
    -e "s|__KEY_PATH__|$KEY_PATH|g" \
    "$REPO_DIR/conf/practica-https-ssl.conf" > "$HTTPS_CONF_PATH"

# 5. Habilitar los módulos y los sitios
a2enmod ssl rewrite
a2ensite "$(basename "$HTTP_CONF_PATH")"
a2ensite "$(basename "$HTTPS_CONF_PATH")"

# 6. Comprobar la configuración antes de reiniciar
if ! apache2ctl configtest; then
    echo "Error en la configuración de Apache. No se reiniciará."
    exit 1
fi

systemctl restart apache2

echo "Certificado HTTPS configurado correctamente."
