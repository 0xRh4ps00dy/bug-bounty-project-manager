<?php $active = 'projects'; $title = htmlspecialchars($project['name']) . ' - Bug Bounty Project Manager'; ?>

<div class="container">
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="/projects">Proyectos</a></li>
            <li class="breadcrumb-item active"><?= htmlspecialchars($project['name']) ?></li>
        </ol>
    </nav>
    
    <div class="card mb-4">
        <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <h1 class="mb-3"><?= htmlspecialchars($project['name']) ?></h1>
                    <p class="text-muted"><?= htmlspecialchars($project['description'] ?? '') ?></p>
                </div>
                <span class="badge bg-<?= $project['status'] === 'active' ? 'success' : 'secondary' ?> fs-6">
                    <?= htmlspecialchars($project['status'] ?? 'active') ?>
                </span>
            </div>
            
            <div class="row mt-4">
                <div class="col-md-4">
                    <div class="text-center p-3 bg-light rounded">
                        <h3 class="text-primary"><?= $project['target_count'] ?? 0 ?></h3>
                        <small class="text-muted">Total de Objetivos</small>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="text-center p-3 bg-light rounded">
                        <h3 class="text-success"><?= round($project['avg_progress'] ?? 0) ?>%</h3>
                        <small class="text-muted">Progreso Promedio</small>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="text-center p-3 bg-light rounded">
                        <h3 class="text-info"><?= date('Y-m-d', strtotime($project['created_at'])) ?></h3>
                        <small class="text-muted">Creado</small>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="mb-0"><i class="bi bi-bullseye"></i> Objetivos</h5>
            <button class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#createTargetModal">
                <i class="bi bi-plus-circle"></i> Agregar Objetivo
            </button>
        </div>
        <div class="card-body p-0">
            <?php if (empty($project['targets'])): ?>
                <p class="text-muted p-3">Sin objetivos aún. ¡Agrega tu primer objetivo!</p>
            <?php else: ?>
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Objetivo</th>
                                <th>Tipo</th>
                                <th>Descripción</th>
                                <th>Estado</th>
                                <th>Progreso</th>
                                <th class="actions-cell">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($project['targets'] as $target): ?>
                                <tr class="clickable-row" data-href="/targets/<?= $target['id'] ?>" style="cursor: pointer;">
                                    <td>
                                        <?php if ($target['target_type'] === 'url'): ?>
                                            <a href="<?= htmlspecialchars($target['target']) ?>" target="_blank" onclick="event.stopPropagation();"><?= htmlspecialchars($target['target']) ?></a>
                                        <?php else: ?>
                                            <?= htmlspecialchars($target['target']) ?>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <span class="badge bg-<?= $target['target_type'] === 'url' ? 'primary' : ($target['target_type'] === 'ip' ? 'info' : 'secondary') ?>">
                                            <?= ucfirst(htmlspecialchars($target['target_type'])) ?>
                                        </span>
                                    </td>
                                    <td><?= htmlspecialchars($target['description'] ?? '') ?></td>
                                    <td>
                                        <span class="badge bg-<?= $target['status'] === 'active' ? 'success' : 'secondary' ?>">
                                            <?= htmlspecialchars($target['status'] ?? 'active') ?>
                                        </span>
                                    </td>
                                    <td>
                                        <div class="progress" style="width: 100px;">
                                            <div class="progress-bar" role="progressbar" 
                                                 style="width: <?= $target['progress'] ?? 0 ?>%"
                                                 aria-valuenow="<?= $target['progress'] ?? 0 ?>" 
                                                 aria-valuemin="0" aria-valuemax="100">
                                                <?= round($target['progress'] ?? 0) ?>%
                                            </div>
                                        </div>
                                    </td>
                                    <td class="actions-cell">
                                        <div class="btn-group btn-group-sm">
                                            <a href="/targets/<?= $target['id'] ?>" 
                                               class="btn btn-info" 
                                               title="Ver">
                                                <i class="bi bi-eye"></i>
                                            </a>
                                            <button class="btn btn-warning" 
                                                    type="button"
                                                    onclick="editTarget(<?= htmlspecialchars(json_encode($target)) ?>, <?= $project['id'] ?>)"
                                                    title="Editar">
                                                <i class="bi bi-pencil"></i>
                                            </button>
                                            <button class="btn btn-danger btn-delete" 
                                                    data-url="/targets/<?= $target['id'] ?>"
                                                    data-confirm="¿Eliminar este objetivo?"
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
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- Create Target Modal -->
<div class="modal fade" id="createTargetModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form action="/targets" method="POST" class="ajax-form" data-redirect="/projects/<?= $project['id'] ?>">
                <input type="hidden" name="project_id" value="<?= $project['id'] ?>">
                <div class="modal-header">
                    <h5 class="modal-title">Nuevo Objetivo</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Nombre *</label>
                        <input type="text" name="name" class="form-control" placeholder="ej. Sitio Web Principal, Servidor API" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Tipo de Objetivo *</label>
                        <select name="target_type" class="form-select" id="projectTargetType" required>
                            <option value="url" selected>URL</option>
                            <option value="ip">Dirección IP</option>
                            <option value="domain">Dominio</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Objetivo *</label>
                        <input type="text" name="target" class="form-control" id="projectTargetInput" placeholder="https://example.com" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Descripción</label>
                        <textarea name="description" class="form-control" rows="3"></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Estado</label>
                        <select name="status" class="form-select">
                            <option value="active">Activo</option>
                            <option value="completed">Completado</option>
                            <option value="archived">Archivado</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Crear Objetivo</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Edit Target Modal -->
<div class="modal fade" id="editTargetModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form id="editTargetForm" method="POST" class="ajax-form" data-method="PUT" data-redirect="/projects/<?= $project['id'] ?>">
                <div class="modal-header">
                    <h5 class="modal-title">Editar Objetivo</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Nombre *</label>
                        <input type="text" name="name" id="edit_target_name" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Tipo de Objetivo *</label>
                        <select name="target_type" class="form-select" id="editProjectTargetType" required>
                            <option value="url">URL</option>
                            <option value="ip">Dirección IP</option>
                            <option value="domain">Dominio</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Objetivo *</label>
                        <input type="text" name="target" class="form-control" id="editProjectTargetInput" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Descripción</label>
                        <textarea name="description" class="form-control" id="edit_target_description" rows="3"></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Estado</label>
                        <select name="status" class="form-select" id="edit_target_status">
                            <option value="active">Activo</option>
                            <option value="completed">Completado</option>
                            <option value="archived">Archivado</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Actualizar Objetivo</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function editTarget(target, projectId) {
    document.getElementById('editTargetForm').action = '/targets/' + target.id;
    document.getElementById('edit_target_name').value = target.name;
    document.getElementById('editProjectTargetType').value = target.target_type;
    document.getElementById('editProjectTargetInput').value = target.target;
    document.getElementById('edit_target_description').value = target.description || '';
    document.getElementById('edit_target_status').value = target.status;
    
    const modal = new bootstrap.Modal(document.getElementById('editTargetModal'));
    modal.show();
}

document.addEventListener('DOMContentLoaded', function() {
    const typeSelect = document.getElementById('projectTargetType');
    const targetInput = document.getElementById('projectTargetInput');
    const editTypeSelect = document.getElementById('editProjectTargetType');
    const editTargetInput = document.getElementById('editProjectTargetInput');
    
    function updateTargetPlaceholder(typeElem, inputElem) {
        const type = typeElem.value;
        
        const placeholders = {
            'url': 'https://example.com or https://api.example.com/endpoint',
            'ip': '192.168.1.1 or 2001:0db8:85a3:0000:0000:8a2e:0370:7334',
            'domain': 'example.com or subdomain.example.co.uk'
        };
        
        inputElem.placeholder = placeholders[type] || 'Enter target value';
        inputElem.type = type === 'url' ? 'url' : 'text';
    }
    
    // Create modal
    if (typeSelect) {
        typeSelect.addEventListener('change', () => updateTargetPlaceholder(typeSelect, targetInput));
        updateTargetPlaceholder(typeSelect, targetInput);
    }
    
    // Edit modal
    if (editTypeSelect) {
        editTypeSelect.addEventListener('change', () => updateTargetPlaceholder(editTypeSelect, editTargetInput));
    }
});
</script>

