# Testing Guide - Targets Enhancement

## Pruebas Manuales en la UI

### 1. Crear un Target (URL)

1. Ve a **Targets** > **New Target**
2. Completa el formulario:
   - Project: Selecciona un proyecto
   - Name: "Main Website"
   - Target Type: **URL**
   - Target: `https://example.com`
   - Description: "Production website"
3. Haz clic en **Create Target**
4. ✅ Verifica que aparezca con badge azul (URL)

### 2. Crear un Target (IP)

1. Ve a **Targets** > **New Target**
2. Completa el formulario:
   - Project: Selecciona un proyecto
   - Name: "Internal Server"
   - Target Type: **IP**
   - Target: `192.168.1.100`
   - Description: "Internal server"
3. Haz clic en **Create Target**
4. ✅ Verifica que aparezca con badge cyan (IP)

### 3. Crear un Target (Domain)

1. Ve a **Targets** > **New Target**
2. Completa el formulario:
   - Project: Selecciona un proyecto
   - Name: "Root Domain"
   - Target Type: **Domain**
   - Target: `example.com`
   - Description: "Root domain"
3. Haz clic en **Create Target**
4. ✅ Verifica que aparezca con badge gris (Domain)

### 4. Validación de Formulario

Intenta crear targets con valores inválidos:

**URL inválida:**
- `Target Type: URL`
- `Target: not-a-url` ❌ Debe fallar

**IP inválida:**
- `Target Type: IP`
- `Target: 999.999.999.999` ❌ Debe fallar

**Domain inválido:**
- `Target Type: Domain`
- `Target: .invalid.` ❌ Debe fallar

## Pruebas API con cURL

### 1. Listar todos los targets

```bash
curl http://localhost/api/targets
```

Verifica que incluyan el campo `target_type`.

### 2. Crear Target (URL)

```bash
curl -X POST http://localhost/api/targets \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": 1,
    "target": "https://api.example.com/v1",
    "target_type": "url",
    "name": "API Endpoint",
    "description": "REST API v1"
  }'
```

### 3. Crear Target (IP)

```bash
curl -X POST http://localhost/api/targets \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": 1,
    "target": "10.0.0.50",
    "target_type": "ip",
    "name": "Router",
    "description": "Network router"
  }'
```

### 4. Crear Target (Domain)

```bash
curl -X POST http://localhost/api/targets \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": 1,
    "target": "subdomain.example.co.uk",
    "target_type": "domain",
    "name": "Subdomain",
    "description": "UK subdomain"
  }'
```

### 5. Obtener un Target específico

```bash
curl http://localhost/api/targets/1
```

Verifica que muestre:
- `"target": "valor del target"`
- `"target_type": "url|ip|domain"`

### 6. Actualizar un Target

```bash
curl -X PUT http://localhost/api/targets/1 \
  -H "Content-Type: application/json" \
  -d '{
    "target": "192.168.1.200",
    "target_type": "ip",
    "description": "Updated IP"
  }'
```

## Pruebas en phpMyAdmin

### 1. Ver estructura de tabla

1. Ve a http://localhost:8080
2. Usuario: `root`
3. Contraseña: `root_password`
4. Navega a `bug_bounty_db` > tabla `targets`
5. ✅ Verifica que exista columna `target` y `target_type`

### 2. Ver datos

```sql
SELECT id, name, target, target_type, project_id FROM targets;
```

✅ Verifica que todos los targets tengan `target_type` con valor válido.

## Pruebas de Exportación

### 1. Exportar en Markdown

1. Ve a un Target > **Aggregated Notes** > **Export as Markdown**
2. ✅ El archivo debe incluir "Target Type: URL/IP/DOMAIN"

### 2. Exportar en JSON

1. Ve a un Target > **Aggregated Notes** > **Export as JSON**
2. ✅ El JSON debe incluir:
```json
{
  "target": {
    "target": "valor",
    "target_type": "url|ip|domain"
  }
}
```

## Validación de Placeholder Dinámico

1. Abre el modal de crear Target
2. Cambia el "Target Type"
3. ✅ El placeholder del campo "Target" debe actualizarse

Placeholders esperados:
- **URL**: `https://example.com or https://api.example.com/endpoint`
- **IP**: `192.168.1.1 or 2001:0db8:85a3:0000:0000:8a2e:0370:7334`
- **Domain**: `example.com or subdomain.example.co.uk`

## Validación de Iconografía

Verifica que los badges en la tabla muestren:

| Tipo | Color | Badge |
|------|-------|-------|
| URL | Azul | PRIMARY |
| IP | Cyan | INFO |
| Domain | Gris | SECONDARY |

## Migración de Base de Datos

Si tienes una instalación antigua:

```bash
docker-compose exec mysql mysql -u root -proot_password bug_bounty_db < mysql/migrations/001_add_target_type.sql
```

✅ Verifica que no haya errores y que los datos se migren correctamente.

## Checklist de Verificación Final

- [ ] Crear targets de los 3 tipos desde la UI
- [ ] Validación de entrada en UI
- [ ] API acepta los 3 tipos
- [ ] Badges muestran el tipo correcto
- [ ] Exportaciones incluyen tipo
- [ ] Placeholders dinámicos funcionan
- [ ] Dashboard muestra targets correctamente
- [ ] Vista de proyecto lista targets con tipo
- [ ] URLs son clickeables, otros valores no
- [ ] Base de datos tiene datos consistentes

---

**Notas Importantes:**
- Los targets existentes obtienen automáticamente `target_type = 'url'`
- La validación se hace en backend, nunca confíes solo en validación de cliente
- Los placeholders son solo de ayuda, la validación real ocurre en servidor
