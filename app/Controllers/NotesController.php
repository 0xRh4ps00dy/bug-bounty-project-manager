<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Models\Target;

class NotesController extends Controller
{
    private Target $targetModel;
    
    public function __construct()
    {
        $this->targetModel = new Target();
    }
    
    /**
     * Show notes view
     */
    public function show(int $targetId): void
    {
        $target = $this->targetModel->getWithProgress($targetId);
        
        if (!$target) {
            $this->redirect('/targets');
            return;
        }
        
        $notesByCategory = $this->targetModel->getAggregatedNotesByCategory($targetId);
        
        $this->view('notes.aggregated', [
            'target' => $target,
            'notesByCategory' => $notesByCategory
        ]);
    }
    
    /**
     * Obtener notas agregadas del target
     */
    public function getAggregatedNotes(int $targetId): array
    {
        $notes = $this->targetModel->find($targetId)['aggregated_notes'] ?? '';
        return ['notes' => $notes];
    }
    
    /**
     * Obtener historial de cambios de notas
     */
    public function getHistory(int $targetId): void
    {
        $history = $this->targetModel->getNotesHistory($targetId, 100);
        
        if ($this->isAjax()) {
            $this->json($history);
        }
    }
    
    /**
     * Notas agrupadas por categoría
     */
    public function getByCategory(int $targetId): void
    {
        $data = $this->targetModel->getAggregatedNotesByCategory($targetId);
        
        if ($this->isAjax()) {
            $this->json($data);
        }
    }
    
    /**
     * Notas agrupadas por severidad
     */
    public function getBySeverity(int $targetId): void
    {
        $data = $this->targetModel->getNotesBySeverity($targetId);
        
        if ($this->isAjax()) {
            $this->json($data);
        }
    }
    
    /**
     * Exportar notas a diferentes formatos
     */
    public function export(int $targetId): array|string
    {
        $format = $this->input('format', 'txt'); // txt, md, json, csv, html
        $target = $this->targetModel->getWithProgress($targetId);
        
        if (!$target) {
            return ['error' => 'Target not found'];
        }
        
        $notes = $target['aggregated_notes'] ?? '';
        $history = $this->targetModel->getNotesHistory($targetId, 1000);
        
        switch ($format) {
            case 'md':
                $this->exportMarkdown($target, $notes, $history);
                break;
            case 'json':
                return $this->exportJson($target, $notes, $history);
            case 'csv':
                $this->exportCsv($history);
                break;
            case 'html':
                $this->exportHtml($target, $notes, $history);
                break;
            default:
                $this->exportText($target, $notes, $history);
        }
        
        return [];
    }
    
    private function exportMarkdown($target, $notes, $history): void
    {
        $filename = 'target-' . $target['id'] . '-notes.md';
        header('Content-Type: text/markdown');
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        
        echo "# Bug Bounty Target Report\n\n";
        echo "**Target:** {$target['target']}\n";
        echo "**Target Type:** " . strtoupper($target['target_type']) . "\n";
        echo "**Project:** {$target['project_name']}\n";
        echo "**Status:** {$target['status']}\n";
        echo "**Progress:** {$target['progress']}%\n";
        echo "**Date:** " . date('Y-m-d H:i:s') . "\n\n";
        
        echo "## Aggregated Findings\n\n";
        echo $notes ? $notes : "No findings recorded.\n\n";
        
        echo "## Findings History\n\n";
        foreach ($history as $entry) {
            echo "### " . $entry['checklist_title'] . "\n";
            echo "- **Category:** {$entry['category_name']}\n";
            echo "- **Severity:** " . strtoupper($entry['severity']) . "\n";
            echo "- **Type:** {$entry['change_type']}\n";
            echo "- **Date:** " . $entry['created_at'] . "\n";
            if ($entry['new_notes']) {
                echo "- **Notes:** " . $entry['new_notes'] . "\n\n";
            }
        }
        
        exit;
    }
    
    private function exportJson($target, $notes, $history): array
    {
        return [
            'target' => [
                'id' => $target['id'],
                'target' => $target['target'],
                'target_type' => $target['target_type'],
                'project' => $target['project_name'],
                'status' => $target['status'],
                'progress' => $target['progress'],
                'exportDate' => date('Y-m-d H:i:s')
            ],
            'aggregatedNotes' => $notes,
            'history' => $history
        ];
    }
    
    private function exportCsv($history): void
    {
        $filename = 'findings-history.csv';
        header('Content-Type: text/csv');
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        
        $output = fopen('php://output', 'w');
        
        // Headers
        fputcsv($output, [
            'Date',
            'Item Title',
            'Category',
            'Severity',
            'Change Type',
            'Notes'
        ]);
        
        // Data
        foreach ($history as $entry) {
            fputcsv($output, [
                $entry['created_at'],
                $entry['checklist_title'],
                $entry['category_name'],
                $entry['severity'],
                $entry['change_type'],
                $entry['new_notes'] ?? $entry['old_notes'] ?? ''
            ]);
        }
        
        fclose($output);
        exit;
    }
    
    private function exportHtml($target, $notes, $history): void
    {
        $filename = 'target-' . $target['id'] . '-notes.html';
        header('Content-Type: text/html');
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        
        ?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Bug Bounty Report - <?= htmlspecialchars($target['target']) ?></title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .target-info { background: #f5f5f5; padding: 15px; border-radius: 5px; }
        .findings { margin: 20px 0; }
        .finding { border-left: 4px solid #dc3545; padding: 10px; margin: 10px 0; }
        .finding.high { border-left-color: #ff6b6b; }
        .finding.critical { border-left-color: #c92a2a; }
        .finding.medium { border-left-color: #ffa94d; }
        .finding.low { border-left-color: #74c0fc; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { text-align: left; padding: 10px; border-bottom: 1px solid #ddd; }
        th { background: #333; color: white; }
    </style>
</head>
<body>
    <h1>Bug Bounty Target Report</h1>
    
    <div class="target-info">
        <p><strong>Target:</strong> <?= htmlspecialchars($target['target']) ?></p>
        <p><strong>Target Type:</strong> <?= ucfirst(htmlspecialchars($target['target_type'])) ?></p>
        <p><strong>Project:</strong> <?= htmlspecialchars($target['project_name']) ?></p>
        <p><strong>Status:</strong> <?= htmlspecialchars($target['status']) ?></p>
        <p><strong>Progress:</strong> <?= $target['progress'] ?>%</p>
        <p><strong>Generated:</strong> <?= date('Y-m-d H:i:s') ?></p>
    </div>
    
    <h2>Aggregated Findings</h2>
    <div class="findings">
        <?= nl2br(htmlspecialchars($notes)) ?: '<p>No findings recorded.</p>' ?>
    </div>
    
    <h2>Findings History</h2>
    <table>
        <thead>
            <tr>
                <th>Date</th>
                <th>Item</th>
                <th>Category</th>
                <th>Severity</th>
                <th>Type</th>
                <th>Notes</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($history as $entry): ?>
            <tr class="finding <?= htmlspecialchars($entry['severity']) ?>">
                <td><?= htmlspecialchars($entry['created_at']) ?></td>
                <td><?= htmlspecialchars($entry['checklist_title']) ?></td>
                <td><?= htmlspecialchars($entry['category_name']) ?></td>
                <td><strong><?= strtoupper(htmlspecialchars($entry['severity'])) ?></strong></td>
                <td><?= htmlspecialchars($entry['change_type']) ?></td>
                <td><?= nl2br(htmlspecialchars($entry['new_notes'] ?? $entry['old_notes'] ?? '')) ?></td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</body>
</html>
        <?php
        exit;
    }
    
    private function exportText($target, $notes, $history): void
    {
        $filename = 'target-' . $target['id'] . '-notes.txt';
        header('Content-Type: text/plain');
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        
        echo "BUG BOUNTY TARGET REPORT\n";
        echo str_repeat("=", 60) . "\n\n";
        
        echo "TARGET INFORMATION\n";
        echo str_repeat("-", 60) . "\n";
        echo "Target: {$target['target']}\n";
        echo "Type: " . strtoupper($target['target_type']) . "\n";
        echo "Project: {$target['project_name']}\n";
        echo "Status: {$target['status']}\n";
        echo "Progress: {$target['progress']}%\n";
        echo "Generated: " . date('Y-m-d H:i:s') . "\n\n";
        
        echo "AGGREGATED FINDINGS\n";
        echo str_repeat("-", 60) . "\n";
        echo $notes ? $notes : "No findings recorded.\n\n";
        
        echo "\n\nFINDINGS HISTORY\n";
        echo str_repeat("-", 60) . "\n";
        foreach ($history as $entry) {
            echo "\n[{$entry['created_at']}] {$entry['checklist_title']}\n";
            echo "Category: {$entry['category_name']}\n";
            echo "Severity: " . strtoupper($entry['severity']) . "\n";
            echo "Type: {$entry['change_type']}\n";
            if ($entry['new_notes']) {
                echo "Notes: " . $entry['new_notes'] . "\n";
            }
        }
        
        exit;
    }
}
