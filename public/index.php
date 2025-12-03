<?php

require_once __DIR__ . '/../vendor/autoload.php';

// Start session
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Error reporting (development mode)
error_reporting(E_ALL);
ini_set('display_errors', '1');

// Timezone
date_default_timezone_set('Europe/Madrid');

// Load routes
$router = new \App\Core\Router();
require __DIR__ . '/../routes/web.php';
require __DIR__ . '/../routes/api.php';

// Dispatch request
$method = $_SERVER['REQUEST_METHOD'];

// Handle PUT, DELETE via _method field
if ($method === 'POST' && isset($_POST['_method'])) {
    $method = strtoupper($_POST['_method']);
}

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

try {
    $result = $router->dispatch($method, $uri);
    
    // If result is array, output as JSON (for API)
    if (is_array($result)) {
        header('Content-Type: application/json');
        echo json_encode($result);
    }
} catch (\Exception $e) {
    http_response_code(500);
    if ($_SERVER['HTTP_ACCEPT'] === 'application/json' || str_starts_with($uri, '/api/')) {
        header('Content-Type: application/json');
        echo json_encode(['error' => $e->getMessage()]);
    } else {
        echo "Error: " . $e->getMessage();
    }
}
