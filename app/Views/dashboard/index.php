<?php $active = 'dashboard'; $title = 'Dashboard - BBPM'; ?>

<div class="container">
    <h1 class="mb-4"><i class="bi bi-speedometer2"></i> Dashboard</h1>
    
    <!-- Statistics Cards -->
    <div class="row g-4 mb-4">
        <div class="col-md-3">
            <div class="card stat-card">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h6 class="text-muted mb-2">Projects</h6>
                            <div class="stat-value text-primary"><?= $stats['projects'] ?? 0 ?></div>
                        </div>
                        <i class="bi bi-folder fs-1 text-primary opacity-25"></i>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-md-3">
            <div class="card stat-card success">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h6 class="text-muted mb-2">Targets</h6>
                            <div class="stat-value text-success"><?= $stats['targets'] ?? 0 ?></div>
                        </div>
                        <i class="bi bi-bullseye fs-1 text-success opacity-25"></i>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-md-3">
            <div class="card stat-card warning">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h6 class="text-muted mb-2">Categories</h6>
                            <div class="stat-value text-warning"><?= $stats['categories'] ?? 0 ?></div>
                        </div>
                        <i class="bi bi-tags fs-1 text-warning opacity-25"></i>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-md-3">
            <div class="card stat-card danger">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h6 class="text-muted mb-2">Completed Items</h6>
                            <div class="stat-value text-danger"><?= $stats['completed_items'] ?? 0 ?></div>
                        </div>
                        <i class="bi bi-check-circle fs-1 text-danger opacity-25"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="row g-4">
        <!-- Recent Projects -->
        <div class="col-md-6">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0"><i class="bi bi-folder"></i> Recent Projects</h5>
                    <a href="/projects" class="btn btn-sm btn-primary">View All</a>
                </div>
                <div class="card-body">
                    <?php if (empty($recentProjects)): ?>
                        <p class="text-muted">No projects yet.</p>
                    <?php else: ?>
                        <div class="list-group list-group-flush">
                            <?php foreach ($recentProjects as $project): ?>
                                <a href="/projects/<?= $project['id'] ?>" class="list-group-item list-group-item-action">
                                    <div class="d-flex justify-content-between align-items-center">
                                        <div>
                                            <h6 class="mb-1"><?= htmlspecialchars($project['name']) ?></h6>
                                            <small class="text-muted">
                                                <?= $project['target_count'] ?> targets
                                            </small>
                                        </div>
                                        <span class="badge bg-<?= $project['status'] === 'active' ? 'success' : 'secondary' ?>">
                                            <?= htmlspecialchars($project['status']) ?>
                                        </span>
                                    </div>
                                </a>
                            <?php endforeach; ?>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
        
        <!-- Recent Targets -->
        <div class="col-md-6">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0"><i class="bi bi-bullseye"></i> Recent Targets</h5>
                    <a href="/targets" class="btn btn-sm btn-primary">View All</a>
                </div>
                <div class="card-body">
                    <?php if (empty($recentTargets)): ?>
                        <p class="text-muted">No targets yet.</p>
                    <?php else: ?>
                        <div class="list-group list-group-flush">
                            <?php foreach ($recentTargets as $target): ?>
                                <a href="/targets/<?= $target['id'] ?>" class="list-group-item list-group-item-action">
                                    <div class="d-flex justify-content-between align-items-center">
                                        <div>
                                            <h6 class="mb-1"><?= htmlspecialchars($target['url']) ?></h6>
                                            <small class="text-muted">
                                                <?= htmlspecialchars($target['project_name']) ?>
                                            </small>
                                        </div>
                                        <div class="text-end">
                                            <div class="progress" style="width: 100px; height: 20px;">
                                                <div class="progress-bar" role="progressbar" 
                                                     style="width: <?= $target['progress'] ?? 0 ?>%"
                                                     aria-valuenow="<?= $target['progress'] ?? 0 ?>" 
                                                     aria-valuemin="0" aria-valuemax="100">
                                                    <?= round($target['progress'] ?? 0) ?>%
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </a>
                            <?php endforeach; ?>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Quick Actions -->
    <div class="row mt-4">
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h5 class="mb-0"><i class="bi bi-lightning"></i> Quick Actions</h5>
                </div>
                <div class="card-body">
                    <div class="d-flex gap-2 flex-wrap">
                        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#newProjectModal">
                            <i class="bi bi-plus-circle"></i> New Project
                        </button>
                        <button class="btn btn-success" data-bs-toggle="modal" data-bs-target="#newTargetModal">
                            <i class="bi bi-plus-circle"></i> New Target
                        </button>
                        <a href="/categories" class="btn btn-warning">
                            <i class="bi bi-tags"></i> Manage Categories
                        </a>
                        <a href="/checklist" class="btn btn-info">
                            <i class="bi bi-list-check"></i> Manage Checklist
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
