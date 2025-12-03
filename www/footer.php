        </div>
    </div>

    <footer class="footer text-center">
        <div class="container">
            <p class="mb-0">Bug Bounty Project Manager &copy; <?php echo date('Y'); ?></p>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Confirmar eliminació
        function confirmDelete(message = '¿Estàs segur que vols eliminar aquest element?') {
            return confirm(message);
        }

        // Auto-hide alerts
        setTimeout(function() {
            let alerts = document.querySelectorAll('.alert');
            alerts.forEach(function(alert) {
                let bsAlert = new bootstrap.Alert(alert);
                bsAlert.close();
            });
        }, 5000);
    </script>
</body>
</html>
