<?php $active = 'categories'; $title = 'Categorías - Bug Bounty Project Manager'; ?>

<div class="container">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1><i class="bi bi-tags"></i> Categorías</h1>
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createModal">
            <i class="bi bi-plus-circle"></i> Nueva Categoría
        </button>
    </div>
    
    <?php if (empty($categories)): ?>
        <div class="alert alert-info">
            No se encontraron categorías.
        </div>
    <?php else: ?>
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0"><i class="bi bi-tags"></i> Categorías</h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th style="width: 100px;">Orden</th>
                                <th>Nombre</th>
                                <th>Descripción</th>
                                <th>Elementos</th>
                                <th style="width: 250px;">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($categories as $index => $category): ?>
                                <tr>
                                    <td>
                                        <span class="badge bg-primary"><?= $category['order_num'] ?? 0 ?></span>
                                    </td>
                                    <td><strong><?= htmlspecialchars($category['name']) ?></strong></td>
                                    <td><?= htmlspecialchars($category['description'] ?? '') ?></td>
                                    <td><span class="badge bg-info"><?= $category['item_count'] ?? 0 ?></span></td>
                                    <td class="actions-cell">
                                        <div class="btn-group btn-group-sm me-2">
                                            <form method="POST" action="/categories/<?= $category['id'] ?>/move-up" style="display: inline;">
                                                <button type="submit" 
                                                        class="btn btn-secondary" 
                                                        title="Subir"
                                                        <?= $index === 0 ? 'disabled' : '' ?>>
                                                    <i class="bi bi-arrow-up"></i>
                                                </button>
                                            </form>
                                            <form method="POST" action="/categories/<?= $category['id'] ?>/move-down" style="display: inline;">
                                                <button type="submit" 
                                                        class="btn btn-secondary" 
                                                        title="Bajar"
                                                        <?= $index === count($categories) - 1 ? 'disabled' : '' ?>>
                                                    <i class="bi bi-arrow-down"></i>
                                                </button>
                                            </form>
                                        </div>
                                        <div class="btn-group btn-group-sm">
                                            <button class="btn btn-warning" 
                                                    onclick="editCategory(<?= htmlspecialchars(json_encode($category)) ?>)"
                                                    title="Editar">
                                                <i class="bi bi-pencil"></i>
                                            </button>
                                            <button class="btn btn-danger btn-delete" 
                                                    data-url="/categories/<?= $category['id'] ?>"
                                                    data-confirm="¿Eliminar categoría '<?= htmlspecialchars($category['name']) ?>'?"
                                                    title="Eliminar">
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

<!-- Modal Crear -->
<div class="modal fade" id="createModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form action="/categories" method="POST" class="ajax-form" data-redirect="/categories">
                <div class="modal-header">
                    <h5 class="modal-title">Nueva Categoría</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Nombre *</label>
                        <input type="text" name="name" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Descripción</label>
                        <textarea name="description" class="form-control" rows="3"></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Orden</label>
                        <input type="number" name="order_num" class="form-control" value="0">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Crear Categoría</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Modal Editar -->
<div class="modal fade" id="editModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form id="editForm" method="POST" class="ajax-form" data-method="PUT" data-redirect="/categories">
                <div class="modal-header">
                    <h5 class="modal-title">Editar Categoría</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Nombre *</label>
                        <input type="text" name="name" id="edit_name" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Descripción</label>
                        <textarea name="description" id="edit_description" class="form-control" rows="3"></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Orden</label>
                        <input type="number" name="order_num" id="edit_order_num" class="form-control">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Guardar Cambios</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function editCategory(category) {
    document.getElementById('editForm').action = '/categories/' + category.id;
    document.getElementById('edit_name').value = category.name;
    document.getElementById('edit_description').value = category.description || '';
    document.getElementById('edit_order_num').value = category.order_num || 0;
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
                    alert('Failed to reorder category');
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
