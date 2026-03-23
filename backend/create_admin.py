
import sqlite3
from werkzeug.security import generate_password_hash

DB_NAME = "streetfixx.db"

def create_admin():
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    email = "admin@mcc.edu.in"
    password = "admin"
    hashed_password = generate_password_hash(password)
    
    try:
        cursor.execute('''
            INSERT INTO users (name, email, password_hash, role, phone, department)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', ("System Admin", email, hashed_password, "admin", "0000000000", "Admin Dept"))
        
        conn.commit()
        print(f"Admin user created successfully.\nEmail: {email}\nPassword: {password}")
    except sqlite3.IntegrityError:
        print("Admin user already exists or email conflict.")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    create_admin()
