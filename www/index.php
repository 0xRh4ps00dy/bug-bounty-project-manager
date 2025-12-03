<?php
require_once 'config.php';

$pageTitle = 'Dashboard - Bug Bounty PM';

// Obtenir estadístiques
$pdo = getConnection();

$stats = [];
$stats['projects'] = $pdo->query("SELECT COUNT(*) FROM projects")->fetchColumn();
$stats['targets'] = $pdo->query("SELECT COUNT(*) FROM targets")->fetchColumn();
$stats['categories'] = $pdo->query("SELECT COUNT(*) FROM categories")->fetchColumn();
$stats['checklist_items'] = $pdo->query("SELECT COUNT(*) FROM checklist_items")->fetchColumn();
$stats['completed_items'] = $pdo->query("SELECT COUNT(*) FROM target_checklist WHERE is_checked = TRUE")->fetchColumn();
$stats['total_checklist'] = $pdo->query("SELECT COUNT(*) FROM target_checklist")->fetchColumn();

// Projectes recents
$recentProjects = $pdo->query("
    SELECT p.*, COUNT(t.id) as target_count 
    FROM projects p 
    LEFT JOIN targets t ON p.id = t.project_id 
    GROUP BY p.id 
    ORDER BY p.updated_at DESC 
    LIMIT 5
")->fetchAll();

// Targets amb més notes
$targetsWithNotes = $pdo->query("
    SELECT t.*, p.name as project_name,
    (SELECT COUNT(*) FROM target_checklist tc WHERE tc.target_id = t.id AND tc.is_checked = TRUE) as completed,
    (SELECT COUNT(*) FROM target_checklist tc WHERE tc.target_id = t.id) as total
    FROM targets t
    JOIN projects p ON t.project_id = p.id
    WHERE t.notes IS NOT NULL AND t.notes != ''
    ORDER BY t.updated_at DESC
    LIMIT 5
")->fetchAll();

include 'header.php';
?>

<div class="row">
    <div class="col-12 mb-4">
        <h1><i class="bi bi-speedometer2"></i> Dashboard</h1>
    </div>
</div>

<div class="row mb-4">
    <div class="col-md-3 mb-3">
        <div class="stats-card" style="border-top: 4px solid #3498db;">
            <i class="bi bi-folder text-primary"></i>
            <h3><?php echo $stats['projects']; ?></h3>
            <p>Projectes</p>
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="stats-card" style="border-top: 4px solid #e74c3c;">
            <i class="bi bi-bullseye text-danger"></i>
            <h3><?php echo $stats['targets']; ?></h3>
            <p>Targets</p>
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="stats-card" style="border-top: 4px solid #f39c12;">
            <i class="bi bi-tags text-warning"></i>
            <h3><?php echo $stats['categories']; ?></h3>
            <p>Categories</p>
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="stats-card" style="border-top: 4px solid #27ae60;">
            <i class="bi bi-check-circle text-success"></i>
            <h3><?php echo $stats['completed_items']; ?>/<?php echo $stats['total_checklist']; ?></h3>
            <p>Items Completats</p>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-6 mb-4">
        <div class="card">
            <div class="card-header">
                <i class="bi bi-folder"></i> Projectes Recents
            </div>
            <div class="card-body">
                <?php if (empty($recentProjects)): ?>
                    <p class="text-muted">No hi ha projectes encara.</p>
                    <a href="projects.php" class="btn btn-primary btn-sm">Crear Primer Projecte</a>
                <?php else: ?>
                    <div class="list-group">
                        <?php foreach ($recentProjects as $project): ?>
                            <a href="project_detail.php?id=<?php echo $project['id']; ?>" class="list-group-item list-group-item-action">
                                <div class="d-flex w-100 justify-content-between">
                                    <h6 class="mb-1"><?php echo htmlspecialchars($project['name']); ?></h6>
                                    <small class="text-muted">
                                        <span class="badge bg-secondary"><?php echo $project['target_count']; ?> targets</span>
                                    </small>
                                </div>
                                <small class="text-muted">
                                    <?php echo htmlspecialchars(substr($project['description'] ?? '', 0, 80)); ?>...
                                </small>
                            </a>
                        <?php endforeach; ?>
                    </div>
                    <div class="mt-3">
                        <a href="projects.php" class="btn btn-primary btn-sm">Veure Tots els Projectes</a>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <div class="col-md-6 mb-4">
        <div class="card">
            <div class="card-header">
                <i class="bi bi-bullseye"></i> Targets amb Activitat Recent
            </div>
            <div class="card-body">
                <?php if (empty($targetsWithNotes)): ?>
                    <p class="text-muted">No hi ha targets amb notes encara.</p>
                <?php else: ?>
                    <div class="list-group">
                        <?php foreach ($targetsWithNotes as $target): ?>
                            <a href="target_detail.php?id=<?php echo $target['id']; ?>" class="list-group-item list-group-item-action">
                                <div class="d-flex w-100 justify-content-between">
                                    <h6 class="mb-1"><?php echo htmlspecialchars($target['name']); ?></h6>
                                    <small>
                                        <?php 
                                        $percentage = $target['total'] > 0 ? round(($target['completed'] / $target['total']) * 100) : 0;
                                        ?>
                                        <span class="badge bg-<?php echo $percentage >= 75 ? 'success' : ($percentage >= 50 ? 'warning' : 'secondary'); ?>">
                                            <?php echo $percentage; ?>%
                                        </span>
                                    </small>
                                </div>
                                <small class="text-muted">
                                    <?php echo htmlspecialchars($target['project_name']); ?> • 
                                    <?php echo $target['completed']; ?>/<?php echo $target['total']; ?> items
                                </small>
                            </a>
                        <?php endforeach; ?>
                    </div>
                    <div class="mt-3">
                        <a href="targets.php" class="btn btn-primary btn-sm">Veure Tots els Targets</a>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-12">
        <div class="card">
            <div class="card-header">
                <i class="bi bi-info-circle"></i> Accions Ràpides
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-3 mb-2">
                        <a href="projects.php" class="btn btn-outline-primary w-100">
                            <i class="bi bi-folder-plus"></i> Nou Projecte
                        </a>
                    </div>
                    <div class="col-md-3 mb-2">
                        <a href="targets.php" class="btn btn-outline-danger w-100">
                            <i class="bi bi-plus-circle"></i> Nou Target
                        </a>
                    </div>
                    <div class="col-md-3 mb-2">
                        <a href="categories.php" class="btn btn-outline-warning w-100">
                            <i class="bi bi-tag"></i> Nova Categoria
                        </a>
                    </div>
                    <div class="col-md-3 mb-2">
                        <a href="checklist.php" class="btn btn-outline-success w-100">
                            <i class="bi bi-list-check"></i> Nou Checklist Item
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<?php include 'footer.php'; ?>
