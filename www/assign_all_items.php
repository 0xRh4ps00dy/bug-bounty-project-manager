<?php
// Script per assignar tots els checklist items als targets existents
require_once 'config.php';

$pdo = getConnection();

echo "=== Assignant tots els checklist items als targets existents ===\n\n";

// Obtenir tots els targets
$targets = $pdo->query("SELECT id, name FROM targets")->fetchAll();

// Obtenir tots els checklist items
$items = $pdo->query("SELECT id FROM checklist_items")->fetchAll();

echo "Total targets: " . count($targets) . "\n";
echo "Total checklist items: " . count($items) . "\n\n";

foreach ($targets as $target) {
    echo "Processant Target #{$target['id']} - {$target['name']}...\n";
    
    $inserted = 0;
    $skipped = 0;
    
    foreach ($items as $item) {
        // Verificar si ja existeix
        $check = $pdo->prepare("SELECT COUNT(*) FROM target_checklist WHERE target_id = ? AND checklist_item_id = ?");
        $check->execute([$target['id'], $item['id']]);
        
        if ($check->fetchColumn() == 0) {
            // No existeix, inserir
            $insert = $pdo->prepare("INSERT INTO target_checklist (target_id, checklist_item_id) VALUES (?, ?)");
            $insert->execute([$target['id'], $item['id']]);
            $inserted++;
        } else {
            $skipped++;
        }
    }
    
    echo "  ✓ {$inserted} items afegits, {$skipped} ja existien\n\n";
}

echo "=== Procés completat ===\n";
