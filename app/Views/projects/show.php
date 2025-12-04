<?php $active = 'projects'; $title = htmlspecialchars($project['name']) . ' - Bug Bounty Project Manager'; ?>

<div class="container">
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="/projects">Projects</a></li>
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
                        <small class="text-muted">Total Targets</small>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="text-center p-3 bg-light rounded">
                        <h3 class="text-success"><?= round($project['avg_progress'] ?? 0) ?>%</h3>
                        <small class="text-muted">Average Progress</small>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="text-center p-3 bg-light rounded">
                        <h3 class="text-info"><?= date('Y-m-d', strtotime($project['created_at'])) ?></h3>
                        <small class="text-muted">Created</small>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="mb-0"><i class="bi bi-bullseye"></i> Targets</h5>
            <button class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#createTargetModal">
                <i class="bi bi-plus-circle"></i> Add Target
            </button>
        </div>
        <div class="card-body p-0">
            <?php if (empty($project['targets'])): ?>
                <p class="text-muted p-3">No targets yet. Add your first target!</p>
            <?php else: ?>
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Target</th>
                                <th>Type</th>
                                <th>Description</th>
                                <th>Status</th>
                                <th>Progress</th>
                                <th class="actions-cell">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($project['targets'] as $target): ?>
                                <tr class="clickable-row" onclick="window.location.href='/targets/<?= $target['id'] ?>';" style="cursor: pointer;">
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
                                        <div class="progress" style="width: 100px; height: 20px;">
                                            <div class="progress-bar" style="width: <?= $target['progress'] ?? 0 ?>%">
                                                <?= round($target['progress'] ?? 0) ?>%
                                            </div>
                                        </div>
                                    </td>
                                    <td class="actions-cell" onclick="event.stopPropagation();">
                                        <a href="/targets/<?= $target['id'] ?>" class="btn btn-sm btn-outline-primary">
                                            <i class="bi bi-eye"></i>
                                        </a>
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
                    <h5 class="modal-title">New Target</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
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
