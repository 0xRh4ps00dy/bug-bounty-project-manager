<?php $active = 'dashboard'; $title = 'Panel de Control - Bug Bounty Project Manager'; ?>

<div class="container">
    <h1 class="mb-4"><i class="bi bi-speedometer2"></i> Panel de Control</h1>
    
    <!-- Statistics Cards -->
    <div class="row g-4 mb-4">
        <div class="col-md-3">
            <div class="card stat-card">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h6 class="text-muted mb-2">Proyectos</h6>
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
                            <h6 class="text-muted mb-2">Objetivos</h6>
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
                            <h6 class="text-muted mb-2">Categorías</h6>
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
                            <h6 class="text-muted mb-2">Elementos Completados</h6>
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
                    <h5 class="mb-0"><i class="bi bi-folder"></i> Proyectos Recientes</h5>
                    <a href="/projects" class="btn btn-sm btn-primary">Ver Todos</a>
                </div>
                <div class="card-body">
                    <?php if (empty($recentProjects)): ?>
                        <p class="text-muted">Sin proyectos aún.</p>
                    <?php else: ?>
                        <div class="list-group list-group-flush">
                            <?php foreach ($recentProjects as $project): ?>
                                <a href="/projects/<?= $project['id'] ?>" class="list-group-item list-group-item-action">
                                    <div class="d-flex justify-content-between align-items-center">
                                        <div>
                                            <h6 class="mb-1"><?= htmlspecialchars($project['name']) ?></h6>
                                            <small class="text-muted">
                                                <?= $project['target_count'] ?> objetivos
                                            </small>
                                        </div>
                                        <span class="badge bg-<?= $project['status'] === 'active' ? 'success' : 'secondary' ?>">
                                            <?= htmlspecialchars($project['status'] === 'active' ? 'Activo' : $project['status']) ?>
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
                    <h5 class="mb-0"><i class="bi bi-bullseye"></i> Objetivos Recientes</h5>
                    <a href="/targets" class="btn btn-sm btn-primary">Ver Todos</a>
                </div>
                <div class="card-body">
                    <?php if (empty($recentTargets)): ?>
                        <p class="text-muted">Sin objetivos aún.</p>
                    <?php else: ?>
                        <div class="list-group list-group-flush">
                            <?php foreach ($recentTargets as $target): ?>
                                <a href="/targets/<?= $target['id'] ?>" class="list-group-item list-group-item-action">
                                    <div class="d-flex justify-content-between align-items-center">
                                        <div>
                                            <h6 class="mb-1"><?= htmlspecialchars($target['target']) ?></h6>
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
    
</div>
