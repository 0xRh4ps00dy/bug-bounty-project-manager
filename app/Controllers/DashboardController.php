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
        // Get targets with progress
        $sql = "
            SELECT t.id, t.project_id,
                   COUNT(tc.id) as total_items,
                   SUM(CASE WHEN tc.is_checked THEN 1 ELSE 0 END) as completed_items,
                   COALESCE(
                       ROUND((SUM(CASE WHEN tc.is_checked THEN 1 ELSE 0 END) / COUNT(tc.id)) * 100, 2),
                       0
                   ) as progress
            FROM targets t
            LEFT JOIN target_checklist tc ON t.id = tc.target_id
            GROUP BY t.id, t.project_id
        ";
        
        $targetProgress = $this->projectModel->query($sql)->fetchAll();
        
        // Get projects with target count
        $sql = "
            SELECT p.*, COUNT(t.id) as target_count
            FROM projects p
            LEFT JOIN targets t ON p.id = t.project_id
            GROUP BY p.id
            ORDER BY p.created_at DESC
            LIMIT 5
        ";
        
        $projects = $this->projectModel->query($sql)->fetchAll();
        
        // Add progress to each project
        foreach ($projects as &$project) {
            $projectTargets = array_filter($targetProgress, fn($t) => $t['project_id'] == $project['id']);
            $totalProgress = 0;
            foreach ($projectTargets as $target) {
                $totalProgress += $target['progress'] ?? 0;
            }
            $project['avg_progress'] = count($projectTargets) > 0 ? round($totalProgress / count($projectTargets), 2) : 0;
        }
        
        return $projects;
    }
    
    private function getRecentTargets(): array
    {
        $sql = "
            SELECT t.*,
                   p.name as project_name,
                   COUNT(tc.id) as total_items,
                   SUM(CASE WHEN tc.is_checked THEN 1 ELSE 0 END) as completed_items,
                   COALESCE(
                       ROUND((SUM(CASE WHEN tc.is_checked THEN 1 ELSE 0 END) / COUNT(tc.id)) * 100, 2),
                       0
                   ) as progress
            FROM targets t
            JOIN projects p ON t.project_id = p.id
            LEFT JOIN target_checklist tc ON t.id = tc.target_id
            GROUP BY t.id, t.target, t.target_type, t.description, t.project_id, t.status, t.created_at, t.updated_at, p.name
            ORDER BY t.updated_at DESC
            LIMIT 5
        ";
        
        return $this->targetModel->query($sql)->fetchAll();
    }
}
