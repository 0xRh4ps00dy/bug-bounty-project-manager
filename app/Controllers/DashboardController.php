<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Models\Project;
use App\Models\Target;

class DashboardController extends Controller
{
    private Project $projectModel;
    private Target $targetModel;
    
    public function __construct()
    {
        $this->projectModel = new Project();
        $this->targetModel = new Target();
    }
    
    public function index(): void
    {
        $stats = $this->getStats();
        $recentProjects = $this->getRecentProjects();
        $recentTargets = $this->getRecentTargets();
        
        if ($this->isAjax()) {
            $this->json([
                'stats' => $stats,
                'recentProjects' => $recentProjects,
                'recentTargets' => $recentTargets
            ]);
        }
        
        $this->view('dashboard.index', [
            'stats' => $stats,
            'recentProjects' => $recentProjects,
            'recentTargets' => $recentTargets
        ]);
    }
    
    private function getStats(): array
    {
        $db = \App\Core\Database::getInstance();
        
        $projectCount = $db->query("SELECT COUNT(*) FROM projects")->fetchColumn();
        $targetCount = $db->query("SELECT COUNT(*) FROM targets")->fetchColumn();
        $categoryCount = $db->query("SELECT COUNT(*) FROM categories")->fetchColumn();
        $completedItems = $db->query("SELECT COUNT(*) FROM target_checklist WHERE is_checked = 1")->fetchColumn();
        
        return [
            'projects' => $projectCount,
            'targets' => $targetCount,
            'categories' => $categoryCount,
            'completed_items' => $completedItems
        ];
    }
    
    private function getRecentProjects(): array
    {
        $sql = "
            SELECT p.id, p.name, p.description, p.status, p.created_at, p.updated_at,
                   COUNT(t.id) as target_count
            FROM projects p
            LEFT JOIN targets t ON p.id = t.project_id
            GROUP BY p.id, p.name, p.description, p.status, p.created_at, p.updated_at
            ORDER BY p.created_at DESC
            LIMIT 5
        ";
        
        return $this->projectModel->query($sql)->fetchAll();
    }
    
    private function getRecentTargets(): array
    {
        $sql = "
            SELECT t.*, p.name as project_name
            FROM targets t
            JOIN projects p ON t.project_id = p.id
            ORDER BY t.updated_at DESC
            LIMIT 5
        ";
        
        return $this->targetModel->query($sql)->fetchAll();
    }
}
