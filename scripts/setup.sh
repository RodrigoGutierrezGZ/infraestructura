#!/bin/bash

# =========================================
# Script de configuración inicial
# Instala dependencias y configura entorno
# =========================================

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Detectar OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
}

# Instalar Docker
install_docker() {
    log "🐳 Instalando Docker..."
    
    case $OS in
        debian)
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        redhat)
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        macos)
            if ! command -v brew &> /dev/null; then
                error "Homebrew no encontrado. Instala Docker Desktop manualmente desde https://docs.docker.com/docker-for-mac/install/"
            fi
            brew install --cask docker
            ;;
        *)
            warning "OS no soportado para instalación automática. Instala Docker manualmente."
            ;;
    esac
    
    # Agregar usuario al grupo docker
    if [[ $OS != "macos" ]] && [[ $OS != "windows" ]]; then
        sudo usermod -aG docker $USER
        log "Usuario agregado al grupo docker. Reinicia la sesión o ejecuta: newgrp docker"
    fi
    
    success "Docker instalado ✓"
}

# Instalar Ansible
install_ansible() {
    log "📋 Instalando Ansible..."
    
    case $OS in
        debian)
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip
            pip3 install ansible
            ;;
        redhat)
            sudo yum install -y python3 python3-pip
            pip3 install ansible
            ;;
        macos)
            if command -v brew &> /dev/null; then
                brew install ansible
            else
                pip3 install ansible
            fi
            ;;
        *)
            if command -v pip3 &> /dev/null; then
                pip3 install ansible
            elif command -v pip &> /dev/null; then
                pip install ansible
            else
                error "Python pip no encontrado. Instala Python primero."
            fi
            ;;
    esac
    
    success "Ansible instalado ✓"
}

# Verificar instalaciones
verify_installation() {
    log "🔍 Verificando instalaciones..."
    
    # Verificar Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        success "Docker: $DOCKER_VERSION"
    else
        error "Docker no encontrado después de la instalación"
    fi
    
    # Verificar Docker Compose
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version)
        success "Docker Compose: $COMPOSE_VERSION"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
        success "Docker Compose (legacy): $COMPOSE_VERSION"
    else
        warning "Docker Compose no encontrado"
    fi
    
    # Verificar Ansible
    if command -v ansible &> /dev/null; then
        ANSIBLE_VERSION=$(ansible --version | head -n1)
        success "Ansible: $ANSIBLE_VERSION"
    else
        error "Ansible no encontrado después de la instalación"
    fi
}

# Configurar entorno de desarrollo
setup_dev_environment() {
    log "⚙️  Configurando entorno de desarrollo..."
    
    # Crear directorios necesarios
    mkdir -p logs
    mkdir -p backups
    
    # Copiar archivos de configuración de ejemplo
    if [[ ! -f ansible/inventory/hosts.local ]]; then
        cp ansible/inventory/hosts ansible/inventory/hosts.local
        log "Archivo de hosts local creado: ansible/inventory/hosts.local"
        log "Edita este archivo con tus configuraciones específicas"
    fi
    
    # Crear archivo .env para desarrollo local
    if [[ ! -f ../.env.local ]]; then
        cat > ../.env.local << EOF
# Configuración local para desarrollo
APP_NAME="Laravel API Local"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=sqlite
DB_DATABASE=../database/database.sqlite

CACHE_STORE=array
SESSION_DRIVER=file
QUEUE_CONNECTION=sync
EOF
        log "Archivo .env.local creado para desarrollo"
    fi
    
    success "Entorno de desarrollo configurado ✓"
}

# Función principal
main() {
    echo "=========================================="
    echo "🛠️  Setup Laravel API Infrastructure"
    echo "=========================================="
    
    detect_os
    log "OS detectado: $OS"
    
    # Verificar si ya están instalados
    DOCKER_INSTALLED=false
    ANSIBLE_INSTALLED=false
    
    if command -v docker &> /dev/null; then
        DOCKER_INSTALLED=true
        log "Docker ya está instalado"
    fi
    
    if command -v ansible &> /dev/null; then
        ANSIBLE_INSTALLED=true
        log "Ansible ya está instalado"
    fi
    
    # Instalar dependencias si no están presentes
    if [[ "$DOCKER_INSTALLED" == false ]]; then
        install_docker
    fi
    
    if [[ "$ANSIBLE_INSTALLED" == false ]]; then
        install_ansible
    fi
    
    # Verificar instalaciones
    verify_installation
    
    # Configurar entorno de desarrollo
    setup_dev_environment
    
    echo ""
    success "🎉 Setup completado exitosamente!"
    echo ""
    log "Próximos pasos:"
    echo "1. Edita ansible/inventory/hosts con tus servidores"
    echo "2. Configura tus claves SSH para los servidores remotos"
    echo "3. Ejecuta: ./scripts/deploy.sh [environment]"
    echo ""
    log "Para desarrollo local:"
    echo "1. cd ../api-laravel"
    echo "2. docker-compose -f ../infraestructura/docker/docker-compose.yml up -d"
    echo "3. Visita: http://localhost:8000"
}

# Ejecutar
main "$@"