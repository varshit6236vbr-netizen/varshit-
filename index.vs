<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>IMS | Unified Control Center</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <style>
        body { background-color: #f0f2f5; font-family: 'Segoe UI', sans-serif; }
        .glass-card { background: white; border-radius: 15px; border: none; box-shadow: 0 10px 30px rgba(0,0,0,0.05); }
        .scroll-box { max-height: 300px; overflow-y: auto; }
        .btn-export { border-radius: 8px; font-weight: 500; }
        .location-badge { font-size: 0.75rem; background-color: #e9ecef; color: #495057; border-radius: 4px; padding: 2px 6px; }
        .kpi-value { font-size: 1.8rem; font-weight: 700; color: #212529; }
    </style>
</head>
<body class="p-4">

    <div class="container">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="fw-bold text-dark m-0">📦 Inventory Control Center</h1>
                <p class="text-muted mb-0">Logged in as: <strong>Admin</strong></p>
            </div>
            <div class="d-flex gap-2">
                <a href="/ui/download-report" class="btn btn-outline-primary btn-export">📊 Export Excel</a>
                <a href="/logout" class="btn btn-danger btn-export">🚪 Logout</a>
            </div>
        </div>

        <div class="row mb-4">
            <div class="col-md-6">
                <div class="glass-card p-4 border-start border-primary border-5">
                    <small class="text-muted text-uppercase fw-bold">Total Inventory Value</small>
                    <div class="kpi-value">₹ {{ total_value }}</div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="glass-card p-4 border-start border-danger border-5">
                    <small class="text-muted text-uppercase fw-bold">Low Stock Alerts</small>
                    <div class="kpi-value text-danger">{{ low_stock }} <span style="font-size: 1rem; color: #6c757d;">Items Below 10 Qty</span></div>
                </div>
            </div>
        </div>

        <div class="glass-card p-4 mb-4">
            <h5 class="fw-bold mb-3">🆕 Register New Item</h5>
            <form action="/ui/add-product" method="post" class="row g-3">
                <div class="col-md-2"><input type="text" name="sku" class="form-control" placeholder="SKU" required></div>
                <div class="col-md-2"><input type="text" name="name" class="form-control" placeholder="Product Name" required></div>
                <div class="col-md-2"><input type="text" name="category" class="form-control" placeholder="Category" required></div>
                <div class="col-md-2"><input type="text" name="location" class="form-control" placeholder="Loc (e.g. Rack A)" required></div>
                <div class="col-md-1"><input type="number" step="0.01" name="unit_price" class="form-control" placeholder="Price ₹" required></div>
                <div class="col-md-1"><input type="text" name="uom" class="form-control" placeholder="UOM" required></div>
                <div class="col-md-2"><button type="submit" class="btn btn-primary w-100">Register</button></div>
            </form>
        </div>

        <div class="glass-card p-4 mb-4">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h5 class="fw-bold m-0 text-primary">Live Stock Levels</h5>
                <input type="text" id="searchInput" onkeyup="filterTable()" class="form-control w-25" placeholder="🔍 Search SKU or Name...">
            </div>
            
            <table class="table table-hover align-middle" id="inventoryTable">
                <thead class="table-light">
                    <tr>
                        <th>PRODUCT & LOCATION</th>
                        <th class="text-center">UNIT PRICE</th>
                        <th class="text-center">QUANTITY</th>
                        <th class="text-center">STOCK VALUE</th>
                        <th class="text-center">DELIVERY / RECEIPT</th>
                        <th class="text-end">MANAGE</th>
                    </tr>
                </thead>
                <tbody>
                    {% for p in products %}
                    <tr>
                        <td>
                            <div class="fw-bold">{{ p.name }}</div>
                            <div class="d-flex gap-2 align-items-center">
                                <small class="text-muted">SKU: {{ p.sku }} | {{ p.category }}</small>
                                <span class="location-badge">📍 {{ p.location }}</span>
                            </div>
                        </td>
                        <td class="text-center text-muted">₹ {{ p.unit_price }}</td>
                        <td class="text-center">
                            <h4 class="mb-0 {% if p.quantity < 10 %}text-danger font-weight-bold{% endif %}">
                                {{ p.quantity }}
                            </h4>
                            <small class="text-muted">{{ p.uom }}</small>
                        </td>
                        <td class="text-center fw-bold text-success">₹ {{ "%.2f"|format(p.quantity * p.unit_price) }}</td>
                        <td class="text-center">
                            <form action="/ui/quick-update" method="post" class="d-inline-flex gap-2">
                                <input type="hidden" name="sku" value="{{ p.sku }}">
                                <input type="number" name="amount" class="form-control form-control-sm" style="width: 70px;" placeholder="Qty" required>
                                <button type="submit" name="action" value="receipt" class="btn btn-sm btn-success">+ In</button>
                                <button type="submit" name="action" value="issue" class="btn btn-sm btn-outline-danger">- Out</button>
                            </form>
                        </td>
                        <td class="text-end">
                            <a href="/ui/delete/{{ p.sku }}" class="btn btn-sm btn-outline-secondary" onclick="return confirm('Permanently delete this product?')">🗑️</a>
                        </td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>

        <div class="glass-card p-4">
            <h5 class="fw-bold mb-3 text-secondary">📜 Recent Move History (Ledger)</h5>
            <div class="scroll-box">
                <table class="table table-sm text-muted">
                    <thead class="table-light">
                        <tr>
                            <th>Time</th>
                            <th>SKU</th>
                            <th>Operation</th>
                            <th>Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for log in history %}
                        <tr>
                            <td>{{ log.timestamp.strftime('%H:%M:%S') }}</td>
                            <td><code>{{ log.sku }}</code></td>
                            <td>
                                <span class="badge {% if log.type == 'INWARD' %}bg-success-subtle text-success{% else %}bg-danger-subtle text-danger{% endif %}">
                                    {{ log.type }}
                                </span>
                            </td>
                            <td><strong>{{ log.quantity }}</strong></td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        function filterTable() {
            let filter = document.getElementById("searchInput").value.toUpperCase();
            let tr = document.getElementById("inventoryTable").getElementsByTagName("tr");
            for (let i = 1; i < tr.length; i++) {
                let text = tr[i].textContent.toUpperCase();
                tr[i].style.display = (text.indexOf(filter) > -1) ? "" : "none";
            }
        }
    </script>
</body>
</html>
