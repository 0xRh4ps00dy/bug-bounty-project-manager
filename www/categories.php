<?php
require_once 'config.php';

$pageTitle = 'Categories - Bug Bounty PM';
$pdo = getConnection();

// Processar accions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'create':
                $name = sanitize($_POST['name']);
                $description = sanitize($_POST['description']);
                
                $stmt = $pdo->prepare("INSERT INTO categories (name, description) VALUES (?, ?)");
                $stmt->execute([$name, $description]);
                
                setFlashMessage("Categoria creada correctament!", "success");
                redirect("categories.php");
                break;
                
            case 'update':
                $id = (int)$_POST['id'];
                $name = sanitize($_POST['name']);
                $description = sanitize($_POST['description']);
                
                $stmt = $pdo->prepare("UPDATE categories SET name = ?, description = ? WHERE id = ?");
                $stmt->execute([$name, $description, $id]);
                
                setFlashMessage("Categoria actualitzada correctament!", "success");
                redirect("categories.php");
                break;
                
            case 'delete':
                $id = (int)$_POST['id'];
                $stmt = $pdo->prepare("DELETE FROM categories WHERE id = ?");
                $stmt->execute([$id]);
                
                setFlashMessage("Categoria eliminada correctament!", "success");
                redirect("categories.php");
                break;
        }
    }
}

// Obtenir totes les categories amb el número d'items
$categories = $pdo->query("
    SELECT c.*, COUNT(ci.id) as item_count
    FROM categories c
    LEFT JOIN checklist_items ci ON c.id = ci.category_id
    GROUP BY c.id
    ORDER BY c.name
")->fetchAll();

// Si s'està editant una categoria
$editCategory = null;
if (isset($_GET['edit'])) {
    $editId = (int)$_GET['edit'];
    $stmt = $pdo->prepare("SELECT * FROM categories WHERE id = ?");
    $stmt->execute([$editId]);
    $editCategory = $stmt->fetch();
}

include 'header.php';
?>

<div class="row mb-4">
    <div class="col-md-8">
        <h1><i class="bi bi-tags"></i> Categories</h1>
    </div>
    <div class="col-md-4 text-end">
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#categoryModal">
            <i class="bi bi-plus-circle"></i> Nova Categoria
        </button>
    </div>
</div>

<?php if (empty($categories)): ?>
    <div class="card">
        <div class="card-body text-center py-5">
            <i class="bi bi-tags" style="font-size: 4rem; color: #ccc;"></i>
            <h3 class="mt-3">No hi ha categories</h3>
            <p class="text-muted">Crea la teva primera categoria per organitzar els checklist items</p>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#categoryModal">
                <i class="bi bi-plus-circle"></i> Crear Categoria
            </button>
        </div>
    </div>
<?php else: ?>
    <div class="row">
        <?php foreach ($categories as $category): ?>
            <div class="col-md-6 col-lg-4 mb-4">
                <div class="card h-100">
                    <div class="card-body">
                        <h5 class="card-title">
                            <i class="bi bi-tag"></i>
                            <?php echo htmlspecialchars($category['name']); ?>
                        </h5>
                        <p class="card-text text-muted">
                            <?php echo htmlspecialchars($category['description'] ?? 'Sense descripció'); ?>
                        </p>
                        
                        <div class="mb-2">
                            <span class="badge bg-info">
                                <i class="bi bi-list-check"></i> <?php echo $category['item_count']; ?> items
                            </span>
                        </div>
                        
                        <small class="text-muted">
                            <i class="bi bi-clock"></i> 
                            Creat: <?php echo date('d/m/Y', strtotime($category['created_at'])); ?>
                        </small>
                    </div>
                    <div class="card-footer bg-transparent">
                        <a href="checklist.php?category_id=<?php echo $category['id']; ?>" class="btn btn-sm btn-primary">
                            <i class="bi bi-list-check"></i> Veure Items
                        </a>
                        <a href="?edit=<?php echo $category['id']; ?>" class="btn btn-sm btn-warning">
                            <i class="bi bi-pencil"></i>
                        </a>
                        <form method="POST" class="d-inline" onsubmit="return confirmDelete('Segur que vols eliminar aquesta categoria i tots els seus items?');">
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<?php echo $category['id']; ?>">
                            <button type="submit" class="btn btn-sm btn-danger">
                                <i class="bi bi-trash"></i>
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        <?php endforeach; ?>
    </div>
<?php endif; ?>

<!-- Modal per crear/editar categoria -->
<div class="modal fade" id="categoryModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form method="POST">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <?php echo $editCategory ? 'Editar Categoria' : 'Nova Categoria'; ?>
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="action" value="<?php echo $editCategory ? 'update' : 'create'; ?>">
                    <?php if ($editCategory): ?>
                        <input type="hidden" name="id" value="<?php echo $editCategory['id']; ?>">
                    <?php endif; ?>
                    
                    <div class="mb-3">
                        <label for="name" class="form-label">Nom de la Categoria *</label>
                        <input type="text" class="form-control" id="name" name="name" 
                               value="<?php echo $editCategory ? htmlspecialchars($editCategory['name']) : ''; ?>" 
                               required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="description" class="form-label">Descripció</label>
                        <textarea class="form-control" id="description" name="description" rows="3"><?php echo $editCategory ? htmlspecialchars($editCategory['description']) : ''; ?></textarea>
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

<?php if ($editCategory): ?>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        var modal = new bootstrap.Modal(document.getElementById('categoryModal'));
        modal.show();
    });
</script>
<?php endif; ?>

<?php include 'footer.php'; ?>
