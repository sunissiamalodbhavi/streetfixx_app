import sqlite3
import os

DB_NAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "streetfixx.db")

def verify():
    print(f"Verifying database: {DB_NAME}")
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    try:
        # 1. Check schema
        cursor.execute("PRAGMA table_info(issues)")
        columns = [col['name'] for col in cursor.fetchall()]
        print(f"Current columns in 'issues': {columns}")
        
        if 'issue_id' in columns:
            print("FAILURE: 'issue_id' column still exists!")
            return
        
        if 'id' not in columns:
             print("FAILURE: 'id' column missing!")
             return

        print("SUCCESS: Schema verification passed ('issue_id' is gone).")

        # 2. Try to insert a dummy issue
        print("Attempting to insert a test issue...")
        cursor.execute('''
            INSERT INTO issues (user_id, title, description, category, location, latitude, longitude)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (1, 'Test Migration', 'Testing if migration worked', 'General', 'Test Loc', 0.0, 0.0))
        
        issue_id = cursor.lastrowid
        print(f"Inserted test issue with ID: {issue_id}")
        
        # 3. Verify retrieval
        cursor.execute("SELECT * FROM issues WHERE id = ?", (issue_id,))
        row = cursor.fetchone()
        if row:
             print("SUCCESS: data insertion and retrieval verified.")
        else:
             print("FAILURE: Could not retrieve inserted row.")

        # Cleanup
        cursor.execute("DELETE FROM issues WHERE id = ?", (issue_id,))
        conn.commit()
        print("Test data cleaned up.")

    except Exception as e:
        print(f"VERIFICATION FAILED: {e}")
    finally:
        conn.close()

if __name__ == '__main__':
    verify()
