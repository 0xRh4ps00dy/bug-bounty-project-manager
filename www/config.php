<?php
// Configuració de la base de dades
define('DB_HOST', 'db');
define('DB_NAME', 'bbpm_db');
define('DB_USER', 'bbpm_user');
define('DB_PASS', 'bbpm_password');

// Connexió a la base de dades
function getConnection() {
    try {
        $pdo = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
            DB_USER,
            DB_PASS,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false
            ]
        );
        return $pdo;
    } catch(PDOException $e) {
        die("Error de connexió: " . $e->getMessage());
    }
}

// Funció per sanititzar input
function sanitize($data) {
    return htmlspecialchars(strip_tags(trim($data)));
}

// Funció per redirigir
function redirect($url) {
    header("Location: $url");
    exit();
}

// Funció per mostrar missatges flash
function setFlashMessage($message, $type = 'success') {
    $_SESSION['flash_message'] = $message;
    $_SESSION['flash_type'] = $type;
}

function getFlashMessage() {
    if (isset($_SESSION['flash_message'])) {
        $message = $_SESSION['flash_message'];
        $type = $_SESSION['flash_type'];
        unset($_SESSION['flash_message']);
        unset($_SESSION['flash_type']);
        return ['message' => $message, 'type' => $type];
    }
    return null;
}

session_start();
