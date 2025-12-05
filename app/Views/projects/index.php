<?php $active = 'projects'; $title = 'Proyectos - Bug Bounty Project Manager'; ?>

<div class="container">
    <div class="d-flex justify-content-between align-items-center mb-4 flex-column flex-md-row gap-2">
        <h1 class="mb-0"><i class="bi bi-folder"></i> Proyectos</h1>
        <button class="btn btn-primary flex-shrink-0" data-bs-toggle="modal" data-bs-target="#createModal">
            <i class="bi bi-plus-circle"></i> Nuevo Proyecto
        </button>
    </div>
    
    <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="mb-0"><i class="bi bi-folder"></i> Proyectos</h5>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover mb-0 table-sm">
                    <thead>
                        <tr>
                            <th style="max-width: 100px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">Nombre</th>
                            <th class="d-none d-md-table-cell">Descripción</th>
                            <th>Estado</th>
                            <th class="d-none d-lg-table-cell">Objetivos</th>
                            <th class="d-none d-lg-table-cell">Progreso</th>
                            <th class="d-none d-md-table-cell">Creado</th>
                            <th class="actions-cell" style="width: 90px;">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($projects)): ?>
                            <tr>
                                <td colspan="7" class="text-center text-muted">No hay proyectos</td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($projects as $project): ?>
                                <tr class="clickable-row" data-href="/projects/<?= $project['id'] ?>" style="cursor: pointer;">
                                    <td>
                                        <strong class="text-truncate d-block"><?= htmlspecialchars($project['name']) ?></strong>
                                        <small class="text-muted d-md-none">
                                            <?= htmlspecialchars(substr($project['description'] ?? '', 0, 30)) ?><?= strlen($project['description'] ?? '') > 30 ? '...' : '' ?>
                                        </small>
                                    </td>
                                    <td class="d-none d-md-table-cell"><?= htmlspecialchars(substr($project['description'] ?? '', 0, 50)) ?><?= strlen($project['description'] ?? '') > 50 ? '...' : '' ?></td>
                                    <td>
                                        <span class="badge bg-<?= $project['status'] === 'active' ? 'success' : 'secondary' ?> text-nowrap">
                                            <?= htmlspecialchars($project['status']) ?>
                                        </span>
                                    </td>
                                    <td class="d-none d-lg-table-cell text-center"><?= $project['target_count'] ?? 0 ?></td>
                                    <td class="d-none d-lg-table-cell">
                                        <div class="progress" style="min-width: 80px; height: 20px;">
                                            <div class="progress-bar" role="progressbar" 
                                                 style="width: <?= round($project['avg_progress'] ?? 0) ?>%; font-size: 0.7rem;"
                                                 aria-valuenow="<?= round($project['avg_progress'] ?? 0) ?>" 
                                                 aria-valuemin="0" aria-valuemax="100">
                                                <?= round($project['avg_progress'] ?? 0) ?>%
                                            </div>
                                        </div>
                                    </td>
                                    <td class="d-none d-md-table-cell text-nowrap"><?= date('Y-m-d', strtotime($project['created_at'])) ?></td>
                                    <td class="actions-cell">
                                        <div class="btn-group btn-group-sm">
                                            <a href="/projects/<?= $project['id'] ?>" 
                                               class="btn btn-info" 
                                               title="View">
                                                <i class="bi bi-eye"></i>
                                            </a>
                                            <button class="btn btn-warning" 
                                                    type="button"
                                                    onclick="editProject(<?= htmlspecialchars(json_encode($project)) ?>)"
                                                    title="Edit">
                                                <i class="bi bi-pencil"></i>
                                            </button>
                                            <button class="btn btn-danger btn-delete" 
                                                    data-url="/projects/<?= $project['id'] ?>"
                                                    data-confirm="Delete project '<?= htmlspecialchars($project['name']) ?>'?"
                                                    title="Delete">
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- Modal Crear -->
<div class="modal fade" id="createModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Nuevo Proyecto</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form action="/projects" method="POST" class="ajax-form" data-redirect="/projects">
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
                    <button type="submit" class="btn btn-primary">Crear Proyecto</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Modal Editar -->
<div class="modal fade" id="editModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Editar Proyecto</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form id="editForm" method="POST" class="ajax-form" data-method="PUT" data-redirect="/projects">
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
                        <label class="form-label">Estado</label>
                        <select name="status" id="edit_status" class="form-select">
                            <option value="active">Activo</option>
                            <option value="completed">Completado</option>
                            <option value="archived">Archivado</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Actualizar Proyecto</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
// Edit project function
function editProject(project) {
    document.getElementById('edit_name').value = project.name;
    document.getElementById('edit_description').value = project.description || '';
    document.getElementById('edit_status').value = project.status;
    document.getElementById('editForm').action = '/projects/' + project.id;
    
    // Open modal
    const modal = new bootstrap.Modal(document.getElementById('editModal'));
    modal.show();
}
</script>
