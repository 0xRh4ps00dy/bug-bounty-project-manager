<?php
require_once 'config.php';

$pdo = getConnection();

if (!isset($_GET['id'])) {
    redirect('targets.php');
}

$targetId = (int)$_GET['id'];

// Processar accions de checklist
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'toggle_check':
                $checklistId = (int)$_POST['checklist_id'];
                $isChecked = isset($_POST['is_checked']) ? 1 : 0;
                
                $stmt = $pdo->prepare("UPDATE target_checklist SET is_checked = ?, checked_at = ? WHERE id = ?");
                $stmt->execute([$isChecked, $isChecked ? date('Y-m-d H:i:s') : null, $checklistId]);
                
                setFlashMessage("Estat actualitzat!", "success");
                redirect("target_detail.php?id=$targetId");
                break;
                
            case 'update_notes':
                $checklistId = (int)$_POST['checklist_id'];
                $notes = isset($_POST['notes']) ? trim($_POST['notes']) : '';
                
                $stmt = $pdo->prepare("UPDATE target_checklist SET notes = ? WHERE id = ?");
                $stmt->execute([$notes, $checklistId]);
                
                setFlashMessage("Notes actualitzades!", "success");
                redirect("target_detail.php?id=$targetId");
                break;
                
            case 'add_items':
                $categoryId = (int)$_POST['category_id'];
                
                // Obtenir tots els items de la categoria
                $stmt = $pdo->prepare("SELECT id FROM checklist_items WHERE category_id = ?");
                $stmt->execute([$categoryId]);
                $items = $stmt->fetchAll();
                
                // Inserir només els items que no existeixen ja
                $inserted = 0;
                foreach ($items as $item) {
                    $check = $pdo->prepare("SELECT COUNT(*) FROM target_checklist WHERE target_id = ? AND checklist_item_id = ?");
                    $check->execute([$targetId, $item['id']]);
                    
                    if ($check->fetchColumn() == 0) {
                        $insert = $pdo->prepare("INSERT INTO target_checklist (target_id, checklist_item_id) VALUES (?, ?)");
                        $insert->execute([$targetId, $item['id']]);
                        $inserted++;
                    }
                }
                
                setFlashMessage("$inserted items afegits correctament!", "success");
                redirect("target_detail.php?id=$targetId");
                break;
        }
    }
}

// Obtenir dades del target
$stmt = $pdo->prepare("
    SELECT t.*, p.name as project_name, p.id as project_id
    FROM targets t
    JOIN projects p ON t.project_id = p.id
    WHERE t.id = ?
");
$stmt->execute([$targetId]);
$target = $stmt->fetch();

if (!$target) {
    setFlashMessage("Target no trobat!", "danger");
    redirect('targets.php');
}

$pageTitle = htmlspecialchars($target['name']) . ' - Bug Bounty PM';

// Obtenir checklist items del target agrupats per categoria
$stmt = $pdo->prepare("
    SELECT tc.*, ci.title, ci.description as item_description, c.name as category_name, c.id as category_id
    FROM target_checklist tc
    JOIN checklist_items ci ON tc.checklist_item_id = ci.id
    JOIN categories c ON ci.category_id = c.id
    WHERE tc.target_id = ?
    ORDER BY c.name, ci.sort_order
");
$stmt->execute([$targetId]);
$checklistItems = $stmt->fetchAll();

// Agrupar per categoria
$groupedItems = [];
foreach ($checklistItems as $item) {
    $groupedItems[$item['category_name']][] = $item;
}

// Obtenir estadístiques
$totalItems = count($checklistItems);
$completedItems = array_filter($checklistItems, function($item) { return $item['is_checked']; });
$completedCount = count($completedItems);
$percentage = $totalItems > 0 ? round(($completedCount / $totalItems) * 100) : 0;

// Obtenir categories disponibles per afegir
$categories = $pdo->query("SELECT * FROM categories ORDER BY name")->fetchAll();

include 'header.php';
?>

<div class="row mb-4">
    <div class="col-12">
        <nav aria-label="breadcrumb">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="index.php">Dashboard</a></li>
                <li class="breadcrumb-item"><a href="projects.php">Projectes</a></li>
                <li class="breadcrumb-item"><a href="project_detail.php?id=<?php echo $target['project_id']; ?>">
                    <?php echo htmlspecialchars($target['project_name']); ?>
                </a></li>
                <li class="breadcrumb-item active"><?php echo htmlspecialchars($target['name']); ?></li>
            </ol>
        </nav>
    </div>
</div>

<div class="row mb-4">
    <div class="col-md-8">
        <h1><i class="bi bi-bullseye"></i> <?php echo htmlspecialchars($target['name']); ?></h1>
    </div>
    <div class="col-md-4 text-end">
        <a href="targets.php?edit=<?php echo $target['id']; ?>" class="btn btn-warning">
            <i class="bi bi-pencil"></i> Editar
        </a>
        <button class="btn btn-success" data-bs-toggle="modal" data-bs-target="#addItemsModal">
            <i class="bi bi-plus-circle"></i> Afegir Items
        </button>
    </div>
</div>

<!-- Informació del Target -->
<div class="row mb-4">
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <i class="bi bi-info-circle"></i> Informació del Target
            </div>
            <div class="card-body">
                <p class="mb-2"><strong>Projecte:</strong> 
                    <span class="badge bg-primary"><?php echo htmlspecialchars($target['project_name']); ?></span>
                </p>
                
                <?php if ($target['url']): ?>
                <p class="mb-2"><strong>URL:</strong> 
                    <a href="<?php echo htmlspecialchars($target['url']); ?>" target="_blank">
                        <?php echo htmlspecialchars($target['url']); ?>
                        <i class="bi bi-box-arrow-up-right"></i>
                    </a>
                </p>
                <?php endif; ?>
                
                <?php if ($target['description']): ?>
                <p class="mb-2"><strong>Descripció:</strong></p>
                <p class="text-muted"><?php echo nl2br(htmlspecialchars($target['description'])); ?></p>
                <?php endif; ?>
                
                <?php if ($target['notes']): ?>
                <hr>
                <p class="mb-2"><strong>Notes Agregades (Auto-generades):</strong></p>
                <div class="alert alert-info">
                    <pre class="mb-0" style="white-space: pre-wrap; font-size: 0.9rem;"><?php echo htmlspecialchars($target['notes']); ?></pre>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
    
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">
                <i class="bi bi-bar-chart"></i> Progrés
            </div>
            <div class="card-body text-center">
                <div class="mb-3">
                    <div class="progress" style="height: 30px;">
                        <div class="progress-bar bg-<?php echo $percentage >= 75 ? 'success' : ($percentage >= 50 ? 'warning' : 'secondary'); ?>" 
                             style="width: <?php echo $percentage; ?>%">
                            <?php echo $percentage; ?>%
                        </div>
                    </div>
                </div>
                <h3 class="mb-0"><?php echo $completedCount; ?> / <?php echo $totalItems; ?></h3>
                <p class="text-muted mb-0">Items completats</p>
            </div>
        </div>
        
        <div class="card mt-3">
            <div class="card-header">
                <i class="bi bi-clock-history"></i> Timestamps
            </div>
            <div class="card-body">
                <p class="mb-2"><small><strong>Creat:</strong><br><?php echo date('d/m/Y H:i', strtotime($target['created_at'])); ?></small></p>
                <p class="mb-0"><small><strong>Actualitzat:</strong><br><?php echo date('d/m/Y H:i', strtotime($target['updated_at'])); ?></small></p>
            </div>
        </div>
    </div>
</div>

<!-- Checklist Items -->
<div class="row">
    <div class="col-12">
        <div class="card">
            <div class="card-header">
                <i class="bi bi-list-check"></i> Checklist (<?php echo $completedCount; ?>/<?php echo $totalItems; ?>)
            </div>
            <div class="card-body">
                <?php if (empty($checklistItems)): ?>
                    <div class="text-center py-4">
                        <i class="bi bi-list-check" style="font-size: 3rem; color: #ccc;"></i>
                        <p class="text-muted mt-2">No hi ha items en aquesta checklist</p>
                        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addItemsModal">
                            <i class="bi bi-plus-circle"></i> Afegir Items
                        </button>
                    </div>
                <?php else: ?>
                    <?php foreach ($groupedItems as $categoryName => $items): ?>
                        <div class="mb-4">
                            <h5 class="bg-light p-2 rounded">
                                <i class="bi bi-tag"></i> <?php echo htmlspecialchars($categoryName); ?>
                                <span class="badge bg-secondary float-end"><?php echo count($items); ?> items</span>
                            </h5>
                            
                            <?php foreach ($items as $item): ?>
                                <div class="card mb-2">
                                    <div class="card-body">
                                        <div class="row align-items-start">
                                            <div class="col-md-6">
                                                <div class="form-check">
                                                    <input class="form-check-input" type="checkbox" 
                                                           id="check_<?php echo $item['id']; ?>"
                                                           <?php echo $item['is_checked'] ? 'checked' : ''; ?>
                                                           onchange="toggleCheck(<?php echo $item['id']; ?>, this.checked)">
                                                    <label class="form-check-label" for="check_<?php echo $item['id']; ?>">
                                                        <strong><?php echo htmlspecialchars($item['title']); ?></strong>
                                                        <?php if ($item['item_description']): ?>
                                                            <br><small class="text-muted"><?php echo htmlspecialchars($item['item_description']); ?></small>
                                                        <?php endif; ?>
                                                        <?php if ($item['checked_at']): ?>
                                                            <br><small class="text-success">
                                                                <i class="bi bi-check-circle"></i> 
                                                                Completat: <?php echo date('d/m/Y H:i', strtotime($item['checked_at'])); ?>
                                                            </small>
                                                        <?php endif; ?>
                                                    </label>
                                                </div>
                                            </div>
                                            <div class="col-md-6">
                                                <form method="POST" class="notes-form">
                                                    <input type="hidden" name="action" value="update_notes">
                                                    <input type="hidden" name="checklist_id" value="<?php echo $item['id']; ?>">
                                                    <div class="input-group">
                                                        <textarea class="form-control form-control-sm" name="notes" rows="2" 
                                                                  placeholder="Afegir notes..."><?php echo htmlspecialchars($item['notes'] ?? ''); ?></textarea>
                                                        <button type="submit" class="btn btn-sm btn-primary">
                                                            <i class="bi bi-save"></i>
                                                        </button>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            <?php endforeach; ?>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<!-- Modal per afegir items -->
<div class="modal fade" id="addItemsModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form method="POST">
                <div class="modal-header">
                    <h5 class="modal-title">Afegir Items de Checklist</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="action" value="add_items">
                    <div class="mb-3">
                        <label for="category_id" class="form-label">Selecciona una Categoria *</label>
                        <select class="form-select" id="category_id" name="category_id" required>
                            <option value="">Selecciona...</option>
                            <?php foreach ($categories as $cat): ?>
                                <option value="<?php echo $cat['id']; ?>">
                                    <?php echo htmlspecialchars($cat['name']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                        <small class="text-muted">Tots els items de la categoria seleccionada s'afegiran a aquest target</small>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel·lar</button>
                    <button type="submit" class="btn btn-success">
                        <i class="bi bi-plus-circle"></i> Afegir Items
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function toggleCheck(checklistId, isChecked) {
    const form = document.createElement('form');
    form.method = 'POST';
    form.innerHTML = `
        <input type="hidden" name="action" value="toggle_check">
        <input type="hidden" name="checklist_id" value="${checklistId}">
        ${isChecked ? '<input type="hidden" name="is_checked" value="1">' : ''}
    `;
    document.body.appendChild(form);
    form.submit();
}
</script>

<?php include 'footer.php'; ?>
