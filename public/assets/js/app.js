// Modern Bug Bounty Project Manager - JavaScript Application

class BBPM {
    constructor() {
        this.baseUrl = window.location.origin;
        this.init();
    }
    
    init() {
        // Add event listeners
        this.attachEventListeners();
    }
    
    attachEventListeners() {
        // Form submissions
        document.addEventListener('submit', (e) => {
            if (e.target.classList.contains('ajax-form')) {
                e.preventDefault();
                this.handleFormSubmit(e.target);
            }
        });
        
        // Delete buttons - handle with highest priority
        document.addEventListener('click', (e) => {
            const deleteBtn = e.target.closest('.btn-delete');
            if (deleteBtn) {
                e.preventDefault();
                e.stopPropagation();
                e.stopImmediatePropagation();
                this.handleDelete(deleteBtn);
                return false;
            }
        }, true);
        
        // Prevent clicks on action cells from triggering row navigation
        document.addEventListener('click', (e) => {
            if (e.target.closest('.actions-cell')) {
                e.stopPropagation();
                e.stopImmediatePropagation();
            }
        }, true);
        
        // Handle clickable rows
        document.addEventListener('click', (e) => {
            const row = e.target.closest('tr.clickable-row');
            if (row && !e.target.closest('.actions-cell')) {
                const href = row.dataset.href;
                if (href) {
                    window.location.href = href;
                }
            }
        });
        
        // Toggle checklist item (use change event instead of click)
        document.addEventListener('change', (e) => {
            if (e.target.classList.contains('checklist-toggle')) {
                this.toggleChecklistItem(e.target);
            }
        });
        
        // Note updates (debounced)
        document.addEventListener('blur', (e) => {
            if (e.target.classList.contains('checklist-notes')) {
                this.updateNotes(e.target);
            }
        }, true);
        
        // Check all category
        document.addEventListener('click', (e) => {
            const btn = e.target.closest('.check-all-category');
            if (btn) {
                e.preventDefault();
                e.stopPropagation();
                this.checkAllCategory(btn);
            }
        });
        
        // Toggle collapse icon
        document.addEventListener('shown.bs.collapse', (e) => {
            if (e.target.classList.contains('category-items')) {
                const header = e.target.previousElementSibling;
                const icon = header.querySelector('.collapse-icon');
                if (icon) icon.classList.replace('bi-chevron-down', 'bi-chevron-up');
            }
        });
        
        document.addEventListener('hidden.bs.collapse', (e) => {
            if (e.target.classList.contains('category-items')) {
                const header = e.target.previousElementSibling;
                const icon = header.querySelector('.collapse-icon');
                if (icon) icon.classList.replace('bi-chevron-up', 'bi-chevron-down');
            }
        });
    }
    
    async handleFormSubmit(form) {
        const formData = new FormData(form);
        const method = form.dataset.method || form.method.toUpperCase();
        const url = form.action;
        
        // Convert FormData to JSON
        const data = Object.fromEntries(formData.entries());
        
        try {
            this.showLoading(form);
            
            const response = await this.fetch(url, {
                method: method,
                body: JSON.stringify(data)
            });
            
            if (response.success) {
                this.showSuccess(response.message || 'Operation successful');
                
                // Reload or redirect
                setTimeout(() => {
                    if (form.dataset.redirect) {
                        window.location.href = form.dataset.redirect;
                    } else {
                        window.location.reload();
                    }
                }, 1000);
            } else {
                this.showError(response.error || 'Operation failed');
            }
        } catch (error) {
            this.showError(error.message);
        } finally {
            this.hideLoading(form);
        }
    }
    
    async handleDelete(btn) {
        const url = btn.dataset.url;
        const confirmMsg = btn.dataset.confirm || 'Are you sure you want to delete this item?';
        
        if (!confirm(confirmMsg)) {
            return;
        }
        
        try {
            this.showLoading(btn);
            
            const response = await this.fetch(url, {
                method: 'DELETE'
            });
            
            if (response.success) {
                this.showSuccess(response.message || 'Deleted successfully');
                
                // Remove element or reload
                setTimeout(() => {
                    const row = btn.closest('tr') || btn.closest('.card');
                    if (row) {
                        row.remove();
                    } else {
                        window.location.reload();
                    }
                }, 500);
            } else {
                this.showError(response.error || 'Delete failed');
            }
        } catch (error) {
            this.showError(error.message);
        } finally {
            this.hideLoading(btn);
        }
    }
    
    async toggleChecklistItem(checkbox) {
        const targetId = checkbox.dataset.targetId;
        const itemId = checkbox.dataset.itemId;
        const isChecked = checkbox.checked ? 1 : 0;
        
        const url = `/targets/${targetId}/checklist/${itemId}/toggle`;
        
        try {
            const response = await this.fetch(url, {
                method: 'POST',
                body: JSON.stringify({ is_checked: isChecked })
            });
            
            if (response.success) {
                // Update visual state
                const checklistItem = checkbox.closest('.checklist-item');
                if (checklistItem) {
                    if (isChecked) {
                        checklistItem.classList.add('checked');
                    } else {
                        checklistItem.classList.remove('checked');
                    }
                }
                
                // Update category counter
                const categorySection = checkbox.closest('.category-section');
                if (categorySection) {
                    this.updateCategoryCounter(categorySection);
                }
                
                // Update progress bar if exists
                this.updateProgress();
            } else {
                // Revert checkbox
                checkbox.checked = !checkbox.checked;
                this.showError(response.error || 'Error al cambiar estado');
            }
        } catch (error) {
            checkbox.checked = !checkbox.checked;
            this.showError(error.message);
        }
    }
    
    async updateNotes(textarea) {
        const targetId = textarea.dataset.targetId;
        const itemId = textarea.dataset.itemId;
        const notes = textarea.value.trim();
        
        const url = `/targets/${targetId}/checklist/${itemId}/notes`;
        
        try {
            const response = await this.fetch(url, {
                method: 'POST',
                body: JSON.stringify({ notes: notes })
            });
            
            if (response.success) {
                this.showSuccess('Notas actualizadas', 1000);
            } else {
                this.showError(response.error || 'Error al actualizar');
            }
        } catch (error) {
            this.showError(error.message);
        }
    }
    
    async checkAllCategory(btn) {
        const categoryId = btn.dataset.categoryId;
        const targetId = btn.dataset.targetId;
        
        const categorySection = document.querySelector(`[data-category-id="${categoryId}"]`);
        if (!categorySection) {
            this.showError('Sección de categoría no encontrada');
            return;
        }
        
        const checkboxes = categorySection.querySelectorAll('.checklist-toggle');
        
        // Determine if we should check all or uncheck all
        const checkedCount = categorySection.querySelectorAll('.checklist-toggle:checked').length;
        const allChecked = checkedCount === checkboxes.length;
        const newState = !allChecked;
        
        const confirmMsg = allChecked 
            ? '¿Desmarcar todos los elementos de esta categoría?' 
            : '¿Marcar todos los elementos de esta categoría como completados?';
        
        if (!confirm(confirmMsg)) {
            return;
        }
        
        try {
            this.showLoading(btn);
            
            // Toggle all items to the new state
            for (const checkbox of checkboxes) {
                if (checkbox.checked !== newState) {
                    const itemId = checkbox.dataset.itemId;
                    
                    const response = await this.fetch(`/targets/${targetId}/checklist/${itemId}/toggle`, {
                        method: 'POST',
                        body: JSON.stringify({ is_checked: newState ? 1 : 0 })
                    });
                    
                    if (response.success) {
                        checkbox.checked = newState;
                        const checklistItem = checkbox.closest('.checklist-item');
                        if (checklistItem) {
                            if (newState) {
                                checklistItem.classList.add('checked');
                            } else {
                                checklistItem.classList.remove('checked');
                            }
                        }
                    }
                }
            }
            
            // Update progress and category counter
            await this.updateProgress();
            
            // Wait a bit for DOM to update, then update the counter and button
            setTimeout(() => {
                this.updateCategoryCounter(categorySection);
            }, 100);
            
            this.showSuccess(allChecked ? 'Todos los elementos desmarcados' : 'Todos los elementos marcados correctamente');
        } catch (error) {
            this.showError('Error al cambiar elementos: ' + error.message);
        } finally {
            this.hideLoading(btn);
        }
    }
    
    updateCategoryCounter(categorySection) {
        const items = categorySection.querySelectorAll('.checklist-toggle');
        const checkedItems = categorySection.querySelectorAll('.checklist-toggle:checked');
        const counter = categorySection.querySelector('.category-header small');
        
        if (counter) {
            counter.textContent = `(${checkedItems.length}/${items.length})`;
        }
        
        // Update button text based on state
        const btn = categorySection.querySelector('.check-all-category');
        if (btn) {
            const allChecked = checkedItems.length === items.length && items.length > 0;
            
            // Save data attributes
            const categoryId = btn.dataset.categoryId;
            const targetId = btn.dataset.targetId;
            
            if (allChecked) {
                btn.innerHTML = '<i class="bi bi-x-circle me-1"></i>Desmarcar Todos';
                btn.classList.remove('btn-light');
                btn.classList.add('btn-outline-light');
                btn.title = 'Desmarcar todos los elementos';
            } else {
                btn.innerHTML = '<i class="bi bi-check-all me-1"></i>Marcar Todos';
                btn.classList.remove('btn-outline-light');
                btn.classList.add('btn-light');
                btn.title = 'Marcar todos como completados';
            }
            
            // Restore data attributes
            btn.dataset.categoryId = categoryId;
            btn.dataset.targetId = targetId;
        }
    }
    
    async updateProgress() {
        // Reload progress stats
        const progressContainer = document.querySelector('.progress[data-target-id]');
        if (!progressContainer) return;
        
        const targetId = progressContainer.dataset.targetId;
        if (!targetId) return;
        
        const progressBar = progressContainer.querySelector('.progress-bar');
        if (!progressBar) return;
        
        try {
            const response = await this.fetch(`/api/targets/${targetId}`);
            if (response.target) {
                progressBar.style.width = response.target.progress + '%';
                progressBar.textContent = Math.round(response.target.progress) + '%';
                
                const completedSpan = document.querySelector('.completed-count');
                if (completedSpan) {
                    completedSpan.textContent = response.target.completed_items;
                }
            }
        } catch (error) {
            console.error('Failed to update progress:', error);
        }
    }
    
    async fetch(url, options = {}) {
        const defaults = {
            headers: {
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            }
        };
        
        const config = { ...defaults, ...options };
        
        const response = await fetch(url, config);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        return await response.json();
    }
    
    showLoading(element) {
        const btn = element.tagName === 'FORM' 
            ? element.querySelector('[type="submit"]')
            : element;
        
        if (btn) {
            btn.disabled = true;
            btn.dataset.originalText = btn.innerHTML;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Loading...';
        }
    }
    
    hideLoading(element) {
        const btn = element.tagName === 'FORM'
            ? element.querySelector('[type="submit"]')
            : element;
        
        if (btn && btn.dataset.originalText) {
            btn.disabled = false;
            btn.innerHTML = btn.dataset.originalText;
        }
    }
    
    showSuccess(message, duration = 3000) {
        this.showToast(message, 'success', duration);
    }
    
    showError(message, duration = 5000) {
        this.showToast(message, 'danger', duration);
    }
    
    showToast(message, type = 'info', duration = 3000) {
        // Create toast container if doesn't exist
        let container = document.querySelector('.toast-container');
        if (!container) {
            container = document.createElement('div');
            container.className = 'toast-container position-fixed top-0 end-0 p-3';
            document.body.appendChild(container);
        }
        
        // Create toast
        const toast = document.createElement('div');
        toast.className = `toast align-items-center text-white bg-${type} border-0`;
        toast.setAttribute('role', 'alert');
        toast.innerHTML = `
            <div class="d-flex">
                <div class="toast-body">${message}</div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        `;
        
        container.appendChild(toast);
        
        // Show toast
        const bsToast = new bootstrap.Toast(toast, { delay: duration });
        bsToast.show();
        
        // Remove after hidden
        toast.addEventListener('hidden.bs.toast', () => {
            toast.remove();
        });
    }
}

// Initialize on DOMContentLoaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.bbpm = new BBPM();
    });
} else {
    window.bbpm = new BBPM();
}
