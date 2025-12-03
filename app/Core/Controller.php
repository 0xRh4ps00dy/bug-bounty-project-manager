<?php

namespace App\Core;

abstract class Controller
{
    protected function json(mixed $data, int $status = 200): void
    {
        http_response_code($status);
        header('Content-Type: application/json');
        echo json_encode($data);
        exit;
    }
    
    protected function view(string $view, array $data = []): void
    {
        extract($data);
        $viewFile = __DIR__ . '/../Views/' . str_replace('.', '/', $view) . '.php';
        
        if (!file_exists($viewFile)) {
            throw new \Exception("View not found: {$view}");
        }
        
        // Start output buffering
        ob_start();
        require $viewFile;
        $content = ob_get_clean();
        
        // If layout is specified, use it
        $layout = $data['layout'] ?? 'app';
        $layoutFile = __DIR__ . '/../Views/layouts/' . $layout . '.php';
        
        if (file_exists($layoutFile)) {
            require $layoutFile;
        } else {
            echo $content;
        }
    }
    
    protected function redirect(string $url): void
    {
        header("Location: {$url}");
        exit;
    }
    
    protected function input(string $key, mixed $default = null): mixed
    {
        $data = $this->getAllInput();
        return $data[$key] ?? $default;
    }
    
    protected function getAllInput(): array
    {
        $input = [];
        
        // GET parameters
        $input = array_merge($input, $_GET);
        
        // POST parameters
        $input = array_merge($input, $_POST);
        
        // JSON body
        if ($_SERVER['CONTENT_TYPE'] === 'application/json' || 
            str_contains($_SERVER['CONTENT_TYPE'] ?? '', 'application/json')) {
            $json = json_decode(file_get_contents('php://input'), true);
            if ($json) {
                $input = array_merge($input, $json);
            }
        }
        
        return $input;
    }
    
    protected function isAjax(): bool
    {
        return !empty($_SERVER['HTTP_X_REQUESTED_WITH']) && 
               strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest';
    }
}
