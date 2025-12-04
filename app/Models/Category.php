<?php

namespace App\Models;

use App\Core\Model;

class Category extends Model
{
    protected string $table = 'categories';
    
    public function getWithItemCount(): array
    {
        $sql = "
            SELECT c.*, COUNT(ci.id) as item_count
            FROM categories c
            LEFT JOIN checklist_items ci ON c.id = ci.category_id
            GROUP BY c.id
            ORDER BY c.order_num
        ";
        
        return $this->query($sql)->fetchAll();
    }
    
    public function moveUp(int $id): bool
    {
        $category = $this->find($id);
        if (!$category) return false;
        
        // Find previous category
        $sql = "SELECT * FROM categories WHERE order_num < ? ORDER BY order_num DESC LIMIT 1";
        $prevCategory = $this->query($sql, [$category['order_num']])->fetch();
        
        if (!$prevCategory) return false;
        
        // Swap order numbers
        $this->update($id, ['order_num' => $prevCategory['order_num']]);
        $this->update($prevCategory['id'], ['order_num' => $category['order_num']]);
        
        return true;
    }
    
    public function moveDown(int $id): bool
    {
        $category = $this->find($id);
        if (!$category) return false;
        
        // Find next category
        $sql = "SELECT * FROM categories WHERE order_num > ? ORDER BY order_num ASC LIMIT 1";
        $nextCategory = $this->query($sql, [$category['order_num']])->fetch();
        
        if (!$nextCategory) return false;
        
        // Swap order numbers
        $this->update($id, ['order_num' => $nextCategory['order_num']]);
        $this->update($nextCategory['id'], ['order_num' => $category['order_num']]);
        
        return true;
    }
}
