

import psycopg2
from faker import Faker
import random

fake = Faker()

# ตั้งค่า connection สำหรับ Docker
conn = psycopg2.connect(
    host="172.20.0.2",  # หรือชื่อ container PostgreSQL
    port=5432,
    database="mydb",
    user="dicek",
    password="2546"
)

cur = conn.cursor()

categories = ["Electronics", "Clothing", "Food", "Toys", "Books"]
brands = ["BrandA", "BrandB", "BrandC", "BrandD"]
regions = ["North", "South", "East", "West"]
stores = [
    {"id": "S001", "name": "Store1", "city": "Bangkok"},
    {"id": "S002", "name": "Store2", "city": "Chiang Mai"},
    {"id": "S003", "name": "Store3", "city": "Phuket"}
]

def generate_sales_record():
    date = fake.date_between(start_date='-3m', end_date='today')
    product_id = fake.bothify(text="P###??")
    product_name = fake.word().title()
    category = random.choice(categories)
    brand = random.choice(brands)
    customer_id = fake.bothify(text="C###??")
    customer_name = fake.name()
    gender = random.choice(["Male", "Female"])
    region = random.choice(regions)
    store = random.choice(stores)
    quantity = random.randint(1, 20)
    unit_price = round(random.uniform(10, 1000), 2)
    discount = round(random.uniform(0, 30), 2)
    sales_amount = round(quantity * unit_price * (1 - discount / 100), 2)
    profit = round(sales_amount * random.uniform(0.1, 0.3), 2)

    return (
        date, product_id, product_name, category, brand,
        customer_id, customer_name, gender, region,
        store["id"], store["name"], store["city"],
        quantity, unit_price, discount, sales_amount, profit
    )

num_records = 10
inserted = 0

for i in range(num_records):
    try:
        record = generate_sales_record()
        cur.execute("""
            INSERT INTO public.sales_data (
                date, product_id, product_name, category, brand,
                customer_id, customer_name, gender, region,
                store_id, store_name, store_city,
                quantity, unit_price, discount, sales_amount, profit
            ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """, record)

        inserted += 1
        
    except Exception as e:
        print(f"Error inserting record {i + 1}: {e}")
        conn.rollback()
        continue

conn.commit()
cur.close()
conn.close()
print(f"{inserted} new records inserted successfully!")
