<?php
require_once 'config.php';

$pageTitle = 'Targets - Bug Bounty PM';
$pdo = getConnection();

// Processar accions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'create':
                $project_id = (int)$_POST['project_id'];
                $name = sanitize($_POST['name']);
                $url = sanitize($_POST['url']);
                $description = sanitize($_POST['description']);
                
                $stmt = $pdo->prepare("INSERT INTO targets (project_id, name, url, description) VALUES (?, ?, ?, ?)");
                $stmt->execute([$project_id, $name, $url, $description]);
                
                setFlashMessage("Target creat correctament!", "success");
                redirect("targets.php");
                break;
                
            case 'update':
                $id = (int)$_POST['id'];
                $project_id = (int)$_POST['project_id'];
                $name = sanitize($_POST['name']);
                $url = sanitize($_POST['url']);
                $description = sanitize($_POST['description']);
                
                $stmt = $pdo->prepare("UPDATE targets SET project_id = ?, name = ?, url = ?, description = ? WHERE id = ?");
                $stmt->execute([$project_id, $name, $url, $description, $id]);
                
                setFlashMessage("Target actualitzat correctament!", "success");
                redirect("targets.php");
                break;
                
            case 'delete':
                $id = (int)$_POST['id'];
                $stmt = $pdo->prepare("DELETE FROM targets WHERE id = ?");
                $stmt->execute([$id]);
                
                setFlashMessage("Target eliminat correctament!", "success");
                redirect("targets.php");
                break;
        }
    }
}

// Obtenir tots els projectes per el select
$projects = $pdo->query("SELECT id, name FROM projects ORDER BY name")->fetchAll();

// Obtenir tots els targets
$targets = $pdo->query("
    SELECT t.*, p.name as project_name,
           COUNT(DISTINCT tc.id) as checklist_count,
           SUM(CASE WHEN tc.is_checked = TRUE THEN 1 ELSE 0 END) as completed_count
    FROM targets t
    JOIN projects p ON t.project_id = p.id
    LEFT JOIN target_checklist tc ON t.id = tc.target_id
    GROUP BY t.id
    ORDER BY t.updated_at DESC
")->fetchAll();

// Si s'està editant un target
$editTarget = null;
if (isset($_GET['edit'])) {
    $editId = (int)$_GET['edit'];
    $stmt = $pdo->prepare("SELECT * FROM targets WHERE id = ?");
    $stmt->execute([$editId]);
    $editTarget = $stmt->fetch();
}

// Si es crea des d'un projecte específic
$preselectedProject = isset($_GET['project_id']) ? (int)$_GET['project_id'] : null;

include 'header.php';
?>

<div class="row mb-4">
    <div class="col-md-8">
        <h1><i class="bi bi-bullseye"></i> Targets</h1>
    </div>
    <div class="col-md-4 text-end">
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#targetModal">
            <i class="bi bi-plus-circle"></i> Nou Target
        </button>
    </div>
</div>

<?php if (empty($targets)): ?>
    <div class="card">
        <div class="card-body text-center py-5">
            <i class="bi bi-bullseye" style="font-size: 4rem; color: #ccc;"></i>
            <h3 class="mt-3">No hi ha targets</h3>
            <p class="text-muted">Crea el teu primer target per començar</p>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#targetModal">
                <i class="bi bi-plus-circle"></i> Crear Target
            </button>
        </div>
    </div>
<?php else: ?>
    <div class="card">
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th>Nom</th>
                            <th>Projecte</th>
                            <th>URL</th>
                            <th>Progrés</th>
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
                                    <?php if (!empty($target['notes'])): ?>
                                        <i class="bi bi-sticky text-warning ms-1" title="Té notes"></i>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <span class="badge bg-primary">
                                        <?php echo htmlspecialchars($target['project_name']); ?>
                                    </span>
                                </td>
                                <td>
                                    <?php if ($target['url']): ?>
                                        <a href="<?php echo htmlspecialchars($target['url']); ?>" target="_blank" class="text-decoration-none">
                                            <?php echo htmlspecialchars(substr($target['url'], 0, 40)); ?>...
                                            <i class="bi bi-box-arrow-up-right"></i>
                                        </a>
                                    <?php else: ?>
                                        <span class="text-muted">-</span>
                                    <?php endif; ?>
                                </td>
                                <td style="min-width: 200px;">
                                    <div class="progress" style="height: 25px;">
                                        <div class="progress-bar bg-<?php echo $percentage >= 75 ? 'success' : ($percentage >= 50 ? 'warning' : 'secondary'); ?>" 
                                             style="width: <?php echo $percentage; ?>%">
                                            <?php echo $completed; ?>/<?php echo $total; ?> (<?php echo $percentage; ?>%)
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <small><?php echo date('d/m/Y H:i', strtotime($target['updated_at'])); ?></small>
                                </td>
                                <td>
                                    <a href="target_detail.php?id=<?php echo $target['id']; ?>" class="btn btn-sm btn-primary">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                    <a href="?edit=<?php echo $target['id']; ?>" class="btn btn-sm btn-warning">
                                        <i class="bi bi-pencil"></i>
                                    </a>
                                    <form method="POST" class="d-inline" onsubmit="return confirmDelete('Segur que vols eliminar aquest target?');">
                                        <input type="hidden" name="action" value="delete">
                                        <input type="hidden" name="id" value="<?php echo $target['id']; ?>">
                                        <button type="submit" class="btn btn-sm btn-danger">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
<?php endif; ?>

<!-- Modal per crear/editar target -->
<div class="modal fade" id="targetModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <form method="POST">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <?php echo $editTarget ? 'Editar Target' : 'Nou Target'; ?>
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="action" value="<?php echo $editTarget ? 'update' : 'create'; ?>">
                    <?php if ($editTarget): ?>
                        <input type="hidden" name="id" value="<?php echo $editTarget['id']; ?>">
                    <?php endif; ?>
                    
                    <div class="mb-3">
                        <label for="project_id" class="form-label">Projecte *</label>
                        <select class="form-select" id="project_id" name="project_id" required>
                            <option value="">Selecciona un projecte...</option>
                            <?php foreach ($projects as $proj): ?>
                                <option value="<?php echo $proj['id']; ?>" 
                                        <?php echo ($editTarget && $editTarget['project_id'] == $proj['id']) || ($preselectedProject == $proj['id']) ? 'selected' : ''; ?>>
                                    <?php echo htmlspecialchars($proj['name']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    
                    <div class="mb-3">
                        <label for="name" class="form-label">Nom del Target *</label>
                        <input type="text" class="form-control" id="name" name="name" 
                               value="<?php echo $editTarget ? htmlspecialchars($editTarget['name']) : ''; ?>" 
                               required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="url" class="form-label">URL</label>
                        <input type="url" class="form-control" id="url" name="url" 
                               value="<?php echo $editTarget ? htmlspecialchars($editTarget['url']) : ''; ?>" 
                               placeholder="https://example.com">
                    </div>
                    
                    <div class="mb-3">
                        <label for="description" class="form-label">Descripció</label>
                        <textarea class="form-control" id="description" name="description" rows="4"><?php echo $editTarget ? htmlspecialchars($editTarget['description']) : ''; ?></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel·lar</button>
                    <button type="submit" class="btn btn-primary">
                        <i class="bi bi-save"></i> Guardar
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php if ($editTarget || $preselectedProject): ?>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        var modal = new bootstrap.Modal(document.getElementById('targetModal'));
        modal.show();
    });
</script>
<?php endif; ?>

<?php include 'footer.php'; ?>
