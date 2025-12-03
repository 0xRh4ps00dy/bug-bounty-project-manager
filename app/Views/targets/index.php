<?php $active = 'targets'; $title = 'Targets - BBPM'; ?>

<div class="container">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1><i class="bi bi-bullseye"></i> Targets</h1>
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createModal">
            <i class="bi bi-plus-circle"></i> New Target
        </button>
    </div>
    
    <?php if (empty($targets)): ?>
        <div class="alert alert-info">
            No targets found. Create your first target!
        </div>
    <?php else: ?>
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Project</th>
                        <th>URL</th>
                        <th>Description</th>
                        <th>Status</th>
                        <th>Progress</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($targets as $target): ?>
                        <tr>
                            <td><?= htmlspecialchars($target['project_id']) ?></td>
                            <td><?= htmlspecialchars($target['url']) ?></td>
                            <td><?= htmlspecialchars($target['description'] ?? '') ?></td>
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
                            <td>
                                <div class="btn-group">
                                    <a href="/targets/<?= $target['id'] ?>" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                    <button class="btn btn-sm btn-outline-danger btn-delete" 
                                            data-url="/targets/<?= $target['id'] ?>"
                                            data-confirm="Delete this target?">
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

<!-- Create Modal -->
<div class="modal fade" id="createModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form action="/targets" method="POST" class="ajax-form" data-redirect="/targets">
                <div class="modal-header">
                    <h5 class="modal-title">New Target</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Project *</label>
                        <select name="project_id" class="form-select" required>
                            <option value="">Select a project...</option>
                            <?php foreach ($projects as $project): ?>
                                <option value="<?= $project['id'] ?>"><?= htmlspecialchars($project['name']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">URL *</label>
                        <input type="url" name="url" class="form-control" required>
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
                    <button type="submit" class="btn btn-primary">Create Target</button>
                </div>
            </form>
        </div>
    </div>
</div>
