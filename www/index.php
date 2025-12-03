<!DOCTYPE html>
<html lang="ca">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LAMP Stack - Funcionant!</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        h2 { color: #666; margin-top: 30px; }
        .success { color: #28a745; }
        .error { color: #dc3545; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #007bff;
            color: white;
        }
        .info-box {
            background-color: #e7f3ff;
            border-left: 4px solid #007bff;
            padding: 15px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 LAMP Stack amb Docker</h1>
        
        <div class="info-box">
            <strong>PHP Version:</strong> <?php echo phpversion(); ?>
        </div>

        <h2>Informació del Sistema</h2>
        <ul>
            <li><strong>Servidor:</strong> <?php echo $_SERVER['SERVER_SOFTWARE']; ?></li>
            <li><strong>Sistema Operatiu:</strong> <?php echo PHP_OS; ?></li>
            <li><strong>Document Root:</strong> <?php echo $_SERVER['DOCUMENT_ROOT']; ?></li>
        </ul>

        <h2>Connexió a MySQL</h2>
        <?php
        $host = 'db';
        $dbname = 'bbpm_db';
        $username = 'bbpm_user';
        $password = 'bbpm_password';

        try {
            $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            echo '<p class="success">✓ Connexió a MySQL exitosa!</p>';
            
            // Obtenir usuaris de la base de dades
            $stmt = $pdo->query("SELECT * FROM users");
            $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            if (count($users) > 0) {
                echo '<h2>Usuaris a la Base de Dades</h2>';
                echo '<table>';
                echo '<tr><th>ID</th><th>Nom</th><th>Email</th><th>Data de Creació</th></tr>';
                foreach ($users as $user) {
                    echo '<tr>';
                    echo '<td>' . htmlspecialchars($user['id']) . '</td>';
                    echo '<td>' . htmlspecialchars($user['name']) . '</td>';
                    echo '<td>' . htmlspecialchars($user['email']) . '</td>';
                    echo '<td>' . htmlspecialchars($user['created_at']) . '</td>';
                    echo '</tr>';
                }
                echo '</table>';
            }
            
        } catch(PDOException $e) {
            echo '<p class="error">✗ Error de connexió: ' . $e->getMessage() . '</p>';
        }
        ?>

        <h2>Extensions PHP Carregades</h2>
        <p><?php echo implode(', ', get_loaded_extensions()); ?></p>

        <div class="info-box" style="margin-top: 30px;">
            <strong>Accés a phpMyAdmin:</strong> <a href="http://localhost:8080" target="_blank">http://localhost:8080</a>
        </div>
    </div>
</body>
</html>
