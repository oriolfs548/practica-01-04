
#!/bin/bash

# Comprobar si Apache ya está instalado
if dpkg -s apache2 >/dev/null 2>&1; then
    echo "Apache ya está instalado."
    exit 0
fi

echo "Actualizando repositorios..."

# Actualizar repositorios
if ! apt update; then
    echo "ERROR: No se pudieron actualizar los repositorios."
    exit 1
fi

echo "Repositorios actualizados correctamente."

# Instalar Apache sin intervención del usuario
echo "Instalando Apache..."

if ! DEBIAN_FRONTEND=noninteractive apt install -y apache2; then
    echo "ERROR: No se pudo instalar Apache."
    exit 1
fi

echo "Apache instalado correctamente."

# Habilitar e iniciar el servicio
echo "Habilitando e iniciando Apache..."

if ! systemctl enable --now apache2; then
    echo "ERROR: No se pudo habilitar o iniciar el servicio Apache."
    exit 1
fi

echo "Apache se ha habilitado e iniciado correctamente."

echo "Instalación de Apache completada correctamente."
exit 0
