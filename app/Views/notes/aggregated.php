<?php $active = 'targets'; ?>

<div class="container-fluid">
    <div class="row">
        <div class="col-md-3">
            <!-- Panel de Navegación de Notas -->
            <div class="card sticky-top" style="top: 20px;">
                <div class="card-header">
                    <h5 class="mb-0"><i class="bi bi-bookmark"></i> Notes Navigation</h5>
                </div>
                <div class="card-body p-0">
                    <nav class="nav flex-column">
                        <a class="nav-link active notes-tab" href="#aggregated" data-bs-toggle="tab">
                            <i class="bi bi-file-text"></i> Aggregated Findings
                        </a>
                        <a class="nav-link notes-tab" href="#by-severity" data-bs-toggle="tab">
                            <i class="bi bi-exclamation-triangle"></i> By Severity
                        </a>
                        <a class="nav-link notes-tab" href="#by-category" data-bs-toggle="tab">
                            <i class="bi bi-tags"></i> By Category
                        </a>
                        <a class="nav-link notes-tab" href="#history" data-bs-toggle="tab">
                            <i class="bi bi-clock-history"></i> History
                        </a>
                        <hr class="my-2">
                        <button class="nav-link text-start" data-export="txt">
                            <i class="bi bi-download"></i> Export TXT
                        </button>
                        <button class="nav-link text-start" data-export="md">
                            <i class="bi bi-download"></i> Export MD
                        </button>
                        <button class="nav-link text-start" data-export="json">
                            <i class="bi bi-download"></i> Export JSON
                        </button>
                        <button class="nav-link text-start" data-export="csv">
                            <i class="bi bi-download"></i> Export CSV
                        </button>
                        <button class="nav-link text-start" data-export="html">
                            <i class="bi bi-download"></i> Export HTML
                        </button>
                    </nav>
                </div>
            </div>
        </div>

        <div class="col-md-9">
            <div class="tab-content">
                <!-- Tab: Aggregated Notes -->
                <div class="tab-pane fade show active" id="aggregated">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="bi bi-file-text"></i> Aggregated Findings</h5>
                        </div>
                        <div class="card-body">
                            <div id="aggregated-notes" class="bg-light p-3 rounded" style="min-height: 300px; max-height: 600px; overflow-y: auto; font-family: monospace; white-space: pre-wrap;">
                                <p class="text-muted">Loading...</p>
                            </div>
                            <div class="mt-3">
                                <button class="btn btn-sm btn-primary" id="refresh-aggregated">
                                    <i class="bi bi-arrow-clockwise"></i> Refresh
                                </button>
                                <button class="btn btn-sm btn-secondary" id="copy-notes">
                                    <i class="bi bi-clipboard"></i> Copy to Clipboard
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Tab: By Severity -->
                <div class="tab-pane fade" id="by-severity">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="bi bi-exclamation-triangle"></i> Findings by Severity</h5>
                        </div>
                        <div class="card-body">
                            <div id="severity-content">
                                <p class="text-muted">Loading...</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Tab: By Category -->
                <div class="tab-pane fade" id="by-category">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="bi bi-tags"></i> Findings by Category</h5>
                        </div>
                        <div class="card-body">
                            <div id="category-content">
                                <p class="text-muted">Loading...</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Tab: History -->
                <div class="tab-pane fade" id="history">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h5 class="mb-0"><i class="bi bi-clock-history"></i> Changes History</h5>
                            <button class="btn btn-sm btn-warning" id="refresh-history">
                                <i class="bi bi-arrow-clockwise"></i> Refresh
                            </button>
                        </div>
                        <div class="card-body p-0">
                            <table class="table table-hover table-sm mb-0">
                                <thead>
                                    <tr>
                                        <th>Date</th>
                                        <th>Item</th>
                                        <th>Type</th>
                                        <th>Severity</th>
                                        <th>Note</th>
                                    </tr>
                                </thead>
                                <tbody id="history-content">
                                    <tr>
                                        <td colspan="5" class="text-muted text-center">Loading...</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const targetId = <?= $targetId ?>;

    // Load aggregated notes
    async function loadAggregatedNotes() {
        try {
            const response = await fetch(`/api/targets/${targetId}/notes`);
            const data = await response.json();
            document.getElementById('aggregated-notes').textContent = data.notes || 'No findings recorded.';
        } catch (error) {
            console.error('Error loading notes:', error);
            document.getElementById('aggregated-notes').textContent = 'Error loading notes.';
        }
    }

    // Load severity breakdown
    async function loadBySeverity() {
        try {
            const response = await fetch(`/api/targets/${targetId}/notes/by-severity`);
            const data = await response.json();
            let html = '';

            const severityColors = {
                critical: 'danger',
                high: 'warning',
                medium: 'info',
                low: 'primary',
                info: 'secondary'
            };

            data.forEach(item => {
                html += `
                    <div class="card mb-3">
                        <div class="card-header bg-${severityColors[item.severity]}">
                            <h6 class="mb-0 text-white">
                                <i class="bi bi-exclamation-triangle"></i>
                                ${item.severity.toUpperCase()} (${item.count})
                            </h6>
                        </div>
                        <div class="card-body">
                            <p class="text-muted">${item.items}</p>
                        </div>
                    </div>
                `;
            });

            document.getElementById('severity-content').innerHTML = html || '<p class="text-muted">No findings by severity.</p>';
        } catch (error) {
            console.error('Error loading severity:', error);
        }
    }

    // Load category breakdown
    async function loadByCategory() {
        try {
            const response = await fetch(`/api/targets/${targetId}/notes/by-category`);
            const data = await response.json();
            let html = '';

            data.forEach(item => {
                const percent = item.total_items > 0 ? Math.round((item.items_with_notes / item.total_items) * 100) : 0;
                html += `
                    <div class="card mb-2">
                        <div class="card-body py-2">
                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="mb-1">${item.category_name}</h6>
                                    <small class="text-muted">
                                        ${item.items_with_notes} findings out of ${item.total_items} items
                                    </small>
                                </div>
                                <div class="text-end">
                                    <div class="progress" style="width: 150px;">
                                        <div class="progress-bar" role="progressbar" 
                                             style="width: ${percent}%"
                                             aria-valuenow="${percent}" aria-valuemin="0" aria-valuemax="100">
                                            ${percent}%
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                `;
            });

            document.getElementById('category-content').innerHTML = html || '<p class="text-muted">No findings by category.</p>';
        } catch (error) {
            console.error('Error loading categories:', error);
        }
    }

    // Load history
    async function loadHistory() {
        try {
            const response = await fetch(`/api/targets/${targetId}/notes/history`);
            const data = await response.json();
            let html = '';

            data.forEach(item => {
                const severityClass = {
                    critical: 'danger',
                    high: 'warning',
                    medium: 'info',
                    low: 'primary',
                    info: 'secondary'
                }[item.severity] || 'secondary';

                html += `
                    <tr>
                        <td>${new Date(item.created_at).toLocaleString()}</td>
                        <td><small>${item.checklist_title}</small></td>
                        <td><span class="badge bg-secondary">${item.change_type}</span></td>
                        <td><span class="badge bg-${severityClass}">${item.severity}</span></td>
                        <td><small class="text-truncate d-block">${item.new_notes || item.old_notes || '-'}</small></td>
                    </tr>
                `;
            });

            document.getElementById('history-content').innerHTML = html || '<tr><td colspan="5" class="text-muted text-center">No history.</td></tr>';
        } catch (error) {
            console.error('Error loading history:', error);
        }
    }

    // Export handler
    document.querySelectorAll('[data-export]').forEach(btn => {
        btn.addEventListener('click', function() {
            const format = this.dataset.export;
            window.location.href = `/targets/${targetId}/notes/export?format=${format}`;
        });
    });

    // Copy to clipboard
    document.getElementById('copy-notes').addEventListener('click', function() {
        const text = document.getElementById('aggregated-notes').textContent;
        navigator.clipboard.writeText(text).then(() => {
            Bug Bounty Project Manager.showSuccess('Copied to clipboard!', 2000);
        });
    });

    // Refresh buttons
    document.getElementById('refresh-aggregated').addEventListener('click', loadAggregatedNotes);
    document.getElementById('refresh-history').addEventListener('click', loadHistory);

    // Tab change handlers
    document.querySelectorAll('.notes-tab').forEach(tab => {
        tab.addEventListener('click', function() {
            const target = this.getAttribute('href');
            setTimeout(() => {
                if (target === '#by-severity') loadBySeverity();
                if (target === '#by-category') loadByCategory();
                if (target === '#history') loadHistory();
            }, 100);
        });
    });

    // Initial load
    loadAggregatedNotes();
});
</script>
