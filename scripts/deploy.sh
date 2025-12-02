#!/bin/bash

# =========================================
# Script de despliegue automatizado
# Laravel API con Docker y Ansible
# =========================================

set -e  # Exit on any error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
ENVIRONMENT=${1:-staging}
PLAYBOOK_PATH="ansible/playbook.yml"
INVENTORY_PATH="ansible/inventory/hosts"
LOG_FILE="deploy_$(date +%Y%m%d_%H%M%S).log"

# Funciones
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

# Verificaciones previas
check_requirements() {
    log "🔍 Verificando requisitos..."
    
    # Verificar Ansible
    if ! command -v ansible &> /dev/null; then
        error "Ansible no está instalado. Instálalo con: pip install ansible"
    fi
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        warning "Docker no encontrado localmente (puede estar en el servidor remoto)"
    fi
    
    # Verificar archivos necesarios
    if [[ ! -f "$PLAYBOOK_PATH" ]]; then
        error "Playbook no encontrado: $PLAYBOOK_PATH"
    fi
    
    if [[ ! -f "$INVENTORY_PATH" ]]; then
        error "Inventory no encontrado: $INVENTORY_PATH"
    fi
    
    success "Todos los requisitos verificados ✓"
}

# Función principal de despliegue
deploy() {
    log "🚀 Iniciando despliegue en ambiente: $ENVIRONMENT"
    
    # Ejecutar playbook de Ansible
    log "📋 Ejecutando playbook de Ansible..."
    
    ansible-playbook \
        -i "$INVENTORY_PATH" \
        "$PLAYBOOK_PATH" \
        --limit "$ENVIRONMENT" \
        --extra-vars "deploy_env=$ENVIRONMENT" \
        --verbose \
        | tee -a "$LOG_FILE"
    
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        success "🎉 Despliegue completado exitosamente!"
        
        # Mostrar información del despliegue
        log "📊 Información del despliegue:"
        echo "Environment: $ENVIRONMENT"
        echo "Timestamp: $(date)"
        echo "Log file: $LOG_FILE"
        
        # Ejecutar verificación de salud
        verify_health
    else
        error "❌ El despliegue falló. Revisa el log: $LOG_FILE"
    fi
}

# Verificar salud de la aplicación
verify_health() {
    log "🏥 Verificando salud de la aplicación..."
    
    # Obtener IP del servidor desde inventory
    SERVER_IP=$(ansible-inventory -i "$INVENTORY_PATH" --list | jq -r ".${ENVIRONMENT}.hosts[0]" 2>/dev/null || echo "localhost")
    
    if [[ "$SERVER_IP" != "localhost" ]]; then
        HEALTH_URL="http://${SERVER_IP}:8000/health"
        API_URL="http://${SERVER_IP}:8000/api/products"
    else
        HEALTH_URL="http://localhost:8000/health"
        API_URL="http://localhost:8000/api/products"
    fi
    
    # Verificar endpoint de salud
    if curl -f -s "$HEALTH_URL" > /dev/null; then
        success "✅ Aplicación respondiendo correctamente"
        log "🔗 URLs disponibles:"
        echo "   Health Check: $HEALTH_URL"
        echo "   API Products: $API_URL"
    else
        warning "⚠️  Aplicación no responde en: $HEALTH_URL"
    fi
}

# Función de rollback
rollback() {
    warning "🔄 Iniciando rollback..."
    
    ansible-playbook \
        -i "$INVENTORY_PATH" \
        "$PLAYBOOK_PATH" \
        --limit "$ENVIRONMENT" \
        --tags "rollback" \
        --verbose \
        | tee -a "$LOG_FILE"
    
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        success "✅ Rollback completado"
    else
        error "❌ Rollback falló"
    fi
}

# Mostrar ayuda
show_help() {
    echo "🚀 Script de despliegue Laravel API"
    echo ""
    echo "Uso: $0 [ENVIRONMENT] [OPTIONS]"
    echo ""
    echo "ENVIRONMENTS:"
    echo "  development  - Servidor de desarrollo"
    echo "  staging     - Servidor de staging (default)"
    echo "  production  - Servidor de producción"
    echo ""
    echo "OPTIONS:"
    echo "  --rollback  - Ejecutar rollback en lugar de despliegue"
    echo "  --check     - Solo verificar requisitos"
    echo "  --help      - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 staging                    # Desplegar en staging"
    echo "  $0 production                 # Desplegar en producción"
    echo "  $0 staging --rollback         # Rollback en staging"
    echo "  $0 --check                    # Solo verificar requisitos"
}

# Script principal
main() {
    echo "=========================================="
    echo "🚀 Laravel API Deployment Script"
    echo "=========================================="
    
    case "${2:-deploy}" in
        --rollback)
            check_requirements
            rollback
            ;;
        --check)
            check_requirements
            ;;
        --help)
            show_help
            ;;
        deploy|*)
            check_requirements
            deploy
            ;;
    esac
}

# Ejecutar script principal
main "$@"