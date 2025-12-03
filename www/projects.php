<?php
require_once 'config.php';

$pageTitle = 'Projectes - Bug Bounty PM';
$pdo = getConnection();

// Processar accions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'create':
                $name = sanitize($_POST['name']);
                $description = sanitize($_POST['description']);
                
                $stmt = $pdo->prepare("INSERT INTO projects (name, description) VALUES (?, ?)");
                $stmt->execute([$name, $description]);
                
                setFlashMessage("Projecte creat correctament!", "success");
                redirect("projects.php");
                break;
                
            case 'update':
                $id = (int)$_POST['id'];
                $name = sanitize($_POST['name']);
                $description = sanitize($_POST['description']);
                
                $stmt = $pdo->prepare("UPDATE projects SET name = ?, description = ? WHERE id = ?");
                $stmt->execute([$name, $description, $id]);
                
                setFlashMessage("Projecte actualitzat correctament!", "success");
                redirect("projects.php");
                break;
                
            case 'delete':
                $id = (int)$_POST['id'];
                $stmt = $pdo->prepare("DELETE FROM projects WHERE id = ?");
                $stmt->execute([$id]);
                
                setFlashMessage("Projecte eliminat correctament!", "success");
                redirect("projects.php");
                break;
        }
    }
}

// Obtenir tots els projectes
$projects = $pdo->query("
    SELECT p.*, 
           COUNT(DISTINCT t.id) as target_count,
           COUNT(DISTINCT tc.id) as checklist_count,
           SUM(CASE WHEN tc.is_checked = TRUE THEN 1 ELSE 0 END) as completed_count
    FROM projects p
    LEFT JOIN targets t ON p.id = t.project_id
    LEFT JOIN target_checklist tc ON t.id = tc.target_id
    GROUP BY p.id
    ORDER BY p.updated_at DESC
")->fetchAll();

// Si s'està editant un projecte
$editProject = null;
if (isset($_GET['edit'])) {
    $editId = (int)$_GET['edit'];
    $stmt = $pdo->prepare("SELECT * FROM projects WHERE id = ?");
    $stmt->execute([$editId]);
    $editProject = $stmt->fetch();
}

include 'header.php';
?>

<div class="row mb-4">
    <div class="col-md-8">
        <h1><i class="bi bi-folder"></i> Projectes</h1>
    </div>
    <div class="col-md-4 text-end">
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#projectModal">
            <i class="bi bi-plus-circle"></i> Nou Projecte
        </button>
    </div>
</div>

<?php if (empty($projects)): ?>
    <div class="card">
        <div class="card-body text-center py-5">
            <i class="bi bi-folder-x" style="font-size: 4rem; color: #ccc;"></i>
            <h3 class="mt-3">No hi ha projectes</h3>
            <p class="text-muted">Crea el teu primer projecte per començar</p>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#projectModal">
                <i class="bi bi-plus-circle"></i> Crear Projecte
            </button>
        </div>
    </div>
<?php else: ?>
    <div class="row">
        <?php foreach ($projects as $project): ?>
            <div class="col-md-6 col-lg-4 mb-4">
                <div class="card h-100">
                    <div class="card-body">
                        <h5 class="card-title">
                            <i class="bi bi-folder"></i>
                            <?php echo htmlspecialchars($project['name']); ?>
                        </h5>
                        <p class="card-text text-muted">
                            <?php echo htmlspecialchars(substr($project['description'] ?? 'Sense descripció', 0, 100)); ?>
                            <?php if (strlen($project['description'] ?? '') > 100) echo '...'; ?>
                        </p>
                        
                        <div class="mb-3">
                            <span class="badge bg-primary me-1">
                                <i class="bi bi-bullseye"></i> <?php echo $project['target_count']; ?> targets
                            </span>
                            <span class="badge bg-success me-1">
                                <i class="bi bi-check-circle"></i> <?php echo $project['completed_count']; ?> completats
                            </span>
                            <span class="badge bg-secondary">
                                <i class="bi bi-list-check"></i> <?php echo $project['checklist_count']; ?> items
                            </span>
                        </div>
                        
                        <small class="text-muted d-block mb-3">
                            <i class="bi bi-clock"></i> 
                            Actualitzat: <?php echo date('d/m/Y H:i', strtotime($project['updated_at'])); ?>
                        </small>
                    </div>
                    <div class="card-footer bg-transparent">
                        <a href="project_detail.php?id=<?php echo $project['id']; ?>" class="btn btn-sm btn-primary">
                            <i class="bi bi-eye"></i> Veure
                        </a>
                        <a href="?edit=<?php echo $project['id']; ?>" class="btn btn-sm btn-warning">
                            <i class="bi bi-pencil"></i> Editar
                        </a>
                        <form method="POST" class="d-inline" onsubmit="return confirmDelete('Segur que vols eliminar aquest projecte i tots els seus targets?');">
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<?php echo $project['id']; ?>">
                            <button type="submit" class="btn btn-sm btn-danger">
                                <i class="bi bi-trash"></i> Eliminar
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        <?php endforeach; ?>
    </div>
<?php endif; ?>

<!-- Modal per crear/editar projecte -->
<div class="modal fade" id="projectModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form method="POST">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <?php echo $editProject ? 'Editar Projecte' : 'Nou Projecte'; ?>
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="action" value="<?php echo $editProject ? 'update' : 'create'; ?>">
                    <?php if ($editProject): ?>
                        <input type="hidden" name="id" value="<?php echo $editProject['id']; ?>">
                    <?php endif; ?>
                    
                    <div class="mb-3">
                        <label for="name" class="form-label">Nom del Projecte *</label>
                        <input type="text" class="form-control" id="name" name="name" 
                               value="<?php echo $editProject ? htmlspecialchars($editProject['name']) : ''; ?>" 
                               required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="description" class="form-label">Descripció</label>
                        <textarea class="form-control" id="description" name="description" rows="4"><?php echo $editProject ? htmlspecialchars($editProject['description']) : ''; ?></textarea>
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

<?php if ($editProject): ?>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        var modal = new bootstrap.Modal(document.getElementById('projectModal'));
        modal.show();
    });
</script>
<?php endif; ?>

<?php include 'footer.php'; ?>
