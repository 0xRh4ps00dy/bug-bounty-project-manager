<?php $active = 'targets'; $title = htmlspecialchars($target['target']) . ' - Bug Bounty Project Manager'; ?>

<div class="container">
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="/targets">Targets</a></li>
            <li class="breadcrumb-item active"><?= htmlspecialchars($target['target']) ?></li>
        </ol>
    </nav>
    
    <div class="card mb-4">
        <div class="card-body">
            <h1 class="mb-3"><?= htmlspecialchars($target['target']) ?></h1>
            <p class="text-muted"><?= htmlspecialchars($target['description'] ?? '') ?></p>
            
            <div class="row mt-4">
                <div class="col-md-2">
                    <strong>Project:</strong><br>
                    <a href="/projects/<?= $target['project_id'] ?>"><?= htmlspecialchars($target['project_name']) ?></a>
                </div>
                <div class="col-md-2">
                    <strong>Type:</strong><br>
                    <span class="badge bg-<?= $target['target_type'] === 'url' ? 'primary' : ($target['target_type'] === 'ip' ? 'info' : 'secondary') ?>">
                        <?= ucfirst(htmlspecialchars($target['target_type'])) ?>
                    </span>
                </div>
                <div class="col-md-2">
                    <strong>Status:</strong><br>
                    <span class="badge bg-<?= $target['status'] === 'active' ? 'success' : 'secondary' ?>">
                        <?= htmlspecialchars($target['status'] ?? 'active') ?>
                    </span>
                </div>
                <div class="col-md-2">
                    <strong>Progress:</strong><br>
                    <span class="completed-count"><?= $target['completed_items'] ?? 0 ?></span> / <?= $target['total_items'] ?? 0 ?>
                </div>
                <div class="col-md-4">
                    <div class="progress" style="height: 30px;" data-target-id="<?= $target['id'] ?>">
                        <div class="progress-bar" role="progressbar" style="width: <?= $target['progress'] ?? 0 ?>%">
                            <?= round($target['progress'] ?? 0) ?>%
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="card">
        <div class="card-header">
            <h5 class="mb-0"><i class="bi bi-list-check"></i> Security Checklist</h5>
        </div>
        <div class="card-body p-0">
            <?php if (empty($checklist)): ?>
                <p class="p-4 text-muted">No checklist items found.</p>
            <?php else: ?>
                <?php foreach ($checklist as $category): ?>
                    <div class="category-section">
                        <div class="p-3 border-bottom" style="background-color: var(--primary); color: white; font-weight: 600;">
                            <h6 class="mb-0"><?= htmlspecialchars($category['category_name']) ?></h6>
                        </div>
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
                                        <p class="text-muted mb-2 small"><?= htmlspecialchars($item['description'] ?? '') ?></p>
                                        <textarea class="form-control form-control-sm checklist-notes" 
                                                  data-target-id="<?= $target['id'] ?>"
                                                  data-item-id="<?= $item['checklist_item_id'] ?>"
                                                  placeholder="Add notes..."
                                                  rows="2"><?= htmlspecialchars($item['notes'] ?? '') ?></textarea>
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
