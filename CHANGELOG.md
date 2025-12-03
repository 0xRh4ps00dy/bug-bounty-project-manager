# Changelog - Bug Bounty Project Manager

## Versió 1.1 (3 Desembre 2025)

### ✨ Noves Funcionalitats

#### Assignació Automàtica de Checklist
- **Funcionalitat Principal**: Quan es crea un nou target, tots els 367 checklist items s'assignen automàticament
- **Benefici**: Estalvia temps i assegura que cap test de seguretat es quedi sense revisar
- **Implementació**: Modificat `targets.php` per afegir tots els items en crear un target

#### Millores en els Triggers
- **Optimització de GROUP_CONCAT**: Augmentat el límit a 10MB per gestionar notes grans
- **Trigger Condicional**: El trigger d'inserció només s'executa si el nou item té notes
- **Millor Rendiment**: Reducció d'operacions innecessàries en la base de dades

### 🔧 Correccions

#### Funció sanitize()
- **Problema**: La funció `sanitize()` estava eliminant contingut HTML que podia ser necessari per notes tècniques
- **Solució**: Simplificada per només fer `trim()`, mantenint el contingut original
- **Nova Funció**: Afegida `sanitizeOutput()` per escapar HTML quan es mostra

#### Notes en Checklist Items
- **Problema**: Les notes podien perdre format o contingut tècnic
- **Solució**: Les notes ara es guarden tal com s'escriuen, preservant payloads, URLs, i codi

#### Gestió de GROUP_CONCAT
- **Problema**: Error "Row was cut by GROUP_CONCAT()" quan hi havia moltes notes
- **Solució**: 
  - Augmentat límit global a 10MB
  - Establert límit de sessió dins de cada trigger
  - Trigger d'inserció optimitzat per evitar càlculs innecessaris

### 📊 Estadístiques

- **Checklist Items Totals**: 367
- **Categories**: 30
- **Assignació Automàtica**: 100% dels items en crear target
- **Temps d'Assignació**: ~2-3 segons per target

### 🛠️ Scripts d'Utilitat

#### test_target_creation.php
- Verifica que tots els targets tenen la checklist completa
- Mostra estadístiques d'assignació per cada target
- Llista els triggers actius a la base de dades

#### assign_all_items.php
- Script per assignar tots els checklist items als targets existents
- Útil per actualitzar targets creats abans d'aquesta versió
- Evita duplicats verificant abans d'inserir

### 📝 Documentació Actualitzada

- **README.md**: Afegida informació sobre assignació automàtica
- **USAGE.md**: Actualitzades instruccions de creació de targets
- **Nou fitxer**: CHANGELOG.md (aquest document)

### 🚀 Com Actualitzar

Si ja tens una instal·lació anterior:

```bash
# 1. Aturar els contenidors
docker-compose down

# 2. Eliminar el volum de MySQL
docker volume rm bug-bounty-project-manager_mysql_data

# 3. Iniciar amb la nova configuració
docker-compose up -d

# 4. Esperar que MySQL s'inicialitzi (15-20 segons)

# 5. (Opcional) Assignar items a targets existents
docker exec bbpm_web php /var/www/html/assign_all_items.php
```

### 🔍 Verificació

Pots verificar que tot funciona correctament executant:

```bash
docker exec bbpm_web php /var/www/html/test_target_creation.php
```

Hauries de veure:
```
Target #X - [Nom del Target]
  Items assignats: 367 / 367 (100%)
  ✓ Checklist completa!
```

### 🎯 Pròximes Funcionalitats (Roadmap)

- [ ] Exportació de reports en PDF
- [ ] Filtres avançats per estat de checklist
- [ ] Plantilles de projectes personalitzades
- [ ] Integració amb eines externes (Burp Suite, etc.)
- [ ] Dashboard amb gràfics de progrés
- [ ] API REST per integració amb altres eines
- [ ] Sistema de notificacions
- [ ] Gestió d'usuaris i permisos

### 📞 Suport

Per problemes o suggeriments, consulta:
- README.md per informació general
- USAGE.md per guia d'ús detallada
- Els logs de Docker: `docker-compose logs -f`

---

**Nota**: Aquest projecte està en desenvolupament actiu. Fes backups regulars de les teves dades!
