<?php $active = 'projects'; $title = 'Projects - Bug Bounty Project Manager'; ?>

<div class="container">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1><i class="bi bi-folder"></i> Projects</h1>
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createModal">
            <i class="bi bi-plus-circle"></i> New Project
        </button>
    </div>
    
    <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="mb-0"><i class="bi bi-folder"></i> Projects</h5>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Description</th>
                            <th>Status</th>
                            <th>Targets</th>
                            <th>Progress</th>
                            <th>Created</th>
                            <th class="actions-cell">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($projects)): ?>
                            <tr>
                                <td colspan="7" class="text-center text-muted">No projects found</td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($projects as $project): ?>
                                <tr class="clickable-row" data-href="/projects/<?= $project['id'] ?>" style="cursor: pointer;">
                                    <td>
                                        <strong><?= htmlspecialchars($project['name']) ?></strong>
                                    </td>
                                    <td><?= htmlspecialchars(substr($project['description'] ?? '', 0, 50)) ?><?= strlen($project['description'] ?? '') > 50 ? '...' : '' ?></td>
                                    <td>
                                        <span class="badge bg-<?= $project['status'] === 'active' ? 'success' : 'secondary' ?>">
                                            <?= htmlspecialchars($project['status']) ?>
                                        </span>
                                    </td>
                                    <td><?= $project['target_count'] ?? 0 ?></td>
                                    <td>
                                        <div class="progress" style="min-width: 100px;">
                                            <div class="progress-bar" style="width: <?= round($project['avg_progress'] ?? 0) ?>%">
                                                <?= round($project['avg_progress'] ?? 0) ?>%
                                            </div>
                                        </div>
                                    </td>
                                    <td><?= date('Y-m-d', strtotime($project['created_at'])) ?></td>
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

<!-- Create Modal -->
<div class="modal fade" id="createModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">New Project</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form action="/projects" method="POST" class="ajax-form" data-redirect="/projects">
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Name *</label>
                        <input type="text" name="name" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Description</label>
                        <textarea name="description" class="form-control" rows="3"></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Status</label>
                        <select name="status" class="form-select">
                            <option value="active">Active</option>
                            <option value="completed">Completed</option>
                            <option value="archived">Archived</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Create Project</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Edit Modal -->
<div class="modal fade" id="editModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Edit Project</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form id="editForm" method="POST" class="ajax-form" data-method="PUT" data-redirect="/projects">
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Name *</label>
                        <input type="text" name="name" id="edit_name" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Description</label>
                        <textarea name="description" id="edit_description" class="form-control" rows="3"></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Status</label>
                        <select name="status" id="edit_status" class="form-select">
                            <option value="active">Active</option>
                            <option value="completed">Completed</option>
                            <option value="archived">Archived</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Update Project</button>
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
