<?php $active = 'categories'; $title = 'Categorías - Bug Bounty Project Manager'; ?>

<div class="container">
    <div class="d-flex justify-content-between align-items-center mb-4 flex-column flex-md-row gap-2">
        <h1 class="mb-0"><i class="bi bi-tags"></i> Categorías</h1>
        <button class="btn btn-primary flex-shrink-0" data-bs-toggle="modal" data-bs-target="#createModal">
            <i class="bi bi-plus-circle"></i> Nueva
        </button>
    </div>
    
    <?php if (empty($categories)): ?>
        <div class="alert alert-info">
            No se encontraron categorías.
        </div>
    <?php else: ?>
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0"><i class="bi bi-tags"></i> Categorías</h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0" style="table-layout: fixed; width: 100%;">
                        <thead class="table-light">
                            <tr>
                                <th style="width: 20%;">Nombre</th>
                                <th class="d-none d-lg-table-cell" style="width: 50%;">Descripción</th>
                                <th class="text-center" style="width: 15%;">Items</th>
                                <th style="width: 15%;" class="text-center">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($categories as $index => $category): ?>
                                <tr>
                                    <td style="overflow: hidden;">
                                        <strong class="d-block text-truncate"><?= htmlspecialchars($category['name']) ?></strong>
                                        <small class="text-muted d-lg-none d-block" style="white-space: normal; line-height: 1.4;">
                                            <?= htmlspecialchars(strlen($category['description'] ?? '') > 60 ? substr($category['description'] ?? '', 0, 60) . '...' : ($category['description'] ?? '')) ?>
                                        </small>
                                    </td>
                                    <td class="d-none d-lg-table-cell" style="overflow: hidden; text-overflow: ellipsis;">
                                        <small class="text-muted d-block" style="white-space: normal; line-height: 1.4;">
                                            <?= htmlspecialchars($category['description'] ?? '') ?>
                                        </small>
                                    </td>
                                    <td class="text-center">
                                        <span class="badge bg-info"><?= $category['item_count'] ?? 0 ?></span>
                                    </td>
                                    <td class="text-center">
                                        <div class="btn-group btn-group-sm" role="group">
                                            <button class="btn btn-secondary d-none d-md-inline-block btn-move-up" 
                                                    data-url="/categories/<?= $category['id'] ?>/move-up"
                                                    title="Subir"
                                                    <?= $index === 0 ? 'disabled' : '' ?>>
                                                <i class="bi bi-arrow-up"></i>
                                            </button>
                                            <button class="btn btn-secondary d-none d-md-inline-block btn-move-down" 
                                                    data-url="/categories/<?= $category['id'] ?>/move-down"
                                                    title="Bajar"
                                                    <?= $index === count($categories) - 1 ? 'disabled' : '' ?>>
                                                <i class="bi bi-arrow-down"></i>
                                            </button>
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
    document.querySelectorAll('.btn-move-up, .btn-move-down').forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            
            const url = this.dataset.url;
            this.disabled = true;
            
            fetch(url, {
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
                    this.disabled = false;
                    alert('Failed to reorder category');
                }
            })
            .catch(error => {
                this.disabled = false;
                console.error('Error:', error);
            });
        });
    });
});
</script>
