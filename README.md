# 🚀 Laravel API - Infraestructura

Automatización completa de despliegue con **Docker**, **Docker Compose**
y **Ansible** para el proyecto Laravel API.

## 📁 Estructura del Proyecto

```text
infraestructura/
├── docker/
│   ├── Dockerfile              # Imagen Docker multi-stage optimizada
│   ├── docker-compose.yml      # Orquestación de servicios
│   ├── supervisord.conf        # Configuración de procesos
│   └── nginx/
│       └── default.conf        # Configuración Nginx optimizada
├── ansible/
│   ├── playbook.yml            # Playbook principal
│   ├── inventory/
│   │   └── hosts               # Inventario de servidores
│   └── roles/
│       └── laravel-api/        # Role personalizado
│           ├── tasks/          # Tareas de despliegue
│           ├── templates/      # Plantillas de configuración
│           └── handlers/       # Manejadores de eventos
└── scripts/
    ├── deploy.sh               # Script de despliegue automatizado
    └── setup.sh                # Script de configuración inicial
```

## 🛠️ Configuración Inicial

### 1. Ejecutar Setup Automático

```bash
cd infraestructura
chmod +x scripts/setup.sh
./scripts/setup.sh
```

Este script instalará automáticamente:

- ✅ Docker y Docker Compose
- ✅ Ansible
- ✅ Configuraciones base
- ✅ Entorno de desarrollo local

### 2. Configurar Servidores (Manual)

Edita el archivo de inventario con tus servidores:

```bash
nano ansible/inventory/hosts
```

Ejemplo de configuración:

```ini
[production]
prod-server ansible_host=192.168.1.100 ansible_user=ubuntu

[staging]
staging-server ansible_host=192.168.1.101 ansible_user=ubuntu
```

## 🚀 Despliegue

### Despliegue Rápido

```bash
# Staging
./scripts/deploy.sh staging

# Producción
./scripts/deploy.sh production

# Desarrollo local
./scripts/deploy.sh development
```

### Despliegue Manual con Ansible

```bash
# Desplegar en staging
ansible-playbook -i ansible/inventory/hosts ansible/playbook.yml --limit staging

# Desplegar en producción
ansible-playbook -i ansible/inventory/hosts ansible/playbook.yml --limit production
```

### Desarrollo Local con Docker Compose

```bash
# Desde la carpeta infraestructura
cd docker
docker-compose up -d

# Verificar servicios
docker-compose ps
docker-compose logs -f app
```

## 🏗️ Arquitectura de Contenedores

### Servicios Incluidos

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| **app** | 8000 | Aplicación Laravel (Nginx + PHP-FPM) |
| **mysql** | 3306 | Base de datos MySQL 8.0 |
| **redis** | 6379 | Cache y sesiones |
| **nginx_lb** | 80/443 | Load balancer (solo producción) |

### Características Docker

- ✅ **Multi-stage build** para imágenes optimizadas
- ✅ **Alpine Linux** para menor tamaño
- ✅ **Supervisor** para manejo de procesos
- ✅ **Health checks** automáticos
- ✅ **Volumes persistentes** para datos
- ✅ **Red personalizada** para comunicación segura

## 📊 Monitoreo y Logs

### Health Checks

```bash
# Verificar salud de la aplicación
curl http://localhost:8000/health

# Verificar API
curl http://localhost:8000/api/products
```

### Logs en Tiempo Real

```bash
# Logs de todos los servicios
docker-compose logs -f

# Logs específicos
docker-compose logs -f app
docker-compose logs -f mysql
docker-compose logs -f redis
```

### Logs con Ansible

Los logs de despliegue se guardan automáticamente en:

```text
infraestructura/deploy_YYYYMMDD_HHMMSS.log
```

## 🔧 Comandos Útiles

### Docker Compose

```bash
# Iniciar servicios
docker-compose up -d

# Detener servicios
docker-compose down

# Reconstruir imágenes
docker-compose build --no-cache

# Escalar servicios
docker-compose up -d --scale app=3

# Ejecutar comandos en contenedor
docker-compose exec app php artisan migrate
docker-compose exec app php artisan test
```

### Ansible

```bash
# Verificar conectividad
ansible all -i ansible/inventory/hosts -m ping

# Ejecutar comandos ad-hoc
ansible all -i ansible/inventory/hosts -m shell -a "docker ps"

# Rollback
./scripts/deploy.sh staging --rollback

# Solo verificar cambios
ansible-playbook -i ansible/inventory/hosts ansible/playbook.yml --check --diff
```

## 🔐 Seguridad

### Variables Sensibles

Crea un archivo `ansible/group_vars/all/vault.yml` para variables sensibles:

```bash
# Crear vault
ansible-vault create ansible/group_vars/all/vault.yml
```

Contenido ejemplo:

```yaml
vault_mysql_root_password: "super_secure_password"
vault_mysql_password: "secure_password"
vault_app_key: "base64:your-generated-app-key"
```

### Firewall y SSL

El playbook configura automáticamente:

- ✅ UFW firewall rules
- ✅ Headers de seguridad en Nginx
- ✅ Compresión Gzip
- ✅ Rate limiting (configuración lista)

## 🚨 Troubleshooting

### Problemas Comunes

1. **Error de permisos Docker**:

   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

2. **Contenedor no inicia**:

   ```bash
   docker-compose logs app
   docker-compose exec app php artisan config:clear
   ```

3. **Base de datos no conecta**:

   ```bash
   docker-compose exec mysql mysql -u root -p -e "SHOW DATABASES;"
   docker-compose restart mysql
   ```

4. **Ansible no conecta**:

   ```bash
   ansible all -i ansible/inventory/hosts -m ping -vvv
   # Verificar SSH keys y configuración
   ```

### Rollback Automático

En caso de falla, ejecutar rollback:

```bash
./scripts/deploy.sh production --rollback
```

## 📈 Optimizaciones Implementadas

### Docker
- ✅ Multi-stage builds
- ✅ Cache de layers optimizado
- ✅ Imágenes Alpine (menores)
- ✅ Health checks
- ✅ Resources limits
- ✅ Security contexts

### Nginx
- ✅ Compresión Gzip
- ✅ Headers de seguridad
- ✅ Cache de assets estáticos
- ✅ Rate limiting
- ✅ SSL ready

### Laravel
- ✅ Config/route/view cache
- ✅ Optimized autoloader
- ✅ Production environment
- ✅ Queue workers
- ✅ Log rotation

## 🌐 Ambientes

| Ambiente | Descripción | URL |
|----------|-------------|-----|
| **Development** | Local con hot-reload | http://localhost:8000 |
| **Staging** | Testing pre-producción | http://staging-server:8000 |
| **Production** | Ambiente productivo | https://your-domain.com |

## 📝 Próximos Pasos

1. ✅ Configurar CI/CD Pipeline (GitHub Actions)
2. ✅ Implementar monitoring con Prometheus
3. ✅ Configurar alertas automáticas
4. ✅ Backup automatizado de base de datos
5. ✅ SSL/TLS con Let's Encrypt

---

## 🤝 Contribución

Para contribuir a la infraestructura:

1. Fork el proyecto
2. Crea una rama para tu feature
3. Realiza tus cambios
4. Prueba localmente con Docker Compose
5. Envía un Pull Request

---

**🚀 ¡Tu infraestructura está lista para escalar!**