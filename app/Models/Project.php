<?php

namespace App\Models;

use App\Core\Model;

class Project extends Model
{
    protected string $table = 'projects';
    
    public function getWithTargets(int $id): ?array
    {
        $sql = "
            SELECT p.*, 
                   COUNT(t.id) as target_count,
                   AVG(t.progress) as avg_progress
            FROM projects p
            LEFT JOIN targets t ON p.id = t.project_id
            WHERE p.id = ?
            GROUP BY p.id
        ";
        
        $stmt = $this->query($sql, [$id]);
        $project = $stmt->fetch();
        
        if (!$project) {
            return null;
        }
        
        // Get targets
        $sql = "SELECT * FROM targets WHERE project_id = ? ORDER BY created_at DESC";
        $stmt = $this->query($sql, [$id]);
        $project['targets'] = $stmt->fetchAll();
        
        return $project;
    }
    
    public function getAllWithStats(): array
    {
        $sql = "
            SELECT p.*, 
                   COUNT(t.id) as target_count,
                   AVG(t.progress) as avg_progress
            FROM projects p
            LEFT JOIN targets t ON p.id = t.project_id
            GROUP BY p.id
            ORDER BY p.created_at DESC
        ";
        
        return $this->query($sql)->fetchAll();
    }
}
