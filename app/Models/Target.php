<?php

namespace App\Models;

use App\Core\Model;

class Target extends Model
{
    protected string $table = 'targets';
    
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
            $values[] = $data['notes'];
        }
        
        if (empty($sets)) {
            return false;
        }
        
        $values[] = $targetId;
        $values[] = $itemId;
        
        $sql = "UPDATE target_checklist SET " . implode(', ', $sets) . " WHERE target_id = ? AND checklist_item_id = ?";
        $stmt = $this->db->prepare($sql);
        
        return $stmt->execute($values);
    }
}
