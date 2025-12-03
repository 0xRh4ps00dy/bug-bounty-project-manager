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
}
