-- Taula d'usuaris
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

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
);

-- Taula de targets (objectius dins de cada projecte)
CREATE TABLE IF NOT EXISTS targets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    url VARCHAR(500),
    description TEXT,
    status VARCHAR(50) DEFAULT 'active',
    progress DECIMAL(5,2) DEFAULT 0.00,
    notes TEXT,
    aggregated_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- Taula de categories de testing
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    order_num INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Taula de checklist items (plantilla base)
CREATE TABLE IF NOT EXISTS checklist_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    order_num INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);

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
);

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
);

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

-- Inserir items de Recon Phase
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(1, 'Identify web server, technologies and database', 1),
(1, 'Subsidiary and Acquisition Enumeration', 2),
(1, 'Reverse Lookup', 3),
(1, 'ASN & IP Space Enumeration and Service Enumeration', 4),
(1, 'Google Dorking', 5),
(1, 'Github Recon', 6),
(1, 'Directory Enumeration', 7),
(1, 'IP Range Enumeration', 8),
(1, 'JS Files Analysis', 9),
(1, 'Subdomain Enumeration and Bruteforcing', 10),
(1, 'Subdomain Takeover', 11),
(1, 'Parameter Fuzzing', 12),
(1, 'Port Scanning', 13),
(1, 'Template-Based Scanning(Nuclei)', 14),
(1, 'Wayback History', 15),
(1, 'Broken Link Hijacking', 16),
(1, 'Internet Search Engine Discovery', 17),
(1, 'Misconfigured Cloud Storage', 18);

-- Inserir items de Registration Feature Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(2, 'Check for duplicate registration/Overwrite existing user', 1),
(2, 'Check for weak password policy', 2),
(2, 'Check for reuse existing usernames', 3),
(2, 'Check for insufficient email verification process', 4),
(2, 'Weak registration implementation-Allows disposable email addresses', 5),
(2, 'Weak registration implementation-Over HTTP', 6),
(2, 'Overwrite default web application pages by specially crafted username registrations', 7);

-- Inserir items de Session Management Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(3, 'Identify actual session cookie out of bulk cookies in the application', 1),
(3, 'Decode cookies using some standard decoding algorithms such as Base64, hex, URL, etc', 2),
(3, 'Modify cookie.session token value by 1 bit/byte', 3),
(3, 'If self-registration is available and you can choose your username, log in with a series of similar usernames', 4),
(3, 'Check for session cookies and cookie expiration date/time', 5),
(3, 'Identify cookie domain scope', 6),
(3, 'Check for HttpOnly flag in cookie', 7),
(3, 'Check for Secure flag in cookie if the application is over SSL', 8),
(3, 'Check for session fixation i.e. value of session cookie before and after authentication', 9),
(3, 'Replay the session cookie from a different effective IP address or system', 10),
(3, 'Check for concurrent login through different machine/IP', 11),
(3, 'Check if any user pertaining information is stored in cookie value or not', 12),
(3, 'Failure to Invalidate Session on (Email Change,2FA Activation)', 13);

-- Inserir items de Authentication Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(4, 'Username enumeration', 1),
(4, 'Bypass authentication using various SQL Injections on username and password field', 2),
(4, 'Lack of password confirmation on Change email address', 3),
(4, 'Lack of password confirmation on Change password', 4),
(4, 'Lack of password confirmation on Manage 2FA', 5),
(4, 'Is it possible to use resources without authentication? Access violation', 6),
(4, 'Check if user credentials are transmitted over SSL or not', 7),
(4, 'Weak login function HTTP and HTTPS both are available', 8),
(4, 'Test user account lockout mechanism on brute force attack', 9),
(4, 'Bypass rate limiting by tampering user agent to Mobile User agent', 10),
(4, 'Bypass rate limiting by tampering user agent to Anonymous user agent', 11),
(4, 'Bypass rate liniting by using null byte', 12),
(4, 'Create a password wordlist using cewl command', 13),
(4, 'Test Oauth login functionality', 14),
(4, 'OAuth: Resource Owner → User', 15),
(4, 'OAuth: Resource Server → Twitter', 16),
(4, 'OAuth: Client Application → Twitterdeck.com', 17),
(4, 'OAuth: Authorization Server → Twitter', 18),
(4, 'OAuth: client_id → Twitterdeck ID', 19),
(4, 'OAuth: client_secret → Secret Token', 20),
(4, 'OAuth: response_type → Defines the token type', 21),
(4, 'OAuth: scope → The requested level of access', 22),
(4, 'OAuth: redirect_uri → The URL user is redirected to', 23),
(4, 'OAuth: state → Main CSRF protection', 24),
(4, 'OAuth: grant_type → Defines the grant_type', 25),
(4, 'OAuth: code → The authorization code', 26),
(4, 'OAuth: access_token → The token to make API requests', 27),
(4, 'OAuth: refresh_token → Allows new access_token', 28),
(4, 'OAuth Code Flaws: Re-Using the code', 29),
(4, 'OAuth Code Flaws: Code Predict/Bruteforce and Rate-limit', 30),
(4, 'OAuth Code Flaws: Is the code for application X valid for application Y?', 31),
(4, 'OAuth Redirect_uri Flaws: URL isn''t validated at all', 32),
(4, 'OAuth Redirect_uri Flaws: Subdomains allowed (Subdomain Takeover)', 33),
(4, 'OAuth Redirect_uri Flaws: Host is validated, path isn''t (Chain open redirect)', 34),
(4, 'OAuth Redirect_uri Flaws: Host is validated, path isn''t (Referer leakages)', 35),
(4, 'OAuth Redirect_uri Flaws: Weak Regexes', 36),
(4, 'OAuth Redirect_uri Flaws: Bruteforcing the URL encoded chars after host', 37),
(4, 'OAuth Redirect_uri Flaws: Bruteforcing the keywords whitelist after host', 38),
(4, 'OAuth Redirect_uri Flaws: URI validation in place: use typical open redirect payloads', 39),
(4, 'OAuth State Flaws: Missing State parameter? (CSRF)', 40),
(4, 'OAuth State Flaws: Predictable State parameter?', 41),
(4, 'OAuth State Flaws: Is State parameter being verified?', 42),
(4, 'OAuth Misc: Is client_secret validated?', 43),
(4, 'OAuth Misc: Pre ATO using facebook phone-number signup', 44),
(4, 'OAuth Misc: No email validation Pre ATO', 45),
(4, 'Test 2FA Misconfiguration: Response Manipulation', 46),
(4, 'Test 2FA Misconfiguration: Status Code Manipulation', 47),
(4, 'Test 2FA Misconfiguration: 2FA Code Leakage in Response', 48),
(4, 'Test 2FA Misconfiguration: 2FA Code Reusability', 49),
(4, 'Test 2FA Misconfiguration: Lack of Brute-Force Protection', 50),
(4, 'Test 2FA Misconfiguration: Missing 2FA Code Integrity Validation', 51),
(4, 'Test 2FA Misconfiguration: With null or 000000', 52);

-- Inserir items de My Account (Post Login) Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(5, 'Find parameter which uses active account user id. Try to tamper it', 1),
(5, 'Create a list of features that are pertaining to a user account only', 2),
(5, 'Post login change email id and update with any existing email id', 3),
(5, 'Open profile picture in a new tab and check the URL', 4),
(5, 'Check account deletion option if application provides it', 5),
(5, 'Change email id, account id, user id parameter and try to brute force other user''s password', 6),
(5, 'Check whether application re authenticates for performing sensitive operation', 7);

-- Inserir items de Forgot Password Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(6, 'Failure to invalidate session on Logout and Password reset', 1),
(6, 'Check if forget password reset link/code uniqueness', 2),
(6, 'Check if reset link does get expire or not', 3),
(6, 'Find user account identification parameter and tamper Id', 4),
(6, 'Check for weak password policy', 5),
(6, 'Weak password reset implementation Token is not invalidated after use', 6),
(6, 'If reset link has another param such as date and time, then change it', 7),
(6, 'Check if security questions are asked? How many guesses allowed?', 8),
(6, 'Add only spaces in new password and confirmed password', 9),
(6, 'Does it display old password on the same page', 10),
(6, 'Ask for two password reset link and use the older one', 11),
(6, 'Check if active session gets destroyed upon changing the password or not?', 12),
(6, 'Weak password reset implementation Password reset token sent over HTTP', 13),
(6, 'Send continuous forget password requests so that it may send sequential tokens', 14);

-- Inserir items de Contact Us Form Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(7, 'Is CAPTCHA implemented on contact us form', 1),
(7, 'Does it allow to upload file on the server?', 2),
(7, 'Blind XSS', 3);

-- Inserir items de Product Purchase Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(8, 'Buy Now: Tamper product ID to purchase other high valued product with low prize', 1),
(8, 'Buy Now: Tamper product data to increase the number of product with the same prize', 2),
(8, 'Gift/Voucher: Tamper gift/voucher count in the request', 3),
(8, 'Gift/Voucher: Tamper gift/voucher value to increase/decrease the value', 4),
(8, 'Gift/Voucher: Reuse gift/voucher by using old gift values', 5),
(8, 'Gift/Voucher: Check the uniqueness of gift/voucher parameter', 6),
(8, 'Gift/Voucher: Use parameter pollution technique to add the same voucher twice', 7),
(8, 'Add/Delete Product from Cart: Tamper user id to delete products', 8),
(8, 'Add/Delete Product from Cart: Tamper cart id to add/delete products', 9),
(8, 'Add/Delete Product from Cart: Identify cart id/user id to view added items', 10),
(8, 'Address: Tamper BurpSuite request to change other user''s shipping address', 11),
(8, 'Address: Try stored XSS by adding XSS vector on shipping address', 12),
(8, 'Address: Use parameter pollution technique to add two shipping address', 13),
(8, 'Place Order: Tamper payment options parameter to change the payment method', 14),
(8, 'Place Order: Tamper the amount value for payment manipulation', 15),
(8, 'Place Order: Check if CVV is going in cleartext or not', 16),
(8, 'Place Order: Check if the application itself processes your card details', 17),
(8, 'Track Order: Track other user''s order by guessing order tracking number', 18),
(8, 'Track Order: Brute force tracking number prefix or suffix', 19),
(8, 'Wish list: Check if a user A can add/remote products in Wishlist of user B', 20),
(8, 'Wish list: Check if a user A can add products into user B''s cart from Wishlist', 21),
(8, 'Post product purchase: Check if user A can cancel orders for user B', 22),
(8, 'Post product purchase: Check if user A can view/check orders by user B', 23),
(8, 'Post product purchase: Check if user A can modify the shipping address of user B', 24),
(8, 'Out of band: Can user order product which is out of stock?', 25);

-- Inserir items de Banking Application Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(9, 'Billing Activity: Check if user A can view the account statement for user B', 1),
(9, 'Billing Activity: Check if user A can view the transaction report for user B', 2),
(9, 'Billing Activity: Check if user A can view the summary report for user B', 3),
(9, 'Billing Activity: Check if user A can register for monthly/weekly statement via email', 4),
(9, 'Billing Activity: Check if user A can update the existing email id of user B', 5),
(9, 'Deposit/Loan/Linked: Check if user A can view the deposit account summary of user B', 6),
(9, 'Deposit/Loan/Linked: Check for account balance tampering for Deposit accounts', 7),
(9, 'Tax Deduction: Check if user A can see the tax deduction details of user B', 8),
(9, 'Tax Deduction: Check parameter tampering for increasing and decreasing interest rate', 9),
(9, 'Tax Deduction: Check if user A can download the TDS details of user B', 10),
(9, 'Tax Deduction: Check if user A can request for the cheque book behalf of user B', 11),
(9, 'Fixed Deposit: Check if is it possible for user A to open FD account behalf of user B', 12),
(9, 'Fixed Deposit: Check if Can user open FD account with more amount than balance', 13),
(9, 'Stopping Payment: Can user A stop the payment of user B via cheque number', 14),
(9, 'Stopping Payment: Can user A stop the payment on basis of date range for user B', 15),
(9, 'Status Enquiry: Can user A view the status enquiry of user B', 16),
(9, 'Status Enquiry: Can user A modify the status enquiry of user B', 17),
(9, 'Status Enquiry: Can user A post and enquiry behalf of user B', 18),
(9, 'Fund transfer: Is it possible to transfer funds to user C instead of user B', 19),
(9, 'Fund transfer: Can fund transfer amount be manipulated?', 20),
(9, 'Fund transfer: Can user A modify the payee list of user B', 21),
(9, 'Fund transfer: Is it possible to add payee without any proper validation', 22),
(9, 'Schedule transfer: Can user A view the schedule transfer of user B', 23),
(9, 'Schedule transfer: Can user A change the details of schedule transfer for user B', 24),
(9, 'NEFT: Amount manipulation via NEFT transfer', 25),
(9, 'NEFT: Check if user A can view the NEFT transfer details of user B', 26),
(9, 'Bill Payment: Check if user can register payee without any checker approval', 27),
(9, 'Bill Payment: Check if user A can view the pending payments of user B', 28),
(9, 'Bill Payment: Check if user A can view the payment made details of user B', 29);

-- Inserir items de Open Redirection Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(10, 'Use burp find option to find parameters such as URL, red, redirect, redir, origin', 1),
(10, 'Check the value of these parameter which may contain a URL', 2),
(10, 'Change the URL value and check if gets redirected', 3),
(10, 'Try Single Slash and url encoding', 4),
(10, 'Using a whitelisted domain or keyword', 5),
(10, 'Using // to bypass http blacklisted keyword', 6),
(10, 'Using https: to bypass // blacklisted keyword', 7),
(10, 'Using \\\\ to bypass // blacklisted keyword', 8),
(10, 'Using \\/\\/ to bypass // blacklisted keyword', 9),
(10, 'Using null byte %00 to bypass blacklist filter', 10),
(10, 'Using ° symbol to bypass', 11);

-- Inserir items de Host Header Injection
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(11, 'Supply an arbitrary Host header', 1),
(11, 'Check for flawed validation', 2),
(11, 'Send ambiguous requests: Inject duplicate Host headers', 3),
(11, 'Send ambiguous requests: Supply an absolute URL', 4),
(11, 'Send ambiguous requests: Add line wrapping', 5),
(11, 'Inject host override headers', 6);

-- Inserir items de SQL Injection Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(12, 'Entry point detection: Simple characters', 1),
(12, 'Entry point detection: Multiple encoding', 2),
(12, 'Entry point detection: Merging characters', 3),
(12, 'Entry point detection: Logic Testing', 4),
(12, 'Entry point detection: Weird characters', 5),
(12, 'Run SQL injection scanner on all requests', 6),
(12, 'Bypassing WAF: Using Null byte before SQL query', 7),
(12, 'Bypassing WAF: Using SQL inline comment sequence', 8),
(12, 'Bypassing WAF: URL encoding', 9),
(12, 'Bypassing WAF: Changing Cases (uppercase/lowercase)', 10),
(12, 'Bypassing WAF: Use SQLMAP tamper scripts', 11),
(12, 'Time Delays: Oracle dbms_pipe.receive_message', 12),
(12, 'Time Delays: Microsoft WAITFOR DELAY', 13),
(12, 'Time Delays: PostgreSQL pg_sleep', 14),
(12, 'Time Delays: MySQL sleep', 15),
(12, 'Conditional Delays: Oracle', 16),
(12, 'Conditional Delays: Microsoft', 17),
(12, 'Conditional Delays: PostgreSQL', 18),
(12, 'Conditional Delays: MySQL', 19);

-- Inserir items de Cross-Site Scripting Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(13, 'Try XSS using QuickXSS tool by theinfosecguy', 1),
(13, 'Upload file using img src=x onerror=alert payload', 2),
(13, 'If script tags are banned, use <h1> and other HTML tags', 3),
(13, 'If output is reflected back inside the JavaScript use alert(1)', 4),
(13, 'If " are filtered then use img src=d onerror=confirm payload', 5),
(13, 'Upload a JavaScript using Image file', 6),
(13, 'Unusual way to execute JS payload is to change method from POST to GET', 7),
(13, 'Tag attribute value: Input landed in input tag', 8),
(13, 'Tag attribute value: Payload to be inserted with onfocus', 9),
(13, 'Tag attribute value: Syntax Encoding payload', 10),
(13, 'XSS filter evasion: < and > can be replace with html entities', 11),
(13, 'XSS filter evasion: Try an XSS polyglot', 12),
(13, 'XSS Firewall Bypass: Check if the firewall is blocking only lowercase', 13),
(13, 'XSS Firewall Bypass: Try to break firewall regex with new line', 14),
(13, 'XSS Firewall Bypass: Try Double Encoding', 15),
(13, 'XSS Firewall Bypass: Testing for recursive filters', 16),
(13, 'XSS Firewall Bypass: Injecting anchor tag without whitespaces', 17),
(13, 'XSS Firewall Bypass: Try to bypass whitespaces using Bullet', 18),
(13, 'XSS Firewall Bypass: Try to change request method', 19);

-- Inserir items de CSRF Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(14, 'Anti-CSRF token: Removing the Anti-CSRF Token', 1),
(14, 'Anti-CSRF token: Altering the Anti-CSRF Token', 2),
(14, 'Anti-CSRF token: Using the Attacker''s Anti-CSRF Token', 3),
(14, 'Anti-CSRF token: Spoofing the Anti-CSRF Token', 4),
(14, 'Anti-CSRF token: Using guessable Anti-CSRF Tokens', 5),
(14, 'Anti-CSRF token: Stealing Anti-CSRF Tokens', 6),
(14, 'Double Submit Cookie: Check for session fixation on subdomains', 7),
(14, 'Double Submit Cookie: Man in the the middle attack', 8),
(14, 'Referrer/Origin validation: Restricting the CSRF POC from sending Referrer header', 9),
(14, 'Referrer/Origin validation: Bypass whitelisting/blacklisting mechanism', 10),
(14, 'JSON/XML format: By using normal HTML Form1', 11),
(14, 'JSON/XML format: By using normal HTML Form2 (Fetch Request)', 12),
(14, 'JSON/XML format: By using XMLHTTP Request/AJAX request', 13),
(14, 'JSON/XML format: By using Flash file', 14),
(14, 'Samesite Cookie: SameSite Lax bypass via method override', 15),
(14, 'Samesite Cookie: SameSite Strict bypass via client-side redirect', 16),
(14, 'Samesite Cookie: SameSite Strict bypass via sibling domain', 17),
(14, 'Samesite Cookie: SameSite Lax bypass via cookie refresh', 18);

-- Inserir items de SSO Vulnerabilities
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(15, 'If internal.company.com Redirects You To SSO, Do FUZZ On Internal', 1),
(15, 'If company.com/internal Redirects To SSO, Try company.com/public/internal', 2),
(15, 'Try To Craft SAML Request With Token And Send It To The Server', 3),
(15, 'If There Is AssertionConsumerServiceURL Try To Insert Your Domain', 4),
(15, 'If There Is AssertionConsumerServiceURL Try To Do FUZZ On Value', 5),
(15, 'If There Is Any UUID, Try To Change It To UUID Of Victim', 6),
(15, 'Try To Figure Out If Server Vulnerable To XML Signature Wrapping', 7),
(15, 'Try To Figure Out If Server Checks The Identity Of The Signer', 8),
(15, 'Try To Inject XXE Payloads At The Top Of The SAML Response', 9),
(15, 'Try To Inject XSLT Payloads Into The Transforms Element', 10),
(15, 'If Victim Can Accept Tokens Issued By Same Identity Provider', 11),
(15, 'While Testing SSO Try To search In Burp About URLs In Cookie Header', 12);

-- Inserir items de XML Injection Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(16, 'Change the content type to text/xml and test XXE with /etc/passwd', 1),
(16, 'Test XXE with /etc/hosts', 2),
(16, 'Test XXE with /proc/self/cmdline', 3),
(16, 'Test XXE with /proc/version', 4),
(16, 'Blind XXE with out-of-band interaction', 5);

-- Inserir items de CORS
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(17, 'Errors parsing Origin headers', 1),
(17, 'Whitelisted null origin value', 2);

-- Inserir items de SSRF
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(18, 'Try basic localhost payloads', 1),
(18, 'Bypassing filters: Bypass using HTTPS', 2),
(18, 'Bypassing filters: Bypass with [::]', 3),
(18, 'Bypassing filters: Bypass with a domain redirection', 4),
(18, 'Bypassing filters: Bypass using a decimal IP location', 5),
(18, 'Bypassing filters: Bypass using IPv6/IPv4 Address Embedding', 6),
(18, 'Bypassing filters: Bypass using malformed urls', 7),
(18, 'Bypassing filters: Bypass using rare address', 8),
(18, 'Bypassing filters: Bypass using enclosed alphanumerics', 9),
(18, 'Cloud Instances: AWS metadata endpoints', 10),
(18, 'Cloud Instances: Google Cloud metadata endpoints', 11),
(18, 'Cloud Instances: Digital Ocean metadata endpoints', 12),
(18, 'Cloud Instances: Azure metadata endpoints', 13),
(18, 'Bypassing via open redirection', 14);

-- Inserir items de File Upload Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(19, 'Upload malicious file to archive upload functionality', 1),
(19, 'Upload a file and change its path to overwrite an existing system file', 2),
(19, 'Large File Denial of Service', 3),
(19, 'Metadata Leakage', 4),
(19, 'ImageMagick Library Attacks', 5),
(19, 'Pixel Flood Attack', 6),
(19, 'Bypasses: Null Byte (%00) Bypass', 7),
(19, 'Bypasses: Content-Type Bypass', 8),
(19, 'Bypasses: Magic Byte Bypass', 9),
(19, 'Bypasses: Client-Side Validation Bypass', 10),
(19, 'Bypasses: Blacklisted Extension Bypass', 11),
(19, 'Bypasses: Homographic Character Bypass', 12);

-- Inserir items de CAPTCHA Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(20, 'Missing Captcha Field Integrity Checks', 1),
(20, 'HTTP Verb Manipulation', 2),
(20, 'Content Type Conversion', 3),
(20, 'Reusuable Captcha', 4),
(20, 'Check if captcha is retrievable with the absolute path', 5),
(20, 'Check for server side validation for CAPTCHA', 6),
(20, 'Check if image recognition can be done with OCR tool', 7);

-- Inserir items de JWT Token Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(21, 'Brute-forcing secret keys', 1),
(21, 'Signing a new token with the "none" algorithm', 2),
(21, 'Changing the signing algorithm of the token', 3),
(21, 'Signing the asymmetrically-signed token to its symmetric algorithm match', 4);

-- Inserir items de Websockets Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(22, 'Intercepting and modifying WebSocket messages', 1),
(22, 'Websockets MITM attempts', 2),
(22, 'Testing secret header websocket', 3),
(22, 'Content stealing in websockets', 4),
(22, 'Token authentication testing in websockets', 5);

-- Inserir items de GraphQL Vulnerabilities Testing
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(23, 'Inconsistent Authorization Checks', 1),
(23, 'Missing Validation of Custom Scalars', 2),
(23, 'Failure to Appropriately Rate-limit', 3),
(23, 'Introspection Query Enabled/Disabled', 4);

-- Inserir items de WordPress Common Vulnerabilities
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(24, 'XSPA in wordpress', 1),
(24, 'Bruteforce in wp-login.php', 2),
(24, 'Information disclosure wordpress username', 3),
(24, 'Backup file wp-config exposed', 4),
(24, 'Log files exposed', 5),
(24, 'Denial of Service via load-styles.php', 6),
(24, 'Denial of Service via load-scripts.php', 7),
(24, 'DDOS using xmlrpc.php', 8),
(24, 'CVE-2018-6389', 9),
(24, 'CVE-2021-24364', 10),
(24, 'WP-Cronjob DOS', 11);

-- Inserir items de XPath Injection
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(25, 'XPath injection to bypass authentication', 1),
(25, 'XPath injection to exfiltrate data', 2),
(25, 'Blind and Time-based XPath injections to exfiltrate data', 3);

-- Inserir items de LDAP Injection
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(26, 'LDAP injection to bypass authentication', 1),
(26, 'LDAP injection to exfiltrate data', 2);

-- Inserir items de Denial of Service
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(27, 'Cookie bomb', 1),
(27, 'Pixel flood, using image with a huge pixels', 2),
(27, 'Frame flood, using GIF with a huge frame', 3),
(27, 'ReDoS (Regex DoS)', 4),
(27, 'CPDoS (Cache Poisoned Denial of Service)', 5);

-- Inserir items de 403 Bypass
INSERT INTO checklist_items (category_id, title, order_num) VALUES
(28, 'Using "X-Original-URL" header', 1),
(28, 'Appending %2e after the first slash', 2),
(28, 'Try add dot (.) slash (/) and semicolon (;) in the URL', 3),
(28, 'Add "..;/" after the directory name', 4),
(28, 'Try to uppercase the alphabet in the url', 5),
(28, 'Tool-bypass-403', 6),
(28, 'Burp Extension-403 Bypasser', 7);

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
INSERT INTO targets (project_id, name, url, description) VALUES
(1, 'Main Website', 'https://shop.example.com', 'Primary e-commerce website with product catalog and checkout'),
(1, 'Admin Panel', 'https://admin.shop.example.com', 'Administrative backend for managing products and orders'),
(1, 'Payment Gateway', 'https://pay.shop.example.com', 'Payment processing integration endpoint'),
(2, 'Online Banking Portal', 'https://bank.example.com', 'Customer-facing online banking portal'),
(2, 'Mobile Banking API', 'https://api.bank.example.com', 'REST API for mobile banking application'),
(3, 'Main Platform', 'https://social.example.com', 'Main social networking platform'),
(3, 'User Profile API', 'https://api.social.example.com/users', 'User profile management API endpoints'),
(4, 'Authentication API', 'https://api.mobile.example.com/auth', 'Authentication and authorization endpoints'),
(4, 'User Data API', 'https://api.mobile.example.com/data', 'User data management endpoints');

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
