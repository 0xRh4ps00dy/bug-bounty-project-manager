<?php $active = 'targets'; $title = 'Objetivos - Bug Bounty Project Manager'; ?>

<div class="container">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1><i class="bi bi-bullseye"></i> Objetivos</h1>
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createModal">
            <i class="bi bi-plus-circle"></i> Nuevo Objetivo
        </button>
    </div>
    
    <?php if (empty($targets)): ?>
        <div class="alert alert-info">
            No se encontraron objetivos. ¡Crea tu primer objetivo!
        </div>
    <?php else: ?>
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0"><i class="bi bi-bullseye"></i> Objetivos</h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Nombre</th>
                                <th>Proyecto</th>
                                <th>Objetivo</th>
                                <th>Tipo</th>
                                <th>Estado</th>
                                <th>Progreso</th>
                                <th class="actions-cell">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($targets as $target): ?>
                                <tr class="clickable-row" data-href="/targets/<?= $target['id'] ?>" style="cursor: pointer;">
                                    <td><strong><?= htmlspecialchars($target['name']) ?></strong></td>
                                    <td><?= htmlspecialchars($target['project_name'] ?? $target['project_id']) ?></td>
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
                                    <td>
                                        <span class="badge bg-<?= $target['status'] === 'active' ? 'success' : 'secondary' ?>">
                                            <?= htmlspecialchars($target['status'] ?? 'active') ?>
                                        </span>
                                    </td>
                                    <td>
                                        <div class="progress" style="width: 150px; height: 25px;">
                                            <div class="progress-bar" style="width: <?= $target['progress'] ?? 0 ?>%">
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
            </div>
        </div>
    <?php endif; ?>
</div>

<!-- Modal Crear -->
<div class="modal fade" id="createModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form action="/targets" method="POST" class="ajax-form" data-redirect="/targets">
                <div class="modal-header">
                    <h5 class="modal-title">Nuevo Objetivo</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Proyecto *</label>
                        <select name="project_id" class="form-select" required>
                            <option value="">Selecciona un proyecto...</option>
                            <?php foreach ($projects as $project): ?>
                                <option value="<?= $project['id'] ?>"><?= htmlspecialchars($project['name']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Nombre *</label>
                        <input type="text" name="name" class="form-control" placeholder="ej. Sitio Web Principal, Servidor API" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Tipo de Objetivo *</label>
                        <select name="target_type" class="form-select" id="targetType" required>
                            <option value="">Selecciona tipo...</option>
                            <option value="url" selected>URL</option>
                            <option value="ip">Dirección IP</option>
                            <option value="domain">Dominio</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Objetivo *</label>
                        <input type="text" name="target" class="form-control" id="targetInput" placeholder="https://example.com" required>
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

<script>
document.addEventListener('DOMContentLoaded', function() {
    const typeSelect = document.getElementById('targetType');
    const targetInput = document.getElementById('targetInput');
    
    function updateTargetPlaceholder() {
        const type = typeSelect.value;
        
        const placeholders = {
            'url': 'https://example.com or https://api.example.com/endpoint',
            'ip': '192.168.1.1 or 2001:0db8:85a3:0000:0000:8a2e:0370:7334',
            'domain': 'example.com or subdomain.example.co.uk'
        };
        
        targetInput.placeholder = placeholders[type] || 'Enter target value';
        targetInput.type = type === 'url' ? 'url' : 'text';
    }
    
    // Add event listener
    if (typeSelect) {
        typeSelect.addEventListener('change', updateTargetPlaceholder);
        // Initialize on page load
        updateTargetPlaceholder();
    }
});
</script>
