<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Models\Category;

class CategoryController extends Controller
{
    private Category $model;
    
    public function __construct()
    {
        $this->model = new Category();
    }
    
    public function index(): void
    {
        $categories = $this->model->getWithItemCount();
        
        if ($this->isAjax()) {
            $this->json($categories);
        }
        
        $this->view('categories.index', ['categories' => $categories]);
    }
    
    public function store(): void
    {
        $data = [
            'name' => trim($this->input('name')),
            'description' => trim($this->input('description', '')),
            'order_num' => (int) $this->input('order_num', 0)
        ];
        
        try {
            $id = $this->model->create($data);
            
            if ($this->isAjax()) {
                $this->json(['success' => true, 'id' => $id], 201);
            }
            
            $_SESSION['flash_message'] = 'Category created successfully';
            $this->redirect('/categories');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/categories');
        }
    }
    
    public function update(int $id): void
    {
        $data = [
            'name' => trim($this->input('name')),
            'description' => trim($this->input('description', '')),
            'order_num' => (int) $this->input('order_num', 0)
        ];
        
        try {
            $this->model->update($id, $data);
            
            if ($this->isAjax()) {
                $this->json(['success' => true]);
            }
            
            $_SESSION['flash_message'] = 'Category updated successfully';
            $this->redirect('/categories');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/categories');
        }
    }
    
    public function destroy(int $id): void
    {
        try {
            $this->model->delete($id);
            
            if ($this->isAjax()) {
                $this->json(['success' => true]);
            }
            
            $_SESSION['flash_message'] = 'Category deleted successfully';
            $this->redirect('/categories');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/categories');
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
                $_SESSION['flash_message'] = 'Category moved up';
            }
            $this->redirect('/categories');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/categories');
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
                $_SESSION['flash_message'] = 'Category moved down';
            }
            $this->redirect('/categories');
        } catch (\Exception $e) {
            if ($this->isAjax()) {
                $this->json(['error' => $e->getMessage()], 500);
            }
            
            $_SESSION['flash_error'] = $e->getMessage();
            $this->redirect('/categories');
        }
    }
}
