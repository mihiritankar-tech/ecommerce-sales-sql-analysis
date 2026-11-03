"""Generate a synthetic e-commerce dataset (reproducible with a fixed seed)."""
import csv, random, datetime as dt
from pathlib import Path

random.seed(42)
OUT = Path(__file__).resolve().parent.parent / "data"
OUT.mkdir(exist_ok=True)

REGIONS = {"Northeast": ["New York", "Boston", "Philadelphia"],
           "Southeast": ["Miami", "Atlanta", "Charlotte"],
           "Midwest": ["Chicago", "Detroit", "Minneapolis"],
           "West": ["Los Angeles", "Seattle", "San Francisco"],
           "Southwest": ["Dallas", "Phoenix", "Houston"]}
REGION_WEIGHT = {"Northeast": 30, "Southeast": 20, "Midwest": 15, "West": 25, "Southwest": 10}
SEGMENTS = [("Consumer", 60), ("Small Business", 30), ("Corporate", 10)]
FIRST = ["James","Maria","David","Priya","Wei","Sofia","Michael","Aisha","Carlos","Emily","Raj","Hannah",
         "Daniel","Fatima","Lucas","Olivia","Ahmed","Grace","Kevin","Mei","Noah","Ana","Ethan","Zara"]
LAST = ["Smith","Garcia","Patel","Chen","Johnson","Kim","Williams","Lopez","Brown","Singh","Davis",
        "Nguyen","Miller","Khan","Wilson","Martinez","Lee","Taylor","Shah","Anderson"]
CATEGORIES = {
    "Electronics": [("Wireless Earbuds",79),("Bluetooth Speaker",59),("Smart Watch",199),("USB-C Hub",45),
                    ("Laptop Stand",39),("Portable Charger",35),("Noise-Cancel Headphones",249),("Webcam HD",69)],
    "Home & Kitchen": [("Coffee Maker",89),("Air Fryer",119),("Blender",65),("Knife Set",75),
                       ("Cookware Set",149),("Desk Lamp",29),("Water Bottle",19),("Throw Blanket",35)],
    "Office Supplies": [("Notebook Pack",12),("Gel Pens (12)",9),("Desk Organizer",24),("Office Chair",229),
                        ("Whiteboard",49),("Paper Shredder",79),("Label Maker",39),("Monitor Arm",89)],
    "Apparel": [("Running Shoes",95),("Hoodie",45),("T-Shirt",19),("Backpack",59),
                ("Rain Jacket",85),("Baseball Cap",22),("Yoga Pants",49),("Wool Socks (3)",18)],
    "Beauty & Health": [("Vitamin D3",15),("Face Moisturizer",28),("Electric Toothbrush",69),("Yoga Mat",32),
                        ("Resistance Bands",25),("Hair Dryer",59),("Sunscreen SPF50",16),("Protein Powder",45)],
}
# margin by category (cost = price * (1 - margin))
MARGIN = {"Electronics":0.25,"Home & Kitchen":0.35,"Office Supplies":0.40,"Apparel":0.50,"Beauty & Health":0.55}

def wchoice(pairs):
    items, w = zip(*pairs); return random.choices(items, weights=w)[0]

# products
products = []
pid = 1
for cat, items in CATEGORIES.items():
    for name, price in items:
        products.append(dict(product_id=pid, product_name=name, category=cat,
                             unit_price=price, unit_cost=round(price*(1-MARGIN[cat]),2)))
        pid += 1
# popularity weights: cheaper items sell more, a few "hero" products
pop = {p["product_id"]: (300/(p["unit_price"]+20)) * random.uniform(0.5, 1.8) for p in products}

# customers
START, END = dt.date(2024,1,1), dt.date(2025,12,31)
customers = []
for cid in range(1, 801):
    region = wchoice(REGION_WEIGHT.items())
    signup = START + dt.timedelta(days=random.randint(0, (END-START).days - 30))
    customers.append(dict(customer_id=cid, customer_name=f"{random.choice(FIRST)} {random.choice(LAST)}",
                          segment=wchoice(SEGMENTS), city=random.choice(REGIONS[region]), region=region,
                          signup_date=signup.isoformat()))

# seasonality multipliers by month (holiday peak, summer dip)
SEASON = {1:0.85,2:0.8,3:0.95,4:0.95,5:1.0,6:0.9,7:0.85,8:0.95,9:1.0,10:1.05,11:1.45,12:1.6}
CHANNELS = [("Website",55),("Mobile App",35),("Marketplace",10)]
SEG_QTY = {"Consumer":1, "Small Business":2, "Corporate":4}

orders, items = [], []
oid, iid = 1, 1
for c in customers:
    signup = dt.date.fromisoformat(c["signup_date"])
    # loyalty: some customers buy once, some many times
    n_orders = random.choices([1,2,3,4,6,9,14], weights=[35,20,15,10,10,6,4])[0]
    if c["segment"] == "Corporate": n_orders += 2
    for _ in range(n_orders):
        # draw a date after signup, weighted by season, with growth in 2025
        for _try in range(20):
            d = signup + dt.timedelta(days=random.randint(0, (END-signup).days))
            growth = 1.18 if d.year == 2025 else 1.0
            if random.random() < SEASON[d.month]*growth/1.9: break
        status = random.choices(["Delivered","Returned","Cancelled"], weights=[90,6,4])[0]
        orders.append(dict(order_id=oid, customer_id=c["customer_id"], order_date=d.isoformat(),
                           channel=wchoice(CHANNELS), status=status))
        for p in random.sample(products, k=random.choices([1,2,3,4],weights=[50,30,15,5])[0]):
            if random.random() > pop[p["product_id"]]/ (max(pop.values())) + 0.35: continue
            qty = random.randint(1, 2) * SEG_QTY[c["segment"]] if p["unit_price"] < 100 else random.randint(1, SEG_QTY[c["segment"]])
            disc = random.choices([0,0.05,0.10,0.20], weights=[65,15,12,8])[0]
            if d.month in (11,12) and random.random() < 0.4: disc = max(disc, 0.15)
            items.append(dict(order_item_id=iid, order_id=oid, product_id=p["product_id"],
                              quantity=qty, unit_price=p["unit_price"], discount=disc))
            iid += 1
        oid += 1

# drop orders that ended up with no items
have_items = {i["order_id"] for i in items}
orders = [o for o in orders if o["order_id"] in have_items]
orders.sort(key=lambda o: o["order_date"])

def write(name, rows):
    with open(OUT/name, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys()); w.writeheader(); w.writerows(rows)
write("customers.csv", customers); write("products.csv", products)
write("orders.csv", orders); write("order_items.csv", items)
print(len(customers), "customers |", len(products), "products |", len(orders), "orders |", len(items), "order items")
