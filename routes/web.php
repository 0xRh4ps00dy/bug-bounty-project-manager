<?php

use App\Controllers\DashboardController;
use App\Controllers\ProjectController;
use App\Controllers\TargetController;
use App\Controllers\CategoryController;
use App\Controllers\ChecklistController;
use App\Controllers\NotesController;

// Dashboard
$router->get('/', [DashboardController::class, 'index']);
$router->get('/dashboard', [DashboardController::class, 'index']);

// Projects
$router->get('/projects', [ProjectController::class, 'index']);
$router->get('/projects/{id}', [ProjectController::class, 'show']);
$router->post('/projects', [ProjectController::class, 'store']);
$router->put('/projects/{id}', [ProjectController::class, 'update']);
$router->delete('/projects/{id}', [ProjectController::class, 'destroy']);

// Targets
$router->get('/targets', [TargetController::class, 'index']);
$router->get('/targets/{id}', [TargetController::class, 'show']);
$router->post('/targets', [TargetController::class, 'store']);
$router->put('/targets/{id}', [TargetController::class, 'update']);
$router->delete('/targets/{id}', [TargetController::class, 'destroy']);

// Target Checklist Actions
$router->post('/targets/{targetId}/checklist/{itemId}/toggle', [TargetController::class, 'toggleCheck']);
$router->post('/targets/{targetId}/checklist/{itemId}/notes', [TargetController::class, 'updateNotes']);

// Notes Management
$router->get('/targets/{id}/notes', [NotesController::class, 'show']);
$router->get('/targets/{id}/notes/history', [NotesController::class, 'getHistory']);
$router->get('/targets/{id}/notes/by-category', [NotesController::class, 'getByCategory']);
$router->get('/targets/{id}/notes/by-severity', [NotesController::class, 'getBySeverity']);
$router->get('/targets/{id}/notes/export', [NotesController::class, 'export']);

// Categories
$router->get('/categories', [CategoryController::class, 'index']);
$router->post('/categories', [CategoryController::class, 'store']);
$router->put('/categories/{id}', [CategoryController::class, 'update']);
$router->delete('/categories/{id}', [CategoryController::class, 'destroy']);

// Checklist Items
$router->get('/checklist', [ChecklistController::class, 'index']);
$router->post('/checklist', [ChecklistController::class, 'store']);
$router->put('/checklist/{id}', [ChecklistController::class, 'update']);
$router->delete('/checklist/{id}', [ChecklistController::class, 'destroy']);
$router->post('/checklist/{id}/move-up', [ChecklistController::class, 'moveUp']);
$router->post('/checklist/{id}/move-down', [ChecklistController::class, 'moveDown']);
