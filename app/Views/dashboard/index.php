<?php $active = 'dashboard'; $title = 'Panel de Control - Bug Bounty Project Manager'; ?>

<div class="container">
    <h1 class="mb-4"><i class="bi bi-speedometer2"></i> Panel de Control</h1>
    
    <!-- Statistics Cards -->
    <div class="row g-2 g-md-4 mb-4">
        <div class="col-6 col-md-3">
            <div class="card stat-card">
                <div class="card-body p-2 p-md-3">
                    <div class="d-flex justify-content-between align-items-center gap-2">
                        <div class="flex-grow-1 min-w-0">
                            <h6 class="text-muted mb-1 text-truncate">Proyectos</h6>
                            <div class="stat-value text-primary"><?= $stats['projects'] ?? 0 ?></div>
                        </div>
                        <i class="bi bi-folder fs-2 text-primary opacity-25 flex-shrink-0"></i>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-6 col-md-3">
            <div class="card stat-card success">
                <div class="card-body p-2 p-md-3">
                    <div class="d-flex justify-content-between align-items-center gap-2">
                        <div class="flex-grow-1 min-w-0">
                            <h6 class="text-muted mb-1 text-truncate">Objetivos</h6>
                            <div class="stat-value text-success"><?= $stats['targets'] ?? 0 ?></div>
                        </div>
                        <i class="bi bi-bullseye fs-2 text-success opacity-25 flex-shrink-0"></i>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-6 col-md-3">
            <div class="card stat-card warning">
                <div class="card-body p-2 p-md-3">
                    <div class="d-flex justify-content-between align-items-center gap-2">
                        <div class="flex-grow-1 min-w-0">
                            <h6 class="text-muted mb-1 text-truncate">Categorías</h6>
                            <div class="stat-value text-warning"><?= $stats['categories'] ?? 0 ?></div>
                        </div>
                        <i class="bi bi-tags fs-2 text-warning opacity-25 flex-shrink-0"></i>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-6 col-md-3">
            <div class="card stat-card danger">
                <div class="card-body p-2 p-md-3">
                    <div class="d-flex justify-content-between align-items-center gap-2">
                        <div class="flex-grow-1 min-w-0">
                            <h6 class="text-muted mb-1 text-truncate">Completados</h6>
                            <div class="stat-value text-danger"><?= $stats['completed_items'] ?? 0 ?></div>
                        </div>
                        <i class="bi bi-check-circle fs-2 text-danger opacity-25 flex-shrink-0"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="row g-2 g-md-4">
        <!-- Recent Projects -->
        <div class="col-12 col-lg-6">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <h5 class="mb-0"><i class="bi bi-folder"></i> Proyectos Recientes</h5>
                    <a href="/projects" class="btn btn-sm btn-primary flex-shrink-0">Ver Todos</a>
                </div>
                <div class="card-body p-0">
                    <?php if (empty($recentProjects)): ?>
                        <p class="text-muted p-3 mb-0">Sin proyectos aún.</p>
                    <?php else: ?>
                        <div class="list-group list-group-flush">
                            <?php foreach ($recentProjects as $project): ?>
                                <a href="/projects/<?= $project['id'] ?>" class="list-group-item list-group-item-action p-2 p-md-3">
                                    <div class="d-flex justify-content-between align-items-start gap-2 flex-wrap">
                                        <div class="flex-grow-1 min-w-0">
                                            <h6 class="mb-1 text-truncate"><?= htmlspecialchars($project['name']) ?></h6>
                                            <small class="text-muted d-block text-truncate">
                                                <?= $project['target_count'] ?> objetivos
                                            </small>
                                        </div>
                                        <span class="badge bg-<?= $project['status'] === 'active' ? 'success' : 'secondary' ?> flex-shrink-0">
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
        <div class="col-12 col-lg-6">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <h5 class="mb-0"><i class="bi bi-bullseye"></i> Objetivos Recientes</h5>
                    <a href="/targets" class="btn btn-sm btn-primary flex-shrink-0">Ver Todos</a>
                </div>
                <div class="card-body p-0">
                    <?php if (empty($recentTargets)): ?>
                        <p class="text-muted p-3 mb-0">Sin objetivos aún.</p>
                    <?php else: ?>
                        <div class="list-group list-group-flush">
                            <?php foreach ($recentTargets as $target): ?>
                                <a href="/targets/<?= $target['id'] ?>" class="list-group-item list-group-item-action p-2 p-md-3">
                                    <div class="d-flex justify-content-between align-items-start gap-2 flex-wrap">
                                        <div class="flex-grow-1 min-w-0">
                                            <h6 class="mb-1 text-truncate"><?= htmlspecialchars($target['target']) ?></h6>
                                            <small class="text-muted d-block text-truncate">
                                                <?= htmlspecialchars($target['project_name']) ?>
                                            </small>
                                        </div>
                                        <div class="text-end flex-shrink-0" style="min-width: 80px;">
                                            <div class="progress" style="height: 18px;">
                                                <div class="progress-bar" role="progressbar" 
                                                     style="width: <?= $target['progress'] ?? 0 ?>%; font-size: 0.7rem;"
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
