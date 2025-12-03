<?php

namespace App\Models;

use App\Core\Model;

class ChecklistItem extends Model
{
    protected string $table = 'checklist_items';
    
    public function getByCategory(int $categoryId): array
    {
        return $this->where('category_id', $categoryId);
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
}
