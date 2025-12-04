<?php $active = 'checklist'; $title = 'Checklist Items - Bug Bounty Project Manager'; ?>

<div class="container">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1><i class="bi bi-list-check"></i> Checklist Items</h1>
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createModal">
            <i class="bi bi-plus-circle"></i> New Item
        </button>
    </div>
    
    <div class="mb-3">
        <select class="form-select" onchange="window.location.href='/checklist?category_id=' + this.value">
            <option value="">All Categories</option>
            <?php foreach ($categories as $cat): ?>
                <option value="<?= $cat['id'] ?>" <?= ($selectedCategory == $cat['id']) ? 'selected' : '' ?>>
                    <?= htmlspecialchars($cat['name']) ?>
                </option>
            <?php endforeach; ?>
        </select>
    </div>
    
    <?php if (empty($items)): ?>
        <div class="alert alert-info">
            No checklist items found.
        </div>
    <?php else: ?>
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0"><i class="bi bi-list-check"></i> Checklist Items</h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th style="width: 100px;">Order</th>
                                <th>Category</th>
                                <th>Title</th>
                                <th>Description</th>
                                <th style="width: 200px;">Actions</th>
                            </tr>
                        </thead>
                <tbody>
                    <?php foreach ($items as $index => $item): ?>
                        <tr>
                            <td>
                                <span class="badge bg-primary"><?= $item['order_num'] ?? 0 ?></span>
                            </td>
                            <td><span class="badge bg-secondary"><?= htmlspecialchars($item['category_name'] ?? '') ?></span></td>
                            <td><strong><?= htmlspecialchars($item['title']) ?></strong></td>
                            <td>
                                <?php 
                                $desc = $item['description'] ?? '';
                                echo htmlspecialchars(strlen($desc) > 80 ? substr($desc, 0, 80) . '...' : $desc);
                                ?>
                            </td>
                            <td>
                                <div class="btn-group btn-group-sm me-2">
                                    <form method="POST" action="/checklist/<?= $item['id'] ?>/move-up" style="display: inline;">
                                        <button type="submit" 
                                                class="btn btn-secondary" 
                                                title="Move Up"
                                                <?= $index === 0 || ($index > 0 && $items[$index-1]['category_id'] !== $item['category_id']) ? 'disabled' : '' ?>>
                                            <i class="bi bi-arrow-up"></i>
                                        </button>
                                    </form>
                                    <form method="POST" action="/checklist/<?= $item['id'] ?>/move-down" style="display: inline;">
                                        <button type="submit" 
                                                class="btn btn-secondary" 
                                                title="Move Down"
                                                <?= $index === count($items) - 1 || ($index < count($items) - 1 && $items[$index+1]['category_id'] !== $item['category_id']) ? 'disabled' : '' ?>>
                                            <i class="bi bi-arrow-down"></i>
                                        </button>
                                    </form>
                                </div>
                                <div class="btn-group btn-group-sm">
                                    <button class="btn btn-warning" 
                                            onclick="editItem(<?= htmlspecialchars(json_encode($item)) ?>)"
                                            title="Edit">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <button class="btn btn-danger btn-delete" 
                                            data-url="/checklist/<?= $item['id'] ?>"
                                            data-confirm="Delete this item?"
                                            title="Delete">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
                </div>
            </div>
        </div>
    <?php endif; ?>
</div>

<!-- Create Modal -->
<div class="modal fade" id="createModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form action="/checklist" method="POST" class="ajax-form" data-redirect="/checklist">
                <div class="modal-header">
                    <h5 class="modal-title">New Checklist Item</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Category *</label>
                        <select name="category_id" class="form-select" required>
                            <option value="">Select category...</option>
                            <?php foreach ($categories as $cat): ?>
                                <option value="<?= $cat['id'] ?>"><?= htmlspecialchars($cat['name']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Title *</label>
                        <input type="text" name="title" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Description</label>
                        <textarea name="description" class="form-control" rows="3"></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Order</label>
                        <input type="number" name="order_num" class="form-control" value="0">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Create Item</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Edit Modal -->
<div class="modal fade" id="editModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form id="editForm" method="POST" class="ajax-form" data-method="PUT" data-redirect="/checklist">
                <div class="modal-header">
                    <h5 class="modal-title">Edit Checklist Item</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Category *</label>
                        <select name="category_id" id="edit_category_id" class="form-select" required>
                            <?php foreach ($categories as $cat): ?>
                                <option value="<?= $cat['id'] ?>"><?= htmlspecialchars($cat['name']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Title *</label>
                        <input type="text" name="title" id="edit_title" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Description</label>
                        <textarea name="description" id="edit_description" class="form-control" rows="3"></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Order</label>
                        <input type="number" name="order_num" id="edit_order_num" class="form-control">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function editItem(item) {
    document.getElementById('editForm').action = '/checklist/' + item.id;
    document.getElementById('edit_category_id').value = item.category_id;
    document.getElementById('edit_title').value = item.title;
    document.getElementById('edit_description').value = item.description || '';
    document.getElementById('edit_order_num').value = item.order_num || 0;
    new bootstrap.Modal(document.getElementById('editModal')).show();
}

// Handle move buttons with AJAX
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('form[action*="/move-"]').forEach(form => {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const button = this.querySelector('button[type="submit"]');
            button.disabled = true;
            
            fetch(this.action, {
                method: 'POST',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    window.location.reload();
                } else {
                    button.disabled = false;
                    alert('Failed to reorder item');
                }
            })
            .catch(error => {
                button.disabled = false;
                console.error('Error:', error);
            });
        });
    });
});
</script>
