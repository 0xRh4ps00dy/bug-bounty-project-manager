<?php 
$active = 'targets'; 
$title = htmlspecialchars($target['target']) . ' - Bug Bounty Project Manager';

// Initialize Parsedown for markdown support
require_once __DIR__ . '/../../../vendor/autoload.php';
$parsedown = new \Parsedown();
?>

<div class="container">
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="/targets">Objetivos</a></li>
            <li class="breadcrumb-item active"><?= htmlspecialchars($target['target']) ?></li>
        </ol>
    </nav>
    
    <div class="card mb-4">
        <div class="card-body">
            <div class="d-flex justify-content-between align-items-start mb-3">
                <div>
                    <h1 class="mb-2"><?= htmlspecialchars($target['target']) ?></h1>
                    <p class="text-muted mb-0"><?= htmlspecialchars($target['description'] ?? '') ?></p>
                </div>
                <a href="/targets/<?= $target['id'] ?>/notes" class="btn btn-primary">
                    <i class="bi bi-journal-text"></i> Ver Todas las Notas
                </a>
            </div>
            
            <div class="row mt-4">
                <div class="col-md-2">
                    <strong>Proyecto:</strong><br>
                    <a href="/projects/<?= $target['project_id'] ?>"><?= htmlspecialchars($target['project_name']) ?></a>
                </div>
                <div class="col-md-2">
                    <strong>Tipo:</strong><br>
                    <span class="badge bg-<?= $target['target_type'] === 'url' ? 'primary' : ($target['target_type'] === 'ip' ? 'info' : 'secondary') ?>">
                        <?= ucfirst(htmlspecialchars($target['target_type'])) ?>
                    </span>
                </div>
                <div class="col-md-2">
                    <strong>Estado:</strong><br>
                    <span class="badge bg-<?= $target['status'] === 'active' ? 'success' : 'secondary' ?>">
                        <?= $target['status'] === 'active' ? 'Activo' : 'Inactivo' ?>
                    </span>
                </div>
                <div class="col-md-2">
                    <strong>Progreso:</strong><br>
                    <span class="completed-count"><?= $target['completed_items'] ?? 0 ?></span> / <?= $target['total_items'] ?? 0 ?>
                </div>
                <div class="col-md-4">
                    <div class="progress" data-target-id="<?= $target['id'] ?>">
                        <div class="progress-bar" role="progressbar" 
                             style="width: <?= $target['progress'] ?? 0 ?>%"
                             aria-valuenow="<?= $target['progress'] ?? 0 ?>" 
                             aria-valuemin="0" aria-valuemax="100">
                            <?= round($target['progress'] ?? 0) ?>%
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="card">
        <div class="card-header">
            <h5 class="mb-0"><i class="bi bi-list-check"></i> Lista de Verificación de Seguridad</h5>
        </div>
        <div class="card-body p-0">
            <?php if (empty($checklist)): ?>
                <p class="p-4 text-muted">No se encontraron elementos en la lista.</p>
            <?php else: ?>
                <?php foreach ($checklist as $category): ?>
                    <?php
                        $checkedCount = 0;
                        foreach ($category['items'] as $item) {
                            if ($item['is_checked']) $checkedCount++;
                        }
                    ?>
                    <div class="category-section" data-category-id="<?= $category['category_id'] ?>">
                        <div class="category-header p-3 border-bottom d-flex justify-content-between align-items-center" style="background-color: var(--primary); color: white; font-weight: 600; cursor: pointer;">
                            <div class="d-flex align-items-center flex-grow-1" data-bs-toggle="collapse" data-bs-target="#category-<?= $category['category_id'] ?>">
                                <i class="bi bi-chevron-down me-2 collapse-icon"></i>
                                <h6 class="mb-0"><?= htmlspecialchars($category['category_name']) ?></h6>
                                <small class="ms-3 opacity-75">(<?= $checkedCount ?>/<?= count($category['items']) ?>)</small>
                            </div>
                            <button type="button" class="btn btn-sm btn-light check-all-category" 
                                    data-category-id="<?= $category['category_id'] ?>"
                                    data-target-id="<?= $target['id'] ?>"
                                    title="Marcar todos">
                                <i class="bi bi-check-all"></i> Marcar Todos
                            </button>
                        </div>
                        <div id="category-<?= $category['category_id'] ?>" class="collapse show category-items">
                        <?php foreach ($category['items'] as $item): ?>
                            <div class="checklist-item <?= $item['is_checked'] ? 'checked' : '' ?>">
                                <div class="row align-items-start">
                                    <div class="col-auto">
                                        <input type="checkbox" 
                                               class="form-check-input checklist-toggle" 
                                               data-target-id="<?= $target['id'] ?>"
                                               data-item-id="<?= $item['checklist_item_id'] ?>"
                                               <?= $item['is_checked'] ? 'checked' : '' ?>>
                                    </div>
                                    <div class="col">
                                        <strong><?= htmlspecialchars($item['title']) ?></strong>
                                        
                                        <!-- Description Section -->
                                        <div class="description-section mt-2 mb-2">
                                            <div class="description-view small text-muted markdown-content">
                                                <div class="d-flex justify-content-between align-items-start">
                                                    <div>
                                                        <?php if (!empty($item['description'])): ?>
                                                            <?= $parsedown->text($item['description']) ?>
                                                        <?php else: ?>
                                                            <em>Sin descripción</em>
                                                        <?php endif; ?>
                                                    </div>
                                                    <button type="button" class="btn btn-sm btn-link edit-description-btn ms-2" 
                                                            data-target-id="<?= $target['id'] ?>"
                                                            data-item-id="<?= $item['checklist_item_id'] ?>"
                                                            title="Editar descripción">
                                                        <i class="bi bi-pencil"></i>
                                                    </button>
                                                </div>
                                            </div>
                                            <div class="description-edit d-none">
                                                <textarea class="form-control form-control-sm description-textarea" 
                                                          placeholder="Escribir descripción..." 
                                                          rows="3"><?= htmlspecialchars($item['description'] ?? '') ?></textarea>
                                                <div class="mt-2 d-flex gap-2">
                                                    <button type="button" class="btn btn-sm btn-success save-description" 
                                                            data-target-id="<?= $target['id'] ?>"
                                                            data-item-id="<?= $item['checklist_item_id'] ?>">
                                                        <i class="bi bi-check"></i> Guardar
                                                    </button>
                                                    <button type="button" class="btn btn-sm btn-secondary cancel-description">
                                                        <i class="bi bi-x"></i> Cancelar
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                        
                                        <!-- Notes Section -->
                                        <textarea class="form-control form-control-sm checklist-notes" 
                                                  data-target-id="<?= $target['id'] ?>"
                                                  data-item-id="<?= $item['checklist_item_id'] ?>"
                                                  placeholder="Añadir notas..."
                                                  rows="2"><?= htmlspecialchars($item['notes'] ?? '') ?></textarea>
                                    </div>
                                </div>
                            </div>
                        <?php endforeach; ?>
                        </div>
                    </div>
                <?php endforeach; ?>
            <?php endif; ?>
        </div>
    </div>
</div>
