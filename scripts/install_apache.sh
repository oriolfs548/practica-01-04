#!/bin/bash

# Comprobar si Apache ya está instalado
if dpkg -s apache2 >/dev/null 2>&1; then
    echo "Apache ya está instalado."
    exit 0
fi

# Instalar Apache sin intervención del usuario
apt update
DEBIAN_FRONTEND=noninteractive apt install -y apache2

# Habilitar e iniciar el servicio
systemctl enable --now apache2

echo "Apache se ha instalado correctamente."
