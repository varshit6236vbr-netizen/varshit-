from fastapi import FastAPI, Depends, HTTPException, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse, StreamingResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import create_engine, Column, String, Float, DateTime
from sqlalchemy.orm import sessionmaker, Session, declarative_base
from datetime import datetime
import uuid
import csv
import io

# 1. DATABASE CONFIGURATION
DATABASE_URL = "postgresql://postgres:2066@localhost:5432/ims_db"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 2. DATA MODELS
class User(Base):
    __tablename__ = "Users"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String, unique=True, index=True)
    password = Column(String)

class Product(Base):
    __tablename__ = "Product"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    sku = Column(String, unique=True, index=True)
    name = Column(String)
    category = Column(String)
    uom = Column(String)
    location = Column(String, default="Main Warehouse") 
    quantity = Column(Float, default=0.0)
    unit_price = Column(Float, default=0.0)

class StockTransaction(Base):
    __tablename__ = "StockTransaction"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    sku = Column(String)
    type = Column(String) # INWARD or OUTWARD
    quantity = Column(Float)
    timestamp = Column(DateTime, default=datetime.utcnow)

# Initialize Database Tables
Base.metadata.create_all(bind=engine)

# Admin Bootstrapper
with SessionLocal() as db_init:
    if not db_init.query(User).filter(User.username == "admin").first():
        db_init.add(User(username="admin", password="password123"))
        db_init.commit()

# 3. APP & TEMPLATE SETUP
app = FastAPI(title="Modular IMS - Presentation Build")
templates = Jinja2Templates(directory="templates")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- 4. AUTHENTICATION & SECURITY ---

@app.get("/login", response_class=HTMLResponse)
def login_page(request: Request):
    return templates.TemplateResponse("login.html", {"request": request})

@app.post("/login")
def login(username: str = Form(...), password: str = Form(...), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == username, User.password == password).first()
    if user:
        # SIMPLIFIED FOR PRESENTATION: OTP is now fixed to 123456
        print(f"\n🔐 [SECURITY NOTICE] LOGIN ATTEMPT: {username} | OTP IS: 123456\n")
        return RedirectResponse(url=f"/verify-otp?user={username}", status_code=303)
    return RedirectResponse(url="/login", status_code=303)

@app.get("/verify-otp", response_class=HTMLResponse)
def verify_otp_page(request: Request, user: str):
    return templates.TemplateResponse("otp.html", {"request": request, "username": user})

@app.post("/verify-otp")
def verify_otp(username: str = Form(...), otp_input: str = Form(...)):
    # Check against the fixed presentation code
    if otp_input == "123456":
        response = RedirectResponse(url="/", status_code=303)
        response.set_cookie(key="user_session", value=username, httponly=True)
        return response
    return RedirectResponse(url=f"/verify-otp?user={username}", status_code=303)

@app.get("/logout")
def logout():
    response = RedirectResponse(url="/login", status_code=303)
    response.delete_cookie("user_session")
    return response

# --- 5. DASHBOARD & ANALYTICS ---

@app.get("/", response_class=HTMLResponse)
def dashboard(request: Request, db: Session = Depends(get_db)):
    session = request.cookies.get("user_session")
    if not session:
        return RedirectResponse(url="/login")
    
    products = db.query(Product).order_by(Product.name).all()
    
    # Robust calculation: handles None/Null values safely
    total_val = sum((p.quantity or 0) * (p.unit_price or 0) for p in products)
    
    history = db.query(StockTransaction).order_by(StockTransaction.timestamp.desc()).limit(15).all()
    low_stock = db.query(Product).filter(Product.quantity < 10).count()
    
    return templates.TemplateResponse("index.html", {
        "request": request, 
        "products": products, 
        "history": history,
        "low_stock": low_stock, 
        "total_value": f"{total_val:,.2f}"
    })

# --- 6. CORE INVENTORY LOGIC ---

@app.post("/ui/quick-update")
async def ui_quick_update(sku: str = Form(...), amount: float = Form(...), action: str = Form(...), db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.sku == sku).first()
    if product:
        if action == "receipt":
            product.quantity += amount
            db.add(StockTransaction(sku=sku, type="INWARD", quantity=amount))
        elif action == "issue" and product.quantity >= amount:
            product.quantity -= amount
            db.add(StockTransaction(sku=sku, type="OUTWARD", quantity=amount))
        db.commit()
    return RedirectResponse(url="/", status_code=303)

@app.post("/ui/add-product")
async def ui_add_product(
    sku: str = Form(...), 
    name: str = Form(...), 
    category: str = Form(...), 
    uom: str = Form(...), 
    location: str = Form(...), 
    unit_price: float = Form(...), 
    db: Session = Depends(get_db)
):
    if not db.query(Product).filter(Product.sku == sku).first():
        db.add(Product(sku=sku, name=name, category=category, uom=uom, location=location, unit_price=unit_price))
        db.commit()
    return RedirectResponse(url="/", status_code=303)

@app.get("/ui/delete/{sku}")
async def ui_delete_product(sku: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.sku == sku).first()
    if product:
        db.delete(product)
        db.commit()
    return RedirectResponse(url="/", status_code=303)

@app.get("/ui/download-report")
def download_report(db: Session = Depends(get_db)):
    products = db.query(Product).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["SKU", "Name", "Category", "Location", "Quantity", "UOM", "Unit Price", "Total Value"])
    
    for p in products:
        qty = p.quantity or 0
        prc = p.unit_price or 0
        writer.writerow([p.sku, p.name, p.category, p.location, qty, p.uom, prc, (qty * prc)])
    
    output.seek(0)
    return StreamingResponse(
        io.BytesIO(output.getvalue().encode()), 
        media_type="text/csv", 
        headers={"Content-Disposition": f"attachment; filename=IMS_Financial_Report_{datetime.now().strftime('%Y%m%d')}.csv"}
    )
