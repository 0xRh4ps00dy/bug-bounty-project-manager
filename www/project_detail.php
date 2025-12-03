<?php
require_once 'config.php';

$pdo = getConnection();

if (!isset($_GET['id'])) {
    redirect('projects.php');
}

$projectId = (int)$_GET['id'];

// Obtenir dades del projecte
$stmt = $pdo->prepare("SELECT * FROM projects WHERE id = ?");
$stmt->execute([$projectId]);
$project = $stmt->fetch();

if (!$project) {
    setFlashMessage("Projecte no trobat!", "danger");
    redirect('projects.php');
}

$pageTitle = htmlspecialchars($project['name']) . ' - Bug Bounty PM';

// Obtenir targets del projecte
$stmt = $pdo->prepare("
    SELECT t.*,
           COUNT(DISTINCT tc.id) as checklist_count,
           SUM(CASE WHEN tc.is_checked = TRUE THEN 1 ELSE 0 END) as completed_count
    FROM targets t
    LEFT JOIN target_checklist tc ON t.id = tc.target_id
    WHERE t.project_id = ?
    GROUP BY t.id
    ORDER BY t.updated_at DESC
");
$stmt->execute([$projectId]);
$targets = $stmt->fetchAll();

include 'header.php';
?>

<div class="row mb-4">
    <div class="col-12">
        <nav aria-label="breadcrumb">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="index.php">Dashboard</a></li>
                <li class="breadcrumb-item"><a href="projects.php">Projectes</a></li>
                <li class="breadcrumb-item active"><?php echo htmlspecialchars($project['name']); ?></li>
            </ol>
        </nav>
    </div>
</div>

<div class="row mb-4">
    <div class="col-md-8">
        <h1><i class="bi bi-folder-open"></i> <?php echo htmlspecialchars($project['name']); ?></h1>
    </div>
    <div class="col-md-4 text-end">
        <a href="projects.php?edit=<?php echo $project['id']; ?>" class="btn btn-warning">
            <i class="bi bi-pencil"></i> Editar Projecte
        </a>
    </div>
</div>

<div class="row mb-4">
    <div class="col-12">
        <div class="card">
            <div class="card-header">
                <i class="bi bi-info-circle"></i> Informació del Projecte
            </div>
            <div class="card-body">
                <p class="mb-2"><strong>Descripció:</strong></p>
                <p class="text-muted"><?php echo htmlspecialchars($project['description'] ?? 'Sense descripció'); ?></p>
                
                <hr>
                
                <div class="row">
                    <div class="col-md-6">
                        <p class="mb-1"><strong>Creat:</strong> <?php echo date('d/m/Y H:i', strtotime($project['created_at'])); ?></p>
                    </div>
                    <div class="col-md-6">
                        <p class="mb-1"><strong>Actualitzat:</strong> <?php echo date('d/m/Y H:i', strtotime($project['updated_at'])); ?></p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row mb-4">
    <div class="col-12">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <span><i class="bi bi-bullseye"></i> Targets (<?php echo count($targets); ?>)</span>
                <a href="targets.php?project_id=<?php echo $project['id']; ?>" class="btn btn-sm btn-primary">
                    <i class="bi bi-plus-circle"></i> Afegir Target
                </a>
            </div>
            <div class="card-body">
                <?php if (empty($targets)): ?>
                    <div class="text-center py-4">
                        <i class="bi bi-bullseye" style="font-size: 3rem; color: #ccc;"></i>
                        <p class="text-muted mt-2">No hi ha targets en aquest projecte</p>
                        <a href="targets.php?project_id=<?php echo $project['id']; ?>" class="btn btn-primary btn-sm">
                            <i class="bi bi-plus-circle"></i> Crear Primer Target
                        </a>
                    </div>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead>
                                <tr>
                                    <th>Nom</th>
                                    <th>URL</th>
                                    <th>Progrés</th>
                                    <th>Notes</th>
                                    <th>Actualitzat</th>
                                    <th>Accions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($targets as $target): ?>
                                    <?php 
                                    $total = $target['checklist_count'];
                                    $completed = $target['completed_count'];
                                    $percentage = $total > 0 ? round(($completed / $total) * 100) : 0;
                                    ?>
                                    <tr>
                                        <td>
                                            <strong><?php echo htmlspecialchars($target['name']); ?></strong>
                                        </td>
                                        <td>
                                            <?php if ($target['url']): ?>
                                                <a href="<?php echo htmlspecialchars($target['url']); ?>" target="_blank" class="text-decoration-none">
                                                    <?php echo htmlspecialchars(substr($target['url'], 0, 30)); ?>...
                                                    <i class="bi bi-box-arrow-up-right"></i>
                                                </a>
                                            <?php else: ?>
                                                <span class="text-muted">-</span>
                                            <?php endif; ?>
                                        </td>
                                        <td>
                                            <div class="progress" style="height: 25px;">
                                                <div class="progress-bar bg-<?php echo $percentage >= 75 ? 'success' : ($percentage >= 50 ? 'warning' : 'secondary'); ?>" 
                                                     style="width: <?php echo $percentage; ?>%">
                                                    <?php echo $completed; ?>/<?php echo $total; ?> (<?php echo $percentage; ?>%)
                                                </div>
                                            </div>
                                        </td>
                                        <td>
                                            <?php if (!empty($target['notes'])): ?>
                                                <i class="bi bi-sticky text-warning" title="Té notes"></i>
                                            <?php else: ?>
                                                <span class="text-muted">-</span>
                                            <?php endif; ?>
                                        </td>
                                        <td>
                                            <small><?php echo date('d/m/Y', strtotime($target['updated_at'])); ?></small>
                                        </td>
                                        <td>
                                            <a href="target_detail.php?id=<?php echo $target['id']; ?>" class="btn btn-sm btn-primary">
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
</div>

<?php include 'footer.php'; ?>
