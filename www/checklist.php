<?php
require_once 'config.php';

$pageTitle = 'Checklist Items - Bug Bounty PM';
$pdo = getConnection();

// Processar accions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'create':
                $category_id = (int)$_POST['category_id'];
                $title = sanitize($_POST['title']);
                $description = sanitize($_POST['description']);
                $sort_order = (int)$_POST['sort_order'];
                
                $stmt = $pdo->prepare("INSERT INTO checklist_items (category_id, title, description, sort_order) VALUES (?, ?, ?, ?)");
                $stmt->execute([$category_id, $title, $description, $sort_order]);
                
                setFlashMessage("Checklist item creat correctament!", "success");
                redirect("checklist.php");
                break;
                
            case 'update':
                $id = (int)$_POST['id'];
                $category_id = (int)$_POST['category_id'];
                $title = sanitize($_POST['title']);
                $description = sanitize($_POST['description']);
                $sort_order = (int)$_POST['sort_order'];
                
                $stmt = $pdo->prepare("UPDATE checklist_items SET category_id = ?, title = ?, description = ?, sort_order = ? WHERE id = ?");
                $stmt->execute([$category_id, $title, $description, $sort_order, $id]);
                
                setFlashMessage("Checklist item actualitzat correctament!", "success");
                redirect("checklist.php");
                break;
                
            case 'delete':
                $id = (int)$_POST['id'];
                $stmt = $pdo->prepare("DELETE FROM checklist_items WHERE id = ?");
                $stmt->execute([$id]);
                
                setFlashMessage("Checklist item eliminat correctament!", "success");
                redirect("checklist.php");
                break;
        }
    }
}

// Filtrar per categoria si es proporciona
$categoryFilter = isset($_GET['category_id']) ? (int)$_GET['category_id'] : null;

// Obtenir totes les categories per el select
$categories = $pdo->query("SELECT * FROM categories ORDER BY name")->fetchAll();

// Obtenir checklist items
if ($categoryFilter) {
    $stmt = $pdo->prepare("
        SELECT ci.*, c.name as category_name
        FROM checklist_items ci
        JOIN categories c ON ci.category_id = c.id
        WHERE ci.category_id = ?
        ORDER BY ci.sort_order, ci.id
    ");
    $stmt->execute([$categoryFilter]);
    $checklistItems = $stmt->fetchAll();
} else {
    $checklistItems = $pdo->query("
        SELECT ci.*, c.name as category_name
        FROM checklist_items ci
        JOIN categories c ON ci.category_id = c.id
        ORDER BY c.name, ci.sort_order, ci.id
    ")->fetchAll();
}

// Agrupar per categoria
$groupedItems = [];
foreach ($checklistItems as $item) {
    $groupedItems[$item['category_name']][] = $item;
}

// Si s'està editant un item
$editItem = null;
if (isset($_GET['edit'])) {
    $editId = (int)$_GET['edit'];
    $stmt = $pdo->prepare("SELECT * FROM checklist_items WHERE id = ?");
    $stmt->execute([$editId]);
    $editItem = $stmt->fetch();
}

include 'header.php';
?>

<div class="row mb-4">
    <div class="col-md-4">
        <h1><i class="bi bi-list-check"></i> Checklist Items</h1>
    </div>
    <div class="col-md-4">
        <select class="form-select" onchange="window.location.href='checklist.php?category_id=' + this.value">
            <option value="">Totes les categories</option>
            <?php foreach ($categories as $cat): ?>
                <option value="<?php echo $cat['id']; ?>" <?php echo $categoryFilter == $cat['id'] ? 'selected' : ''; ?>>
                    <?php echo htmlspecialchars($cat['name']); ?>
                </option>
            <?php endforeach; ?>
        </select>
    </div>
    <div class="col-md-4 text-end">
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#checklistModal">
            <i class="bi bi-plus-circle"></i> Nou Item
        </button>
    </div>
</div>

<?php if (empty($checklistItems)): ?>
    <div class="card">
        <div class="card-body text-center py-5">
            <i class="bi bi-list-check" style="font-size: 4rem; color: #ccc;"></i>
            <h3 class="mt-3">No hi ha checklist items</h3>
            <p class="text-muted">Crea el teu primer checklist item</p>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#checklistModal">
                <i class="bi bi-plus-circle"></i> Crear Item
            </button>
        </div>
    </div>
<?php else: ?>
    <?php foreach ($groupedItems as $categoryName => $items): ?>
        <div class="card mb-4">
            <div class="card-header">
                <i class="bi bi-tag"></i> <?php echo htmlspecialchars($categoryName); ?>
                <span class="badge bg-secondary float-end"><?php echo count($items); ?> items</span>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th width="50">#</th>
                                <th>Títol</th>
                                <th>Descripció</th>
                                <th>Ordre</th>
                                <th width="150">Accions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($items as $index => $item): ?>
                                <tr>
                                    <td><?php echo $index + 1; ?></td>
                                    <td><strong><?php echo htmlspecialchars($item['title']); ?></strong></td>
                                    <td>
                                        <small class="text-muted">
                                            <?php echo htmlspecialchars(substr($item['description'] ?? '-', 0, 100)); ?>
                                            <?php if (strlen($item['description'] ?? '') > 100) echo '...'; ?>
                                        </small>
                                    </td>
                                    <td><?php echo $item['sort_order']; ?></td>
                                    <td>
                                        <a href="?edit=<?php echo $item['id']; ?>" class="btn btn-sm btn-warning">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <form method="POST" class="d-inline" onsubmit="return confirmDelete('Segur que vols eliminar aquest item?');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="id" value="<?php echo $item['id']; ?>">
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
    <?php endforeach; ?>
<?php endif; ?>

<!-- Modal per crear/editar item -->
<div class="modal fade" id="checklistModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <form method="POST">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <?php echo $editItem ? 'Editar Checklist Item' : 'Nou Checklist Item'; ?>
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="action" value="<?php echo $editItem ? 'update' : 'create'; ?>">
                    <?php if ($editItem): ?>
                        <input type="hidden" name="id" value="<?php echo $editItem['id']; ?>">
                    <?php endif; ?>
                    
                    <div class="mb-3">
                        <label for="category_id" class="form-label">Categoria *</label>
                        <select class="form-select" id="category_id" name="category_id" required>
                            <option value="">Selecciona una categoria...</option>
                            <?php foreach ($categories as $cat): ?>
                                <option value="<?php echo $cat['id']; ?>" 
                                        <?php echo ($editItem && $editItem['category_id'] == $cat['id']) || $categoryFilter == $cat['id'] ? 'selected' : ''; ?>>
                                    <?php echo htmlspecialchars($cat['name']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    
                    <div class="mb-3">
                        <label for="title" class="form-label">Títol *</label>
                        <input type="text" class="form-control" id="title" name="title" 
                               value="<?php echo $editItem ? htmlspecialchars($editItem['title']) : ''; ?>" 
                               required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="description" class="form-label">Descripció</label>
                        <textarea class="form-control" id="description" name="description" rows="3"><?php echo $editItem ? htmlspecialchars($editItem['description']) : ''; ?></textarea>
                    </div>
                    
                    <div class="mb-3">
                        <label for="sort_order" class="form-label">Ordre de Classificació</label>
                        <input type="number" class="form-control" id="sort_order" name="sort_order" 
                               value="<?php echo $editItem ? $editItem['sort_order'] : 0; ?>" min="0">
                        <small class="text-muted">Número més baix apareix primer</small>
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

<?php if ($editItem): ?>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        var modal = new bootstrap.Modal(document.getElementById('checklistModal'));
        modal.show();
    });
</script>
<?php endif; ?>

<?php include 'footer.php'; ?>
