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
    
    public function store(): array|null
    {
        $target = trim($this->input('target'));
        $targetType = $this->input('target_type', 'url');
        
        // Validate target based on type
        if (!$this->validateTarget($target, $targetType)) {
            if ($this->isApiRequest()) {
                http_response_code(400);
                return ['error' => 'Invalid target format for type: ' . $targetType];
            }
            $_SESSION['flash_error'] = 'Invalid target format for type: ' . $targetType;
            $this->redirect('/targets');
            return null;
        }
        
        $data = [
            'project_id' => (int) $this->input('project_id'),
            'name' => trim($this->input('name')),
            'target' => $target,
            'target_type' => $targetType,
            'description' => trim($this->input('description', '')),
            'status' => $this->input('status', 'active')
        ];
        
        try {
            $id = $this->model->createWithChecklist($data);
            
            // If it's an API request, return array (will be converted to JSON by index.php)
            if ($this->isApiRequest()) {
                http_response_code(201);
                return ['success' => true, 'id' => $id, 'message' => 'Target created successfully'];
            }
            
            $_SESSION['flash_message'] = 'Target created successfully with full checklist';
            $this->redirect('/targets');
            return null;
        } catch (\Exception $e) {
            if ($this->isApiRequest()) {
                http_response_code(500);
                return ['error' => $e->getMessage()];
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/targets');
            return null;
        }
    }
    
    public function update(int $id): void
    {
        $targetValue = trim($this->input('target'));
        $targetType = $this->input('target_type', 'url');
        
        // Validate target based on type
        if (!$this->validateTarget($targetValue, $targetType)) {
            if ($this->isAjax()) {
                $this->json(['error' => 'Invalid target format for type: ' . $targetType], 400);
            }
            $_SESSION['flash_error'] = 'Invalid target format for type: ' . $targetType;
            $this->redirect('/targets/' . $id);
            return;
        }
        
        $data = [
            'name' => trim($this->input('name')),
            'target' => $targetValue,
            'target_type' => $targetType,
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
    
    /**
     * Validate target based on its type
     */
    private function validateTarget(string $target, string $type): bool
    {
        if (empty($target)) {
            return false;
        }
        
        return match($type) {
            'url' => $this->isValidUrl($target),
            'ip' => $this->isValidIp($target),
            'domain' => $this->isValidDomain($target),
            default => false,
        };
    }
    
    /**
     * Validate if string is a valid URL
     */
    private function isValidUrl(string $url): bool
    {
        return filter_var($url, FILTER_VALIDATE_URL) !== false;
    }
    
    /**
     * Validate if string is a valid IPv4 or IPv6 address
     */
    private function isValidIp(string $ip): bool
    {
        return filter_var($ip, FILTER_VALIDATE_IP) !== false;
    }
    
    /**
     * Validate if string is a valid domain
     * Allows: example.com, subdomain.example.com, example.co.uk, etc.
     */
    private function isValidDomain(string $domain): bool
    {
        // Domain pattern: labels separated by dots, each label 1-63 chars
        $pattern = '/^(?!-)(?:[a-zA-Z0-9-]{1,63}(?<!-)\.)*(?!-)(?:[a-zA-Z0-9-]{1,63}(?<!-))\.(?:[a-zA-Z]{2,})$/';
        return preg_match($pattern, $domain) === 1;
    }
}

