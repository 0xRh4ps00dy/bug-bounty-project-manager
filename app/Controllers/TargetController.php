<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Models\Target;
use App\Models\Project;

class TargetController extends Controller
{
    private Target $model;
    private Project $projectModel;
    
    public function __construct()
    {
        $this->model = new Target();
        $this->projectModel = new Project();
    }
    
    public function index(): void
    {
        $targets = $this->model->all();
        $projects = $this->projectModel->all();
        
        if ($this->isAjax()) {
            $this->json($targets);
        }
        
        $this->view('targets.index', [
            'targets' => $targets,
            'projects' => $projects
        ]);
    }
    
    public function show(int $id): void
    {
        $target = $this->model->getWithProgress($id);
        
        if (!$target) {
            if ($this->isAjax()) {
                $this->json(['error' => 'Target not found'], 404);
            }
            $this->redirect('/targets');
        }
        
        $checklist = $this->model->getChecklist($id);
        
        // Group by category
        $groupedChecklist = [];
        foreach ($checklist as $item) {
            $categoryId = $item['category_id'];
            if (!isset($groupedChecklist[$categoryId])) {
                $groupedChecklist[$categoryId] = [
                    'category_name' => $item['category_name'],
                    'items' => []
                ];
            }
            $groupedChecklist[$categoryId]['items'][] = $item;
        }
        
        if ($this->isAjax()) {
            $this->json([
                'target' => $target,
                'checklist' => $groupedChecklist
            ]);
        }
        
        $this->view('targets.show', [
            'target' => $target,
            'checklist' => $groupedChecklist
        ]);
    }
    
    public function store(): void
    {
        $data = [
            'project_id' => (int) $this->input('project_id'),
            'url' => trim($this->input('url')),
            'description' => trim($this->input('description', '')),
            'status' => $this->input('status', 'active')
        ];
        
        try {
            $id = $this->model->createWithChecklist($data);
            
            if ($this->isAjax()) {
                $this->json(['success' => true, 'id' => $id, 'message' => 'Target created successfully'], 201);
            }
            
            $_SESSION['flash_message'] = 'Target created successfully with full checklist';
            $this->redirect('/targets');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/targets');
        }
    }
    
    public function update(int $id): void
    {
        $data = [
            'project_id' => (int) $this->input('project_id'),
            'url' => trim($this->input('url')),
            'description' => trim($this->input('description', '')),
            'status' => $this->input('status')
        ];
        
        try {
            $this->model->update($id, $data);
            
            if ($this->isAjax()) {
                $this->json(['success' => true, 'message' => 'Target updated successfully']);
            }
            
            $_SESSION['flash_message'] = 'Target updated successfully';
            $this->redirect('/targets');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/targets');
        }
    }
    
    public function destroy(int $id): void
    {
        try {
            $this->model->delete($id);
            
            if ($this->isAjax()) {
                $this->json(['success' => true, 'message' => 'Target deleted successfully']);
            }
            
            $_SESSION['flash_message'] = 'Target deleted successfully';
            $this->redirect('/targets');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/targets');
        }
    }
    
    public function toggleCheck(int $targetId, int $itemId): void
    {
        $isChecked = (int) $this->input('is_checked', 0);
        
        try {
            $this->model->updateChecklistItem($targetId, $itemId, ['is_checked' => $isChecked]);
            $this->json(['success' => true]);
        } catch (\Exception $e) {
            $this->json(['error' => $e->getMessage()], 500);
        }
    }
    
    public function updateNotes(int $targetId, int $itemId): void
    {
        $notes = trim($this->input('notes', ''));
        
        try {
            $this->model->updateChecklistItem($targetId, $itemId, ['notes' => $notes]);
            $this->json(['success' => true]);
        } catch (\Exception $e) {
            $this->json(['error' => $e->getMessage()], 500);
        }
    }
}
