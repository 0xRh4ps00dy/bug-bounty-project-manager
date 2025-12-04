<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Models\ChecklistItem;
use App\Models\Category;

class ChecklistController extends Controller
{
    private ChecklistItem $model;
    private Category $categoryModel;
    
    public function __construct()
    {
        $this->model = new ChecklistItem();
        $this->categoryModel = new Category();
    }
    
    public function index(): void
    {
        $categoryId = $this->input('category_id');
        
        if ($categoryId) {
            $items = $this->model->getByCategory((int) $categoryId);
        } else {
            $items = $this->model->getAllWithCategory();
        }
        
        $categories = $this->categoryModel->all();
        
        if ($this->isAjax()) {
            $this->json($items);
        }
        
        $this->view('checklist.index', [
            'items' => $items,
            'categories' => $categories,
            'selectedCategory' => $categoryId
        ]);
    }
    
    public function store(): void
    {
        $data = [
            'category_id' => (int) $this->input('category_id'),
            'title' => trim($this->input('title')),
            'description' => trim($this->input('description', '')),
            'order_num' => (int) $this->input('order_num', 0)
        ];
        
        try {
            $id = $this->model->create($data);
            
            if ($this->isAjax()) {
                $this->json(['success' => true, 'id' => $id], 201);
            }
            
            $_SESSION['flash_message'] = 'Checklist item created successfully';
            $this->redirect('/checklist');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/checklist');
        }
    }
    
    public function update(int $id): void
    {
        $data = [
            'category_id' => (int) $this->input('category_id'),
            'title' => trim($this->input('title')),
            'description' => trim($this->input('description', '')),
            'order_num' => (int) $this->input('order_num', 0)
        ];
        
        try {
            $this->model->update($id, $data);
            
            if ($this->isAjax()) {
                $this->json(['success' => true]);
            }
            
            $_SESSION['flash_message'] = 'Checklist item updated successfully';
            $this->redirect('/checklist');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/checklist');
        }
    }
    
    public function destroy(int $id): void
    {
        try {
            $this->model->delete($id);
            
            if ($this->isAjax()) {
                $this->json(['success' => true]);
            }
            
            $_SESSION['flash_message'] = 'Checklist item deleted successfully';
            $this->redirect('/checklist');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/checklist');
        }
    }
    
    public function moveUp(int $id): void
    {
        try {
            $success = $this->model->moveUp($id);
            
            if ($this->isAjax()) {
                $this->json(['success' => $success]);
            }
            
            if ($success) {
                $_SESSION['flash_message'] = 'Item moved up';
            }
            $this->redirect('/checklist');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/checklist');
        }
    }
    
    public function moveDown(int $id): void
    {
        try {
            $success = $this->model->moveDown($id);
            
            if ($this->isAjax()) {
                $this->json(['success' => $success]);
            }
            
            if ($success) {
                $_SESSION['flash_message'] = 'Item moved down';
            }
            $this->redirect('/checklist');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/checklist');
        }
    }
}
