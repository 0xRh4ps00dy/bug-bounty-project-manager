<?php

namespace App\Core;

class Router
{
    private array $routes = [];
    private string $basePath = '';
    
    public function __construct(string $basePath = '')
    {
        $this->basePath = rtrim($basePath, '/');
    }
    
    public function get(string $path, callable|array $handler): void
    {
        $this->addRoute('GET', $path, $handler);
    }
    
    public function post(string $path, callable|array $handler): void
    {
        $this->addRoute('POST', $path, $handler);
    }
    
    public function put(string $path, callable|array $handler): void
    {
        $this->addRoute('PUT', $path, $handler);
    }
    
    public function delete(string $path, callable|array $handler): void
    {
        $this->addRoute('DELETE', $path, $handler);
    }
    
    private function addRoute(string $method, string $path, callable|array $handler): void
    {
        $path = $this->basePath . $path;
        $this->routes[] = [
            'method' => $method,
            'path' => $path,
            'handler' => $handler,
            'pattern' => $this->compileRoute($path)
        ];
    }
    
    private function compileRoute(string $path): string
    {
        // Convertir {id} a regex captura groups
        $pattern = preg_replace('/\{([a-zA-Z_][a-zA-Z0-9_]*)\}/', '(?P<$1>[^/]+)', $path);
        return '#^' . $pattern . '$#';
    }
    
    public function dispatch(string $method, string $uri): mixed
    {
        // Remove query string
        $uri = strtok($uri, '?');
        $uri = rtrim($uri, '/') ?: '/';
        
        foreach ($this->routes as $route) {
            if ($route['method'] !== $method) {
                continue;
            }
            
            if (preg_match($route['pattern'], $uri, $matches)) {
                // Extract named parameters
                $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);
                
                return $this->callHandler($route['handler'], $params);
            }
        }
        
        http_response_code(404);
        return $this->notFound();
    }
    
    private function callHandler(callable|array $handler, array $params): mixed
    {
        if (is_array($handler)) {
            [$controller, $method] = $handler;
            $controller = new $controller();
            return $controller->$method(...array_values($params));
        }
        
        return $handler(...array_values($params));
    }
    
    private function notFound(): array
    {
        return ['error' => 'Route not found', 'code' => 404];
    }
}
