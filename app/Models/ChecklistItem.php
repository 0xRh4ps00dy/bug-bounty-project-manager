<?php

namespace App\Models;

use App\Core\Model;

class ChecklistItem extends Model
{
    protected string $table = 'checklist_items';
    
    public function getByCategory(int $categoryId): array
    {
        $sql = "SELECT * FROM checklist_items WHERE category_id = ? ORDER BY order_num";
        return $this->query($sql, [$categoryId])->fetchAll();
    }
    
    public function getAllWithCategory(): array
    {
        $sql = "
            SELECT ci.*, c.name as category_name
            FROM checklist_items ci
            JOIN categories c ON ci.category_id = c.id
            ORDER BY c.order_num, ci.order_num
        ";
        
        return $this->query($sql)->fetchAll();
    }
    
    public function moveUp(int $id): bool
    {
        $item = $this->find($id);
        if (!$item) return false;
        
        // Find previous item in same category
        $sql = "SELECT * FROM checklist_items 
                WHERE category_id = ? AND order_num < ? 
                ORDER BY order_num DESC LIMIT 1";
        $prevItem = $this->query($sql, [$item['category_id'], $item['order_num']])->fetch();
        
        if (!$prevItem) return false;
        
        // Swap order numbers
        $this->update($id, ['order_num' => $prevItem['order_num']]);
        $this->update($prevItem['id'], ['order_num' => $item['order_num']]);
        
        return true;
    }
    
    public function moveDown(int $id): bool
    {
        $item = $this->find($id);
        if (!$item) return false;
        
        // Find next item in same category
        $sql = "SELECT * FROM checklist_items 
                WHERE category_id = ? AND order_num > ? 
                ORDER BY order_num ASC LIMIT 1";
        $nextItem = $this->query($sql, [$item['category_id'], $item['order_num']])->fetch();
        
        if (!$nextItem) return false;
        
        // Swap order numbers
        $this->update($id, ['order_num' => $nextItem['order_num']]);
        $this->update($nextItem['id'], ['order_num' => $item['order_num']]);
        
        return true;
    }
    
    public function reorderCategory(int $categoryId): void
    {
        $items = $this->getByCategory($categoryId);
        $order = 1;
        foreach ($items as $item) {
            $this->update($item['id'], ['order_num' => $order++]);
        }
    }
}
