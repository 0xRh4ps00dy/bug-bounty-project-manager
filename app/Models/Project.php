<?php

namespace App\Models;

use App\Core\Model;

class Project extends Model
{
    protected string $table = 'projects';
    
    public function getWithTargets(int $id): ?array
    {
        // Get project
        $sql = "SELECT * FROM projects WHERE id = ?";
        $stmt = $this->query($sql, [$id]);
        $project = $stmt->fetch();
        
        if (!$project) {
            return null;
        }
        
        // Get targets with progress
        $sql = "
            SELECT t.*,
                   COUNT(tc.id) as total_items,
                   SUM(CASE WHEN tc.is_checked THEN 1 ELSE 0 END) as completed_items,
                   COALESCE(
                       ROUND((SUM(CASE WHEN tc.is_checked THEN 1 ELSE 0 END) / COUNT(tc.id)) * 100, 2),
                       0
                   ) as progress
            FROM targets t
            LEFT JOIN target_checklist tc ON t.id = tc.target_id
            WHERE t.project_id = ?
            GROUP BY t.id
            ORDER BY t.created_at DESC
        ";
        $stmt = $this->query($sql, [$id]);
        $project['targets'] = $stmt->fetchAll();
        
        // Calculate average progress
        $totalProgress = 0;
        $targetCount = count($project['targets']);
        foreach ($project['targets'] as $target) {
            $totalProgress += $target['progress'] ?? 0;
        }
        $project['avg_progress'] = $targetCount > 0 ? round($totalProgress / $targetCount, 2) : 0;
        $project['target_count'] = $targetCount;
        
        return $project;
    }

    public function getAllWithStats(): array
    {
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
        
        $results = $this->query($sql)->fetchAll();
        
        // Group by project and calculate stats
        $projects = $this->query("SELECT * FROM projects ORDER BY created_at DESC")->fetchAll();
        
        foreach ($projects as &$project) {
            $projectTargets = array_filter($results, fn($t) => $t['project_id'] == $project['id']);
            $project['target_count'] = count($projectTargets);
            
            $totalProgress = 0;
            foreach ($projectTargets as $target) {
                $totalProgress += $target['progress'] ?? 0;
            }
            $project['avg_progress'] = count($projectTargets) > 0 ? round($totalProgress / count($projectTargets), 2) : 0;
        }
        
        return $projects;
    }
}
