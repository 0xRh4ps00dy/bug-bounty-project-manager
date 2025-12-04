<?php $active = 'targets'; ?>

<div class="container mt-4">
    <nav aria-label="breadcrumb" class="mb-3">
        <ol class="breadcrumb mb-0">
            <li class="breadcrumb-item"><a href="/targets">Objetivos</a></li>
            <li class="breadcrumb-item"><a href="/targets/<?= $target['id'] ?>"><?= htmlspecialchars($target['target']) ?></a></li>
            <li class="breadcrumb-item active">Notas</li>
        </ol>
    </nav>
    
    <div class="card shadow-sm">
        <div class="card-header bg-primary text-white">
            <h3 class="mb-0">
                <i class="bi bi-sticky-fill"></i> Notas de <?= htmlspecialchars($target['target']) ?>
            </h3>
        </div>
        <div class="card-body p-2">
            <?php if (!empty($notesByCategory)): ?>
                <?php foreach ($notesByCategory as $index => $category): ?>
                    <h5 class="text-primary pb-1 mb-1" style="border-bottom: 2px solid var(--primary); font-size: 1rem;">
                        <i class="bi bi-folder-fill"></i> <?= htmlspecialchars($category['category_name']) ?>
                    </h5>
                    
                    <?php if (!empty($category['items'])): ?>
                        <?php foreach ($category['items'] as $item): ?>
                            <div class="card mb-1 border-left-primary" style="margin-bottom: 0.5rem;">
                                <div class="card-header bg-primary bg-opacity-10 py-1 px-2" style="padding: 0.5rem 0.75rem;">
                                    <h6 class="mb-0 text-white fw-bold" style="font-size: 0.9rem;">
                                        <i class="bi bi-check-circle<?= $item['is_checked'] ? '-fill' : '' ?>"></i>
                                        <?= htmlspecialchars($item['title']) ?>
                                    </h6>
                                </div>
                                <div class="card-body p-2" style="padding: 0.5rem 0.75rem;">
                                    <?php if (!empty($item['notes'])): ?>
                                        <?php 
                                            // Limpiar agresivamente espacios en blanco
                                            $cleanedNotes = trim($item['notes']);
                                            $cleanedNotes = preg_replace('/\s+/', ' ', $cleanedNotes);
                                        ?>
                                        <div style="background-color: var(--bg-secondary); padding: 0.5rem; border-radius: 0.25rem; word-wrap: break-word; word-break: break-word; line-height: 1.4; font-size: 0.9rem; color: var(--text-primary);">
                                            <?= htmlspecialchars($cleanedNotes) ?>
                                        </div>
                                    <?php else: ?>
                                        <em class="text-muted" style="font-size: 0.9rem;">Sin notas</em>
                                    <?php endif; ?>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                    <?php if ($index < count($notesByCategory) - 1): ?>
                        <div style="margin-top: 0.75rem;"></div>
                    <?php endif; ?>
                <?php endforeach; ?>
            <?php endif; ?>
        </div>
    </div>
</div>

<style>
.border-left-primary {
    border-left: 4px solid var(--primary) !important;
}

.card-header.bg-primary.bg-opacity-10 {
    background-color: rgba(13, 110, 253, 0.1) !important;
}

[data-theme="dark"] .card-header.bg-primary.bg-opacity-10 {
    background-color: rgba(90, 158, 255, 0.15) !important;
}

[data-theme="dark"] .card {
    background-color: var(--bg-primary);
    border-color: var(--border-color);
}
</style>
