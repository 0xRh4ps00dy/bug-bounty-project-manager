<?php
// Test per verificar la creació de targets amb checklist completa
require_once 'config.php';

$pdo = getConnection();

echo "=== Test de Creació de Target ===\n\n";

// Comptar checklist items totals
$totalItems = $pdo->query("SELECT COUNT(*) FROM checklist_items")->fetchColumn();
echo "Total checklist items disponibles: $totalItems\n\n";

// Comptar targets existents
$totalTargets = $pdo->query("SELECT COUNT(*) FROM targets")->fetchColumn();
echo "Total targets existents: $totalTargets\n\n";

// Verificar assignació d'items per target
echo "=== Verificació d'Items per Target ===\n\n";

$targets = $pdo->query("
    SELECT t.id, t.name, COUNT(tc.id) as items_assignats
    FROM targets t
    LEFT JOIN target_checklist tc ON t.id = tc.target_id
    GROUP BY t.id
    ORDER BY t.id
")->fetchAll();

foreach ($targets as $target) {
    $percentage = $totalItems > 0 ? round(($target['items_assignats'] / $totalItems) * 100, 2) : 0;
    echo "Target #{$target['id']} - {$target['name']}\n";
    echo "  Items assignats: {$target['items_assignats']} / $totalItems ($percentage%)\n";
    
    if ($target['items_assignats'] == $totalItems) {
        echo "  ✓ Checklist completa!\n";
    } else {
        echo "  ⚠ ATENCIÓ: Falten " . ($totalItems - $target['items_assignats']) . " items\n";
    }
    echo "\n";
}

// Verificar triggers
echo "=== Verificació de Triggers ===\n\n";
$triggers = $pdo->query("SHOW TRIGGERS LIKE 'target_checklist'")->fetchAll();
echo "Triggers actius: " . count($triggers) . "\n";
foreach ($triggers as $trigger) {
    echo "  - {$trigger['Trigger']}\n";
}

echo "\n=== Test Finalitzat ===\n";
