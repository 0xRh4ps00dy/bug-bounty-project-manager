<?php

namespace App\Models;

use App\Core\Model;

class Target extends Model
{
    protected string $table = 'targets';
    
    public function all(): array
    {
        $sql = "
            SELECT t.*, p.name as project_name
            FROM targets t
            LEFT JOIN projects p ON t.project_id = p.id
            ORDER BY t.created_at DESC
        ";
        $stmt = $this->db->query($sql);
        return $stmt->fetchAll();
    }

    public function getAllWithProgress(): array
    {
        $sql = "
            SELECT t.*,
                   p.name as project_name,
                   COUNT(tc.id) as total_items,
                   SUM(CASE WHEN tc.is_checked THEN 1 ELSE 0 END) as completed_items,
                   ROUND((SUM(CASE WHEN tc.is_checked THEN 1 ELSE 0 END) / COUNT(tc.id)) * 100, 2) as progress
            FROM targets t
            LEFT JOIN projects p ON t.project_id = p.id
            LEFT JOIN target_checklist tc ON t.id = tc.target_id
            GROUP BY t.id
            ORDER BY t.created_at DESC
        ";
        
        $stmt = $this->db->query($sql);
        $results = $stmt->fetchAll();
        
        // Handle NULL progress when no checklist items
        return array_map(function($target) {
            $target['progress'] = $target['progress'] ?? 0;
            return $target;
        }, $results);
    }
    
    public function createWithChecklist(array $data): int
    {
        // Create target
        $targetId = $this->create($data);
        
        // Assign all checklist items
        $sql = "SELECT id FROM checklist_items ORDER BY category_id, order_num";
        $stmt = $this->query($sql);
        $items = $stmt->fetchAll();
        
        $insertSql = "INSERT INTO target_checklist (target_id, checklist_item_id) VALUES (?, ?)";
        $insertStmt = $this->db->prepare($insertSql);
        
        foreach ($items as $item) {
            $insertStmt->execute([$targetId, $item['id']]);
        }
        
        return $targetId;
    }
    
    public function getWithProgress(int $id): ?array
    {
        $sql = "
            SELECT t.*,
                   p.name as project_name,
                   COUNT(tc.id) as total_items,
                   SUM(CASE WHEN tc.is_checked THEN 1 ELSE 0 END) as completed_items,
                   ROUND((SUM(CASE WHEN tc.is_checked THEN 1 ELSE 0 END) / COUNT(tc.id)) * 100, 2) as progress
            FROM targets t
            LEFT JOIN projects p ON t.project_id = p.id
            LEFT JOIN target_checklist tc ON t.id = tc.target_id
            WHERE t.id = ?
            GROUP BY t.id
        ";
        
        $stmt = $this->query($sql, [$id]);
        return $stmt->fetch() ?: null;
    }
    
    public function getChecklist(int $targetId): array
    {
        $sql = "
            SELECT tc.*, ci.title, ci.description, c.name as category_name, c.id as category_id
            FROM target_checklist tc
            JOIN checklist_items ci ON tc.checklist_item_id = ci.id
            JOIN categories c ON ci.category_id = c.id
            WHERE tc.target_id = ?
            ORDER BY c.order_num, ci.order_num
        ";
        
        $stmt = $this->query($sql, [$targetId]);
        return $stmt->fetchAll();
    }
    
    public function updateChecklistItem(int $targetId, int $itemId, array $data): bool
    {
        $sets = [];
        $values = [];
        
        if (isset($data['is_checked'])) {
            $sets[] = 'is_checked = ?';
            $values[] = $data['is_checked'];
        }
        
        if (isset($data['notes'])) {
            $sets[] = 'notes = ?';
            // Limpiar: trim, reemplazar todos los espacios en blanco, trim final
            $notes = trim($data['notes']);
            $notes = preg_replace('/\s+/', ' ', $notes);
            $notes = trim($notes);
            $values[] = $notes;
        }
        
        if (isset($data['severity'])) {
            $sets[] = 'severity = ?';
            $values[] = $data['severity'];
        }
        
        if (isset($data['description'])) {
            $sets[] = 'description = ?';
            // Limpiar: trim, reemplazar todos los espacios en blanco, trim final
            $description = trim($data['description']);
            $description = preg_replace('/\s+/', ' ', $description);
            $description = trim($description);
            $values[] = $description;
        }
        
        if (empty($sets)) {
            return false;
        }
        
        $sets[] = 'updated_at = NOW()';
        $values[] = $targetId;
        $values[] = $itemId;
        
        $sql = "UPDATE target_checklist SET " . implode(', ', $sets) . " WHERE target_id = ? AND checklist_item_id = ?";
        $stmt = $this->db->prepare($sql);
        
        return $stmt->execute($values);
    }
    
    public function updateChecklistItemDescription(int $itemId, string $description): bool
    {
        // Clean description
        $description = trim($description);
        $description = preg_replace('/\s+/', ' ', $description);
        $description = trim($description);
        
        $sql = "UPDATE checklist_items SET description = ? WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        
        return $stmt->execute([$description, $itemId]);
    }
    
    public function getNotesHistory(int $targetId, int $limit = 50): array
    {
        $sql = "
            SELECT nh.*, ci.title as checklist_title, c.name as category_name
            FROM notes_history nh
            JOIN checklist_items ci ON nh.checklist_item_id = ci.id
            JOIN categories c ON ci.category_id = c.id
            WHERE nh.target_id = ?
            ORDER BY nh.created_at DESC
            LIMIT ?
        ";
        
        $stmt = $this->query($sql, [$targetId, $limit]);
        return $stmt->fetchAll();
    }
    
    public function getAggregatedNotesByCategory(int $targetId): array
    {
        $sql = "
            SELECT 
                c.id as category_id,
                c.name as category_name,
                ci.id as checklist_item_id,
                ci.title,
                TRIM(tc.notes) as notes,
                tc.is_checked,
                tc.severity
            FROM target_checklist tc
            JOIN checklist_items ci ON tc.checklist_item_id = ci.id
            JOIN categories c ON ci.category_id = c.id
            WHERE tc.target_id = ? AND (tc.notes IS NOT NULL AND tc.notes != '')
            ORDER BY c.order_num, ci.order_num
        ";
        
        $stmt = $this->query($sql, [$targetId]);
        $results = $stmt->fetchAll();
        
        // Group by category and clean notes at PHP level
        $grouped = [];
        foreach ($results as $item) {
            // Clean whitespace at PHP level
            $item['notes'] = trim($item['notes']);
            $item['notes'] = preg_replace('/\s+/', ' ', $item['notes']);
            
            $catId = $item['category_id'];
            if (!isset($grouped[$catId])) {
                $grouped[$catId] = [
                    'category_id' => $catId,
                    'category_name' => $item['category_name'],
                    'items' => []
                ];
            }
            $grouped[$catId]['items'][] = $item;
        }
        
        return array_values($grouped);
    }
    
    public function getNotesBySeverity(int $targetId): array
    {
        $sql = "
            SELECT 
                tc.severity,
                COUNT(tc.id) as count,
                GROUP_CONCAT(DISTINCT ci.title SEPARATOR ', ') as items
            FROM target_checklist tc
            JOIN checklist_items ci ON tc.checklist_item_id = ci.id
            WHERE tc.target_id = ? AND tc.notes IS NOT NULL AND tc.notes != ''
            GROUP BY tc.severity
            ORDER BY FIELD(tc.severity, 'critical', 'high', 'medium', 'low', 'info')
        ";
        
        $stmt = $this->query($sql, [$targetId]);
        return $stmt->fetchAll();
    }
}
