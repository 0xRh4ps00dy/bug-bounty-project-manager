<?php

use App\Controllers\ProjectController;
use App\Controllers\TargetController;
use App\Controllers\CategoryController;
use App\Controllers\ChecklistController;

// All API routes will return JSON

// Projects API
$router->get('/api/projects', [ProjectController::class, 'index']);
$router->get('/api/projects/{id}', [ProjectController::class, 'show']);
$router->post('/api/projects', [ProjectController::class, 'store']);
$router->put('/api/projects/{id}', [ProjectController::class, 'update']);
$router->delete('/api/projects/{id}', [ProjectController::class, 'destroy']);

// Targets API
$router->get('/api/targets', [TargetController::class, 'index']);
$router->get('/api/targets/{id}', [TargetController::class, 'show']);
$router->post('/api/targets', [TargetController::class, 'store']);
$router->put('/api/targets/{id}', [TargetController::class, 'update']);
$router->delete('/api/targets/{id}', [TargetController::class, 'destroy']);

// Target Checklist API
$router->post('/api/targets/{targetId}/checklist/{itemId}/toggle', [TargetController::class, 'toggleCheck']);
$router->post('/api/targets/{targetId}/checklist/{itemId}/notes', [TargetController::class, 'updateNotes']);

// Categories API
$router->get('/api/categories', [CategoryController::class, 'index']);
$router->post('/api/categories', [CategoryController::class, 'store']);
$router->put('/api/categories/{id}', [CategoryController::class, 'update']);
$router->delete('/api/categories/{id}', [CategoryController::class, 'destroy']);

// Checklist Items API
$router->get('/api/checklist', [ChecklistController::class, 'index']);
$router->post('/api/checklist', [ChecklistController::class, 'store']);
$router->put('/api/checklist/{id}', [ChecklistController::class, 'update']);
$router->delete('/api/checklist/{id}', [ChecklistController::class, 'destroy']);
