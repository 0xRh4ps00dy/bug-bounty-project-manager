<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Models\Project;

class ProjectController extends Controller
{
    private Project $model;
    
    public function __construct()
    {
        $this->model = new Project();
    }
    
    public function index(): void
    {
        $projects = $this->model->getAllWithStats();
        
        if ($this->isAjax()) {
            $this->json($projects);
        }
        
        $this->view('projects.index', ['projects' => $projects]);
    }
    
    public function show(int $id): void
    {
        $project = $this->model->getWithTargets($id);
        
        if (!$project) {
            if ($this->isAjax()) {
                $this->json(['error' => 'Project not found'], 404);
            }
            $this->redirect('/projects');
        }
        
        if ($this->isAjax()) {
            $this->json($project);
        }
        
        $this->view('projects.show', ['project' => $project]);
    }
    
    public function store(): void
    {
        $data = [
            'name' => trim($this->input('name')),
            'description' => trim($this->input('description', '')),
            'status' => $this->input('status', 'active')
        ];
        
        try {
            $id = $this->model->create($data);
            
            if ($this->isAjax()) {
                $this->json(['success' => true, 'id' => $id, 'message' => 'Project created successfully'], 201);
            }
            
            $_SESSION['flash_message'] = 'Project created successfully';
            $this->redirect('/projects');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/projects');
        }
    }
    
    public function update(int $id): void
    {
        $data = [
            'name' => trim($this->input('name')),
            'description' => trim($this->input('description', '')),
            'status' => $this->input('status', 'active')
        ];
        
        try {
            $this->model->update($id, $data);
            
            if ($this->isAjax()) {
                $this->json(['success' => true, 'message' => 'Project updated successfully']);
            }
            
            $_SESSION['flash_message'] = 'Project updated successfully';
            $this->redirect('/projects');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/projects');
        }
    }
    
    public function destroy(int $id): void
    {
        try {
            $this->model->delete($id);
            
            if ($this->isAjax()) {
                $this->json(['success' => true, 'message' => 'Project deleted successfully']);
            }
            
            $_SESSION['flash_message'] = 'Project deleted successfully';
            $this->redirect('/projects');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/projects');
        }
    }
}
