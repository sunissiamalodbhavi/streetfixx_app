import sqlite3
import os

DB_NAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "streetfixx.db")

def get_db_connection():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Create Users Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL,
            phone TEXT,
            department TEXT,
            staff_id TEXT,
            gender TEXT,
            status TEXT DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Create Issues Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS issues (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            title TEXT NOT NULL,
            description TEXT,
            category TEXT,
            location TEXT,
            latitude REAL,
            longitude REAL,
            image_url TEXT,
            reporter_type TEXT,
            priority TEXT DEFAULT 'Medium',
            completion_image TEXT,
            completion_note TEXT,
            completed_at TIMESTAMP,
            completed_by INTEGER,
            status TEXT DEFAULT 'Pending',
            assigned_to INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id),
            FOREIGN KEY (assigned_to) REFERENCES users (id),
            FOREIGN KEY (completed_by) REFERENCES users (id)
        )
    ''')

    # ... existing logic remains ...

    try:
        cursor.execute('ALTER TABLE issues ADD COLUMN completion_note TEXT')
        print("Added 'completion_note' column to issues table.")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute('ALTER TABLE issues ADD COLUMN image_url TEXT')
        print("Added 'image_url' column to issues table.")
    except sqlite3.OperationalError:
        pass

    # Add completion proof columns
    try:
        cursor.execute('ALTER TABLE issues ADD COLUMN completion_image TEXT')
        print("Added 'completion_image' column to issues table.")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute('ALTER TABLE issues ADD COLUMN completed_at TIMESTAMP')
        print("Added 'completed_at' column to issues table.")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute('ALTER TABLE issues ADD COLUMN completed_by INTEGER REFERENCES users(id)')
        print("Added 'completed_by' column to issues table.")
    except sqlite3.OperationalError:
        pass

    # Create Bookings Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS bookings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            resource_type TEXT NOT NULL,
            resource_id TEXT,
            start_time TIMESTAMP,
            end_time TIMESTAMP,
            purpose TEXT,
            status TEXT DEFAULT 'Pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    ''')
    
    # Attempt to add assigned_to column if it doesn't exist (for existing DBs)
    try:
        cursor.execute('ALTER TABLE issues ADD COLUMN assigned_to INTEGER REFERENCES users(id)')
        print("Added 'assigned_to' column to issues table.")
    except sqlite3.OperationalError:
        # Column likely already exists
        pass

    try:
        cursor.execute('ALTER TABLE users ADD COLUMN gender TEXT')
        print("Added 'gender' column to users table.")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute('ALTER TABLE users ADD COLUMN fcm_token TEXT')
        print("Added 'fcm_token' column to users table.")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE issues ADD COLUMN priority TEXT DEFAULT 'Medium'")
        print("Added 'priority' column to issues table.")
    except sqlite3.OperationalError:
        pass
        
    try:
        cursor.execute("ALTER TABLE issues ADD COLUMN reporter_type TEXT")
        print("Added 'reporter_type' column to issues table.")
    except sqlite3.OperationalError:
        pass
    
    conn.commit()
    conn.close()
    print("Database initialized successfully.")

if __name__ == '__main__':
    init_db()
