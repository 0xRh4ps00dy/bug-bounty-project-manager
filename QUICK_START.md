# 🚀 Quick Start - Targets Enhancement

## Para Nuevas Instalaciones

No requiere configuración adicional. El esquema actualizado está en `mysql/init.sql`.

### Pasos:
1. `docker-compose up -d`
2. Accede a http://localhost
3. Ve a **Targets** > **New Target**
4. Selecciona tipo (URL, IP, o Domain)
5. Ingresa el valor
6. ¡Listo!

---

## Para Instalaciones Existentes

### Opción 1: Migración Automática (Recomendado)

```bash
# Ejecutar el script de migración
docker-compose exec db mysql -u root -proot_password bbpm_db < mysql/migrations/001_add_target_type.sql
```

### Opción 2: Migración Manual

```bash
# Acceder a phpMyAdmin
# http://localhost:8080
# Usuario: root
# Contraseña: root_password

# Ejecutar en SQL:
ALTER TABLE targets CHANGE COLUMN url target VARCHAR(500);

ALTER TABLE targets 
ADD COLUMN target_type ENUM('url', 'ip', 'domain') DEFAULT 'url' AFTER target;

UPDATE targets SET target_type = 'url';
```

### Opción 3: Rebuild Completo

```bash
# ⚠️ Esto eliminará TODOS los datos
docker-compose down
docker volume rm bug-bounty-project-manager_mysql_data
docker-compose up -d
```

---

## Verificación Post-Migración

### 1. Verificar en phpMyAdmin
```sql
SHOW COLUMNS FROM targets;
```

Debe mostrar las columnas:
- `target` (VARCHAR)
- `target_type` (ENUM)

### 2. Verificar Datos
```sql
SELECT id, name, target, target_type FROM targets LIMIT 5;
```

Todos los targets existentes deben tener `target_type = 'url'`.

### 3. Probar UI
1. Ve a **Targets** > **New Target**
2. Intenta crear un target de cada tipo
3. Verifica que aparezcan badges de colores

---

## Ejemplos Rápidos

### Via UI
- **URL**: `https://api.example.com`
- **IP**: `192.168.1.100`
- **Domain**: `example.com`

### Via API (cURL)

```bash
# URL
curl -X POST http://localhost/api/targets \
  -H "Content-Type: application/json" \
  -d '{"project_id":1,"target":"https://example.com","target_type":"url","name":"Website"}'

# IP
curl -X POST http://localhost/api/targets \
  -H "Content-Type: application/json" \
  -d '{"project_id":1,"target":"192.168.1.100","target_type":"ip","name":"Server"}'

# Domain
curl -X POST http://localhost/api/targets \
  -H "Content-Type: application/json" \
  -d '{"project_id":1,"target":"example.com","target_type":"domain","name":"Domain"}'
```

---

## Troubleshooting

### ❌ Error: "Unknown column 'target_type'"

**Solución**: Ejecutar migración:
```bash
docker-compose exec mysql mysql -u root -proot_password bug_bounty_db < mysql/migrations/001_add_target_type.sql
```

### ❌ Error de validación al crear target

**Causa**: Formato inválido para el tipo seleccionado

**Solución**:
- URL: Debe incluir `http://` o `https://`
- IP: Usar formato IPv4 (`x.x.x.x`) o IPv6 válido
- Domain: Usar formato `ejemplo.com` o `sub.ejemplo.com`

### ❌ API devuelve error 400

**Verificar**:
- Campo `target` es requerido
- Campo `target_type` es válido (url, ip, domain)
- Campo `project_id` existe

---

## Documentación Relacionada

- 📖 [TARGETS_ENHANCEMENT.md](TARGETS_ENHANCEMENT.md) - Documentación técnica
- 📖 [TESTING_GUIDE.md](TESTING_GUIDE.md) - Guía de pruebas
- 📖 [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - Referencia API
- 📖 [EXECUTIVE_SUMMARY_ES.md](EXECUTIVE_SUMMARY_ES.md) - Resumen ejecutivo

---

## Soporte

- Verificar logs: `docker-compose logs -f apache`
- Acceder a phpMyAdmin: http://localhost:8080
- Ver API: http://localhost/api/targets

**Versión**: 1.1  
**Estado**: ✅ Listo para producción
