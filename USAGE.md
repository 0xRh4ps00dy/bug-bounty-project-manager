# Guia Ràpida d'Ús - Bug Bounty Project Manager

## 🚀 Primer Pas: Accedir a l'Aplicació

Obre el teu navegador i accedeix a: **http://localhost**

## 📋 Flux de Treball Recomanat

### 1. Crear un Projecte
1. Ves a **Projectes** des del menú superior
2. Fes clic a **Nou Projecte**
3. Omple el nom i descripció
4. Guarda

### 2. Crear Targets per al Projecte
1. Des de la pàgina de detall del projecte, fes clic a **Afegir Target**
   - O ves a **Targets** i crea'n un nou
2. Selecciona el projecte
3. Afegeix el nom del target (ex: "Main Website")
4. Afegeix l'URL (opcional)
5. Afegeix una descripció
6. Guarda

**✨ Important**: Quan es crea un nou target, **automàticament s'assignen tots els 367 checklist items** al target. No cal afegir-los manualment!

### 3. Treballar amb la Checklist del Target
1. Ves al detall del target (fes clic a "Veure" des de la llista de targets)
2. Veuràs tots els 367 checklist items organitzats per categories
3. Els items estan agrupats per categoria per facilitar la navegació

**Nota**: Si per algun motiu un target no té tots els items, pots utilitzar el botó **Afegir Items** per afegir items d'una categoria específica.

### 4. Treballar amb la Checklist
1. Marca els items com a completats fent clic al checkbox
2. Afegeix notes específiques per cada item en el camp de text
3. Les notes es guarden fent clic al botó "Guardar" (icona de disquet)

### 5. Visualitzar el Progrés
- El dashboard mostra estadístiques generals
- Cada target mostra una barra de progrés
- Les notes de tots els items s'agreguen automàticament al camp "Notes Agregades"

## 🎯 Categories Disponibles

El sistema inclou 30 categories amb més de 350 checklist items:

- **Recon Phase**: Reconeixement i recopilació d'informació
- **Registration Feature Testing**: Testing de registre
- **Session Management Testing**: Gestió de sessions
- **Authentication Testing**: Testing d'autenticació i OAuth
- **SQL Injection Testing**: Tests d'injecció SQL
- **Cross-Site Scripting Testing**: Tests XSS
- **CSRF Testing**: Tests de Cross-Site Request Forgery
- **File Upload Testing**: Tests de pujada de fitxers
- **SSRF**: Server-Side Request Forgery
- **JWT Token Testing**: Tests de tokens JWT
- **GraphQL Vulnerabilities**: Vulnerabilitats GraphQL
- I moltes més...

## 💡 Consells

### Organització
- Crea un projecte per cada programa de bug bounty
- Crea un target per cada aplicació/subdomini
- Utilitza les categories predefinides per afegir tests ràpidament

### Notes
- Sigues específic en les notes de cada item
- Afegeix payloads, URLs afectades, i evidències
- Les notes s'agreguen automàticament al target

### Progrés
- Marca els items completats per fer seguiment del progrés
- La barra de progrés et mostra el percentatge completat
- Revisa el dashboard per veure l'estat general

## 🔧 Gestió de Categories i Items Personalitzats

### Crear Categories Personalitzades
1. Ves a **Categories**
2. Fes clic a **Nova Categoria**
3. Afegeix nom i descripció
4. Guarda

### Crear Checklist Items Personalitzats
1. Ves a **Checklist Items**
2. Fes clic a **Nou Item**
3. Selecciona la categoria
4. Afegeix el títol i descripció
5. Defineix l'ordre de classificació
6. Guarda

## 📊 Funcions del Dashboard

El dashboard mostra:
- **Projectes totals**
- **Targets totals**
- **Categories disponibles**
- **Items completats vs totals**
- **Projectes recents** amb número de targets
- **Targets amb activitat recent** amb percentatge de progrés

## 🔗 Navegació

### Breadcrumbs
- Utilitza les breadcrumbs (ruta de navegació) a la part superior per tornar enrere
- Exemple: Dashboard > Projectes > Nom del Projecte > Nom del Target

### Menú de Navegació
- **Dashboard**: Vista general
- **Projectes**: Gestió de projectes
- **Targets**: Gestió de targets
- **Categories**: Gestió de categories
- **Checklist Items**: Gestió d'items de checklist

## ⚡ Accions Ràpides

Des del dashboard pots accedir ràpidament a:
- Crear nou projecte
- Crear nou target
- Crear nova categoria
- Crear nou checklist item

## 📱 Responsive Design

L'aplicació és completament responsive i funciona en:
- Ordinadors de sobretaula
- Tablets
- Dispositius mòbils

## 🎨 Codis de Colors

- **Blau**: Projectes i accions principals
- **Vermell**: Targets i accions de visualització
- **Groc/Taronja**: Categories i accions d'edició
- **Verd**: Items completats i accions d'èxit
- **Gris**: Items pendents

### Barres de Progrés
- **Verd** (≥75%): Molt bé encaminat
- **Groc** (50-74%): A mig camí
- **Gris** (<50%): Començant

## 🆘 Ajuda

Si tens problemes:
1. Revisa els logs: `docker-compose logs -f`
2. Reinicia els contenidors: `docker-compose restart`
3. Consulta el README.md per més informació tècnica

## 📝 Exemple de Flux Complet

1. **Crear Projecte**: "Acme Corp Bug Bounty"
2. **Crear Target**: "Main Website - https://acme.com"
3. **Afegir Items**: Selecciona "Recon Phase"
4. **Treballar**:
   - ✅ Identify web server: "Apache 2.4, PHP 7.4, MySQL 8.0"
   - ✅ Subdomain Enumeration: "Found 15 subdomains, dev.acme.com exposed"
   - ✅ Google Dorking: "Found backup files in Google cache"
5. **Afegir Més Categories**: "SQL Injection Testing", "XSS Testing"
6. **Continuar el Testing**: Marca items i afegeix notes
7. **Revisar Progrés**: Visualitza el percentatge completat

Bona cacera de bugs! 🐛🎯
