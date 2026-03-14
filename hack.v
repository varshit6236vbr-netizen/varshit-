<!DOCTYPE html>
<html>
<head>
<title>Smart Warehouse Inventory</title>

<style>

*{
margin:0;
padding:0;
box-sizing:border-box;
font-family:Arial;
}

body{
background:#f1f5f9;
}

.login{
width:350px;
margin:120px auto;
background:white;
padding:30px;
border-radius:10px;
box-shadow:0 4px 12px rgba(0,0,0,0.15);
}

.login h2{
text-align:center;
margin-bottom:20px;
}

input{
width:100%;
padding:10px;
margin:8px 0;
border:1px solid #ccc;
border-radius:5px;
}

button{
width:100%;
padding:10px;
background:#2563eb;
border:none;
color:white;
border-radius:5px;
cursor:pointer;
}

button:hover{
background:#1d4ed8;
}

.link{
text-align:center;
margin-top:10px;
color:blue;
cursor:pointer;
}

.sidebar{
width:230px;
background:#0f172a;
color:white;
height:100vh;
position:fixed;
padding-top:20px;
}

.sidebar h2{
text-align:center;
margin-bottom:20px;
}

.sidebar a{
display:block;
padding:12px;
color:white;
text-decoration:none;
}

.sidebar a:hover{
background:#1e293b;
}

.main{
margin-left:230px;
padding:30px;
}

.cards{
display:flex;
gap:20px;
}

.card{
background:white;
padding:20px;
border-radius:8px;
box-shadow:0 3px 8px rgba(0,0,0,0.1);
width:200px;
}

.card h3{
font-size:18px;
margin-bottom:10px;
}

.section{
display:none;
}

.active{
display:block;
}

table{
width:100%;
margin-top:20px;
border-collapse:collapse;
background:white;
}

th,td{
padding:12px;
border-bottom:1px solid #ddd;
text-align:left;
}

th{
background:#e2e8f0;
}

.form{
margin-top:15px;
display:flex;
gap:10px;
flex-wrap:wrap;
}

.form input{
width:200px;
}

.logout{
margin-top:20px;
background:red;
}

</style>
</head>

<body>

<!-- LOGIN -->

<div id="loginPage" class="login">

<h2>Inventory Login</h2>

<input id="loginUser" placeholder="Username">
<input id="loginPass" type="password" placeholder="Password">

<button onclick="login()">Login</button>

<p class="link" onclick="showSignup()">Create Account</p>

</div>


<!-- SIGNUP -->

<div id="signupPage" class="login" style="display:none">

<h2>Create Account</h2>

<input id="signupUser" placeholder="Username">
<input id="signupPass" type="password" placeholder="Password">

<button onclick="signup()">Signup</button>

<p class="link" onclick="showLogin()">Back to Login</p>

</div>


<!-- APP -->

<div id="app" style="display:none">

<div class="sidebar">

<h2>Warehouse</h2>

<a onclick="showSection('dashboard')">Dashboard</a>
<a onclick="showSection('products')">Products</a>
<a onclick="showSection('receipts')">Receipts</a>
<a onclick="showSection('delivery')">Delivery</a>
<a onclick="showSection('adjust')">Adjustment</a>

<button class="logout" onclick="logout()">Logout</button>

</div>


<div class="main">

<!-- DASHBOARD -->

<div id="dashboard" class="section active">

<h1>Inventory Dashboard</h1>

<div class="cards">

<div class="card">
<h3>Total Products</h3>
<p id="totalProducts">0</p>
</div>

<div class="card">
<h3>Total Stock</h3>
<p id="totalStock">0</p>
</div>

<div class="card">
<h3>Low Stock</h3>
<p id="lowStock">0</p>
</div>

</div>

</div>


<!-- PRODUCTS -->

<div id="products" class="section">

<h1>Product Management</h1>

<div class="form">

<input id="name" placeholder="Product Name">
<input id="sku" placeholder="SKU">
<input id="category" placeholder="Category">
<input id="stock" placeholder="Initial Stock">

<button onclick="addProduct()">Add Product</button>

</div>

<table>

<thead>

<tr>
<th>Name</th>
<th>SKU</th>
<th>Category</th>
<th>Stock</th>
</tr>

</thead>

<tbody id="productTable"></tbody>

</table>

</div>


<!-- RECEIPTS -->

<div id="receipts" class="section">

<h1>Incoming Stock</h1>

<div class="form">

<input id="receiptSku" placeholder="SKU">
<input id="receiptQty" placeholder="Quantity">

<button onclick="receiveStock()">Receive</button>

</div>

</div>


<!-- DELIVERY -->

<div id="delivery" class="section">

<h1>Delivery Orders</h1>

<div class="form">

<input id="deliverySku" placeholder="SKU">
<input id="deliveryQty" placeholder="Quantity">

<button onclick="deliverStock()">Deliver</button>

</div>

</div>


<!-- ADJUSTMENT -->

<div id="adjust" class="section">

<h1>Stock Adjustment</h1>

<div class="form">

<input id="adjustSku" placeholder="SKU">
<input id="adjustQty" placeholder="New Quantity">

<button onclick="adjustStock()">Adjust</button>

</div>

</div>

</div>

</div>


<script>

let users = JSON.parse(localStorage.getItem("users")) || [];
let products = JSON.parse(localStorage.getItem("products")) || [];

function showSignup(){
loginPage.style.display="none";
signupPage.style.display="block";
}

function showLogin(){
signupPage.style.display="none";
loginPage.style.display="block";
}

function signup(){

users.push({
user:signupUser.value,
pass:signupPass.value
});

localStorage.setItem("users",JSON.stringify(users));

alert("Account created");

showLogin();

}

function login(){

let u=loginUser.value;
let p=loginPass.value;

let user=users.find(x=>x.user==u && x.pass==p);

if(user){

loginPage.style.display="none";
app.style.display="block";

render();

}else{

alert("Invalid login");

}

}

function logout(){

app.style.display="none";
loginPage.style.display="block";

}

function showSection(id){

document.querySelectorAll(".section").forEach(s=>s.classList.remove("active"));

document.getElementById(id).classList.add("active");

}

function save(){

localStorage.setItem("products",JSON.stringify(products));

render();

}

function render(){

let table=document.getElementById("productTable");
table.innerHTML="";

let total=0;
let low=0;

products.forEach(p=>{

total+=p.stock;

if(p.stock<5) low++;

table.innerHTML+=`
<tr>
<td>${p.name}</td>
<td>${p.sku}</td>
<td>${p.category}</td>
<td>${p.stock}</td>
</tr>
`;

});

totalProducts.innerText=products.length;
totalStock.innerText=total;
lowStock.innerText=low;

}

function addProduct(){

products.push({
name:name.value,
sku:sku.value,
category:category.value,
stock:Number(stock.value)
});

save();

}

function receiveStock(){

let p=products.find(x=>x.sku==receiptSku.value);

if(p){

p.stock+=Number(receiptQty.value);

save();

}

}

function deliverStock(){

let p=products.find(x=>x.sku==deliverySku.value);

if(p){

p.stock-=Number(deliveryQty.value);

save();

}

}

function adjustStock(){

let p=products.find(x=>x.sku==adjustSku.value);

if(p){

p.stock=Number(adjustQty.value);

save();

}

}

</script>

</body>
</html>
