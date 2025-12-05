<?php $active = 'checklist'; $title = 'Elementos de Lista de Verificación - Bug Bounty Project Manager'; ?>

<div class="container">
    <div class="d-flex justify-content-between align-items-center mb-4 flex-column flex-md-row gap-2">
        <h1 class="mb-0"><i class="bi bi-list-check"></i> Lista de Verificación</h1>
        <button class="btn btn-primary flex-shrink-0" data-bs-toggle="modal" data-bs-target="#createModal">
            <i class="bi bi-plus-circle"></i> Nuevo
        </button>
    </div>
    
    <div class="mb-3">
        <select class="form-select form-select-sm" onchange="window.location.href='/checklist?category_id=' + this.value">
            <option value="">Todas las Categorías</option>
            <?php foreach ($categories as $cat): ?>
                <option value="<?= $cat['id'] ?>" <?= ($selectedCategory == $cat['id']) ? 'selected' : '' ?>>
                    <?= htmlspecialchars($cat['name']) ?>
                </option>
            <?php endforeach; ?>
        </select>
    </div>
    
    <?php if (empty($items)): ?>
        <div class="alert alert-info">
            No se encontraron elementos de lista de verificación.
        </div>
    <?php else: ?>
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0"><i class="bi bi-list-check"></i> Elementos</h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0 table-sm">
                        <thead>
                            <tr>
                                <th class="d-none d-md-table-cell" style="width: 50px;">Orden</th>
                                <th class="d-none d-lg-table-cell" style="width: 100px;">Categoría</th>
                                <th style="max-width: 100px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">Título</th>
                                <th class="d-none d-xl-table-cell">Descripción</th>
                                <th style="width: 90px; white-space: nowrap;">Acciones</th>
                            </tr>
                        </thead>
                <tbody>
                    <?php foreach ($items as $index => $item): ?>
                        <tr>
                            <td class="d-none d-md-table-cell text-center">
                                <span class="badge bg-primary"><?= $item['order_num'] ?? 0 ?></span>
                            </td>
                            <td class="d-none d-lg-table-cell">
                                <span class="badge bg-secondary text-truncate d-inline-block" style="max-width: 120px;">
                                    <?= htmlspecialchars($item['category_name'] ?? '') ?>
                                </span>
                            </td>
                            <td>
                                <strong class="text-truncate d-block"><?= htmlspecialchars($item['title']) ?></strong>
                                <small class="text-muted d-lg-none text-truncate d-block">
                                    <?= htmlspecialchars($item['category_name'] ?? '') ?>
                                </small>
                            </td>
                            <td class="d-none d-xl-table-cell">
                                <small class="text-muted text-truncate d-block">
                                    <?php 
                                    $desc = $item['description'] ?? '';
                                    echo htmlspecialchars(strlen($desc) > 60 ? substr($desc, 0, 60) . '...' : $desc);
                                    ?>
                                </small>
                            </td>
                            <td>
                                <div class="btn-group btn-group-sm gap-1" role="group">
                                    <!-- Move buttons -->
                                    <div class="btn-group btn-group-sm d-none d-md-inline-flex">
                                        <form method="POST" action="/checklist/<?= $item['id'] ?>/move-up" style="display: inline;">
                                            <button type="submit" 
                                                    class="btn btn-outline-secondary py-0 px-1" 
                                                    title="Subir"
                                                    <?= $index === 0 || ($index > 0 && $items[$index-1]['category_id'] !== $item['category_id']) ? 'disabled' : '' ?>>
                                                <i class="bi bi-arrow-up"></i>
                                            </button>
                                        </form>
                                        <form method="POST" action="/checklist/<?= $item['id'] ?>/move-down" style="display: inline;">
                                            <button type="submit" 
                                                    class="btn btn-outline-secondary py-0 px-1" 
                                                    title="Bajar"
                                                    <?= $index === count($items) - 1 || ($index < count($items) - 1 && $items[$index+1]['category_id'] !== $item['category_id']) ? 'disabled' : '' ?>>
                                                <i class="bi bi-arrow-down"></i>
                                            </button>
                                        </form>
                                    </div>
                                    
                                    <!-- Edit/Delete buttons -->
                                    <button class="btn btn-outline-warning py-0 px-1" 
                                            onclick="editItem(<?= htmlspecialchars(json_encode($item)) ?>)"
                                            title="Editar">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <button class="btn btn-outline-danger py-0 px-1 btn-delete" 
                                            data-url="/checklist/<?= $item['id'] ?>"
                                            data-confirm="¿Eliminar este elemento?"
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

<!-- Create Modal -->
<div class="modal fade" id="createModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form action="/checklist" method="POST" class="ajax-form" data-redirect="/checklist">
                <div class="modal-header">
                    <h5 class="modal-title">Nuevo Elemento de Lista de Verificación</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Categoría *</label>
                        <select name="category_id" class="form-select" required>
                            <option value="">Selecciona una categoría...</option>
                            <?php foreach ($categories as $cat): ?>
                                <option value="<?= $cat['id'] ?>"><?= htmlspecialchars($cat['name']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Título *</label>
                        <input type="text" name="title" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Descripción</label>
                        <textarea name="description" class="form-control" rows="8" placeholder="Escribe la descripción del elemento..."></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Orden</label>
                        <input type="number" name="order_num" class="form-control" value="0">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Crear Elemento</button>
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
                    <h5 class="modal-title">Editar Elemento de Lista de Verificación</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Categoría *</label>
                        <select name="category_id" id="edit_category_id" class="form-select" required>
                            <?php foreach ($categories as $cat): ?>
                                <option value="<?= $cat['id'] ?>"><?= htmlspecialchars($cat['name']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Título *</label>
                        <input type="text" name="title" id="edit_title" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Descripción</label>
                        <textarea name="description" id="edit_description" class="form-control" rows="8" placeholder="Escribe la descripción del elemento..."></textarea>
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
