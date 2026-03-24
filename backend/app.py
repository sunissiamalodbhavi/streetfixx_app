from flask import Flask, request, jsonify
from flask_cors import CORS
from db import get_db_connection, init_db
import sqlite3
from werkzeug.security import generate_password_hash, check_password_hash
import uuid
import os
import firebase_admin
from firebase_admin import credentials, messaging

app = Flask(__name__)
# Enable CORS for all domains to allow Flutter emulator/device access
CORS(app)

# Initialize DB if not exists
try:
    init_db()
except Exception as e:
    print(f"Database might already be initialized: {e}")

# Initialize Firebase Admin SDK
try:
    # Look for serviceAccountKey.json in the current directory
    service_account_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'serviceAccountKey.json')
    if os.path.exists(service_account_path):
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin initialized successfully")
    else:
        print("serviceAccountKey.json not found. Push notifications will be disabled.")
except Exception as e:
    print(f"Error initializing Firebase Admin: {e}")

def send_push_notification(user_id, title, body):
    """Utility function to send push notification to a specific user"""
    conn = get_db_connection()
    user = conn.execute('SELECT fcm_token FROM users WHERE id = ?', (user_id,)).fetchone()
    conn.close()

    if not user or not user['fcm_token']:
        print(f"⚠️ No FCM token found for user {user_id}")
        return False

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            token=user['fcm_token'],
        )
        response = messaging.send(message)
        print(f"Successfully sent message to user {user_id}: {response}")
        return True
    except Exception as e:
        print(f"Error sending FCM message to user {user_id}: {e}")
        return False

def notify_admins(title, body):
    """Utility to notify all admins"""
    conn = get_db_connection()
    admins = conn.execute("SELECT fcm_token FROM users WHERE role = 'admin'").fetchall()
    conn.close()
    
    for admin in admins:
        if admin['fcm_token']:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(title=title, body=body),
                    token=admin['fcm_token'],
                )
                messaging.send(message)
            except Exception as e:
                print(f"Error sending FCM to admin: {e}")

@app.route('/')
def home():
    return jsonify({"message": "StreetFixx API is running"})

# --- AUHTENTICATION ---

@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    role = data.get('role', 'student') # Default to student if not provided

    phone = data.get('phone')
    department = data.get('department')
    staff_id = data.get('staff_id')
    gender = data.get('gender')

    if not name or not email or not password:
        return jsonify({"error": "Missing required fields"}), 400

    hashed_password = generate_password_hash(password)
    
    conn = get_db_connection()
    try:
        conn.execute('INSERT INTO users (name, email, password_hash, role, phone, department, staff_id, gender) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                     (name, email, hashed_password, role, phone, department, staff_id, gender))
        conn.commit()
        user_id = conn.execute('SELECT last_insert_rowid()').fetchone()[0]
        conn.close()
        return jsonify({"message": "User registered successfully", "user_id": user_id, "role": role}), 201
    except sqlite3.IntegrityError:
        conn.close()
        return jsonify({"error": "Email already exists"}), 409
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 500

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    conn = get_db_connection()
    user = conn.execute('SELECT * FROM users WHERE email = ?', (email,)).fetchone()
    conn.close()

    if user and check_password_hash(user['password_hash'], password):
        return jsonify({
            "message": "Login successful",
            "user_id": user['id'],
            "name": user['name'],
            "email": user['email'],
            "role": user['role']
        }), 200
    else:
        return jsonify({"error": "Invalid credentials"}), 401

# --- ISSUES ---

from werkzeug.utils import secure_filename

# ... imports ...

# Configure upload folder
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Ensure upload directory exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

from flask import send_from_directory

@app.route('/uploads/<path:filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# ... existing code ...

@app.route('/citizen/report-issue', methods=['POST'])
def report_issue():
    # Handle multipart/form-data
    user_id = request.form.get('user_id')
    title = request.form.get('title')
    description = request.form.get('description')
    category = request.form.get('category')
    location = request.form.get('location')
    latitude = request.form.get('latitude')
    longitude = request.form.get('longitude')
    priority = request.form.get('priority', 'Medium')
    reporter_type = request.form.get('reporter_type', 'student') # Default to student
    
    if not user_id or not title:
        return jsonify({"error": "User ID and Title are required"}), 400

    image_url = None
    if 'image' in request.files:
        file = request.files['image']
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            # Make filename unique to avoid overwrite
            unique_filename = f"{uuid.uuid4()}_{filename}"
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], unique_filename))
            image_url = f"/uploads/{unique_filename}"

    conn = get_db_connection()
    try:
        cursor = conn.execute('''
            INSERT INTO issues (user_id, title, description, category, location, latitude, longitude, image_url, priority, reporter_type)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (user_id, title, description, category, location, latitude, longitude, image_url, priority, reporter_type))
        conn.commit()
        new_issue_id = cursor.lastrowid
        conn.close()
        
        # Notify Admins when a new issue is reported
        notify_admins("New Issue Reported", f"A new {priority.lower()} priority issue '{title}' was just reported.")
        
        abs_image_url = (request.host_url.rstrip('/') + image_url) if image_url else None
        return jsonify({"message": "Issue reported successfully", "issue_id": new_issue_id, "image_url": abs_image_url}), 201
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 500

@app.route('/citizen/issues/<int:user_id>', methods=['GET'])
def get_user_issues(user_id):
    conn = get_db_connection()
    issues = conn.execute('SELECT * FROM issues WHERE user_id = ? ORDER BY created_at DESC', (user_id,)).fetchall()
    conn.close()
    
    # Convert Row objects to dicts and fix image_url
    issues_list = []
    for issue in issues:
        d = dict(issue)
        if d.get('image_url') and d['image_url'].startswith('/'):
            d['image_url'] = request.host_url.rstrip('/') + d['image_url']
        if d.get('completion_image') and d['completion_image'].startswith('/'):
            d['completion_image'] = request.host_url.rstrip('/') + d['completion_image']
        issues_list.append(d)
    return jsonify(issues_list), 200

@app.route('/admin/issues', methods=['GET'])
def get_all_issues():
    reporter_type = request.args.get('reporter_type')
    role = request.args.get('role')
    status = request.args.get('status')
    conn = get_db_connection()
    
    query = '''
        SELECT issues.*, 
               u1.name as reported_by,
               u1.role as reported_by_role,
               u2.name as assigned_to_name,
               u3.name as completed_by_name
        FROM issues 
        JOIN users u1 ON issues.user_id = u1.id 
        LEFT JOIN users u2 ON issues.assigned_to = u2.id
        LEFT JOIN users u3 ON issues.completed_by = u3.id
    '''
    params = []
    
    where_clauses = []
    
    if reporter_type:
        where_clauses.append('issues.reporter_type = ?')
        params.append(reporter_type)
        
    if role:
        if role == 'staff':
            where_clauses.append("(u1.role = 'staff' OR u1.role = 'maintenance')")
        else:
            where_clauses.append("u1.role = ?")
            params.append(role)
            
    if status:
        status_lower = status.lower()
        if status_lower == 'pending':
            where_clauses.append("LOWER(issues.status) = 'pending'")
        elif status_lower == 'assigned':
            where_clauses.append("LOWER(issues.status) IN ('assigned', 'in progress')")
        elif status_lower == 'resolved':
            where_clauses.append("LOWER(issues.status) IN ('resolved', 'completed')")
        else:
            where_clauses.append("LOWER(issues.status) = ?")
            params.append(status_lower)
            
    if where_clauses:
        query += ' WHERE ' + ' AND '.join(where_clauses)
        
    query += ' ORDER BY issues.created_at DESC'
    
    issues = conn.execute(query, params).fetchall()
    conn.close()
    
    issues_list = []
    for issue in issues:
        d = dict(issue)
        if d.get('image_url') and d['image_url'].startswith('/'):
            d['image_url'] = request.host_url.rstrip('/') + d['image_url']
        if d.get('completion_image') and d['completion_image'].startswith('/'):
            d['completion_image'] = request.host_url.rstrip('/') + d['completion_image']
        issues_list.append(d)
    return jsonify(issues_list), 200

@app.route('/admin/issues/counts', methods=['GET'])
def get_issue_counts():
    conn = get_db_connection()
    query = '''
        SELECT u.role, COUNT(i.id) as count
        FROM issues i
        JOIN users u ON i.user_id = u.id
        GROUP BY u.role
    '''
    counts = conn.execute(query).fetchall()
    conn.close()
    
    result = {
        "student_count": 0,
        "hall_student_count": 0,
        "staff_count": 0
    }
    
    for row in counts:
        role = row['role']
        count = row['count']
        if role == 'student':
            result['student_count'] += count
        elif role == 'hall_student':
            result['hall_student_count'] += count
        elif role in ['staff', 'maintenance']:
            result['staff_count'] += count
            
    return jsonify(result), 200

@app.route('/admin/users-count', methods=['GET'])
def get_users_count():
    conn = get_db_connection()
    count = conn.execute('SELECT COUNT(*) FROM users').fetchone()[0]
    conn.close()
    return jsonify({"total_users": count}), 200

@app.route('/admin/analytics', methods=['GET'])
def get_admin_analytics():
    conn = get_db_connection()
    
    # 1. Summary Counts (Total, Assigned, Pending, Resolved)
    summary = conn.execute('''
        SELECT 
            COUNT(*) as total_issues,
            SUM(CASE WHEN LOWER(status) IN ('assigned', 'in progress') THEN 1 ELSE 0 END) as assigned_issues,
            SUM(CASE WHEN LOWER(status) = 'pending' THEN 1 ELSE 0 END) as pending_issues,
            SUM(CASE WHEN LOWER(status) IN ('resolved', 'completed') THEN 1 ELSE 0 END) as resolved_issues
        FROM issues
    ''').fetchone()
    
    # 2. Role-based Stats
    role_stats_raw = conn.execute('''
        SELECT 
            u.role as reported_by_role,
            COUNT(i.id) as total,
            SUM(CASE WHEN LOWER(i.status) IN ('resolved', 'completed') THEN 1 ELSE 0 END) as resolved,
            SUM(CASE WHEN LOWER(i.status) IN ('assigned', 'in progress') THEN 1 ELSE 0 END) as assigned,
            SUM(CASE WHEN LOWER(i.status) = 'pending' THEN 1 ELSE 0 END) as pending
        FROM issues i
        JOIN users u ON i.user_id = u.id
        GROUP BY u.role
    ''').fetchall()
    
    role_stats = {
        'student': {'total': 0, 'resolved': 0, 'assigned': 0, 'pending': 0},
        'hall_student': {'total': 0, 'resolved': 0, 'assigned': 0, 'pending': 0},
        'staff': {'total': 0, 'resolved': 0, 'assigned': 0, 'pending': 0}
    }
    
    for row in role_stats_raw:
        r_type = row['reported_by_role']
        if r_type:
            r_type = r_type.lower()
            
        mapped_role = r_type
        if r_type == 'maintenance':
            mapped_role = 'staff'
            
        if mapped_role in role_stats:
            role_stats[mapped_role]['total'] += row['total'] or 0
            role_stats[mapped_role]['resolved'] += row['resolved'] or 0
            role_stats[mapped_role]['assigned'] += row['assigned'] or 0
            role_stats[mapped_role]['pending'] += row['pending'] or 0
            
    # 3. Location Analysis
    locations = conn.execute('''
        SELECT location, COUNT(*) as count 
        FROM issues 
        WHERE location IS NOT NULL AND TRIM(location) != ''
        GROUP BY location 
        ORDER BY count DESC 
        LIMIT 10
    ''').fetchall()
    
    location_data = [{'location': row['location'], 'count': row['count']} for row in locations]
    
    # 4. Monthly Issue Trends (Last 6 Months)
    # STRFTIME extracts YYYY-MM
    months = conn.execute('''
        SELECT * FROM (
            SELECT 
                strftime('%Y-%m', created_at) as month,
                COUNT(*) as count
            FROM issues
            WHERE created_at IS NOT NULL
            GROUP BY month
            ORDER BY month DESC
            LIMIT 6
        ) ORDER BY month ASC
    ''').fetchall()
    
    monthly_trends = [{'month': row['month'], 'count': row['count']} for row in months]
    
    conn.close()
    
    # Ensure empty summary doesn't return None values
    summary_dict = dict(summary)
    for key in summary_dict:
        if summary_dict[key] is None:
            summary_dict[key] = 0
            
    return jsonify({
        'summary': summary_dict,
        'roles': role_stats,
        'locations': location_data,
        'monthly_trends': monthly_trends
    }), 200

# --- BOOKINGS ---

@app.route('/bookings', methods=['POST'])
def create_booking():
    data = request.get_json()
    user_id = data.get('user_id')
    resource_type = data.get('resource_type') # e.g., 'Guest House', 'Hall'
    resource_id = data.get('resource_id')
    start_time = data.get('start_time')
    end_time = data.get('end_time')
    purpose = data.get('purpose')
    
    if not user_id or not resource_type:
         return jsonify({"error": "User ID and Resource Type are required"}), 400

    conn = get_db_connection()
    try:
        conn.execute('''
            INSERT INTO bookings (user_id, resource_type, resource_id, start_time, end_time, purpose)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (user_id, resource_type, resource_id, start_time, end_time, purpose))
        conn.commit()
        conn.close()
        return jsonify({"message": "Booking created successfully"}), 201
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 500

@app.route('/admin/bookings', methods=['GET'])
def get_all_bookings():
    conn = get_db_connection()
    query = '''
        SELECT bookings.*, users.name as user_name 
        FROM bookings 
        JOIN users ON bookings.user_id = users.id 
        ORDER BY created_at DESC
    '''
    bookings = conn.execute(query).fetchall()
    conn.close()
    return jsonify([dict(row) for row in bookings]), 200

@app.route('/bookings/status', methods=['PUT'])
def update_booking_status():
    data = request.get_json()
    booking_id = data.get('booking_id')
    status = data.get('status') # 'Approved' or 'Rejected'
    
    if not booking_id or not status:
        return jsonify({"error": "Booking ID and Status are required"}), 400
        
    conn = get_db_connection()
    try:
        conn.execute('UPDATE bookings SET status = ? WHERE id = ?', (status, booking_id))
        conn.commit()
        conn.close()
        return jsonify({"message": f"Booking {status.lower()} successfully"}), 200
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 500

# --- ADMIN ACTIONS ---

@app.route('/admin/staff', methods=['GET'])
def get_staff_list():
    conn = get_db_connection()
    staff = conn.execute("SELECT id, name, department, role FROM users WHERE role = 'maintenance'").fetchall()
    conn.close()
    if not staff:
        return jsonify([]), 200 # Return empty list if no maintenance staff found
    return jsonify([dict(row) for row in staff]), 200

@app.route('/admin/issue/assign', methods=['PUT'])
def assign_issue():
    data = request.get_json()
    issue_id = data.get('issue_id') # This is now the INTEGER id
    staff_id = data.get('staff_id') 
    
    if not issue_id or not staff_id:
        return jsonify({"error": "Issue ID and Staff ID are required"}), 400
        
    conn = get_db_connection()
    try:
        conn.execute('UPDATE issues SET assigned_to = ?, status = ? WHERE id = ?', 
                     (staff_id, 'Assigned', issue_id))
        conn.commit()
        
        # Notify Staff
        send_push_notification(staff_id, "New Issue Assigned", f"Issue #{issue_id} has been assigned to you.")
        
        conn.close()
        return jsonify({"message": "Issue assigned successfully"}), 200
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 500

# --- MAINTENANCE ---

@app.route('/maintenance/issues/<int:user_id>', methods=['GET'])
def get_maintenance_issues(user_id):
    conn = get_db_connection()
    issues = conn.execute('''
        SELECT issues.*, 
               u1.name as reported_by,
               u1.department as reporter_department
        FROM issues 
        JOIN users u1 ON issues.user_id = u1.id 
        WHERE assigned_to = ? 
        ORDER BY created_at DESC
    ''', (user_id,)).fetchall()
    conn.close()
    
    issues_list = []
    for issue in issues:
        d = dict(issue)
        if d.get('image_url') and d['image_url'].startswith('/'):
            d['image_url'] = request.host_url.rstrip('/') + d['image_url']
        if d.get('completion_image') and d['completion_image'].startswith('/'):
            d['completion_image'] = request.host_url.rstrip('/') + d['completion_image']
        issues_list.append(d)
    return jsonify(issues_list), 200

@app.route('/maintenance/issue/update', methods=['PUT'])
def update_issue_status():
    data = request.get_json()
    issue_id = data.get('issue_id')
    status = data.get('status') # e.g., 'In Progress'
    
    if not issue_id or not status:
        return jsonify({"error": "Issue ID and Status are required"}), 400
        
    conn = get_db_connection()
    user = conn.execute('SELECT role FROM users WHERE id = ?', (data.get('user_id'),)).fetchone()
    if not user or user['role'] != 'maintenance':
        conn.close()
        return jsonify({"error": "Unauthorized: Maintenance role required"}), 403
    try:
        conn.execute('UPDATE issues SET status = ? WHERE id = ?', (status, issue_id))
        conn.commit()
        conn.close()
        return jsonify({"message": "Issue status updated successfully"}), 200
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 500

@app.route('/maintenance/complete_issue', methods=['POST'])
def complete_issue():
    issue_id = request.form.get('issue_id')
    maintenance_id = request.form.get('maintenance_id')
    completion_note = request.form.get('completion_note', '')
    
    if not issue_id or not maintenance_id:
        return jsonify({"error": "Issue ID and Maintenance ID are required"}), 400

    conn = get_db_connection()
    user = conn.execute('SELECT role FROM users WHERE id = ?', (maintenance_id,)).fetchone()
    if not user or user['role'] != 'maintenance':
        conn.close()
        return jsonify({"error": "Unauthorized: Maintenance role required"}), 403

    completion_image_url = None
    if 'completion_image' in request.files:
        file = request.files['completion_image']
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            unique_filename = f"completed_{uuid.uuid4()}_{filename}"
            
            # Ensure completion directory exists
            os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], 'completions'), exist_ok=True)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], 'completions', unique_filename))
            completion_image_url = f"/uploads/completions/{unique_filename}"
    
    if not completion_image_url:
        return jsonify({"error": "Completion image is required"}), 400

    try:
        from datetime import datetime
        completed_at = datetime.utcnow().isoformat()
        
        # Get original reporter to notify them
        issue_data = conn.execute('SELECT user_id FROM issues WHERE id = ?', (issue_id,)).fetchone()
        
        conn.execute('''
            UPDATE issues 
            SET status = 'COMPLETED', 
                completion_image = ?, 
                completion_note = ?,
                completed_at = ?, 
                completed_by = ? 
            WHERE id = ?
        ''', (completion_image_url, completion_note, completed_at, maintenance_id, issue_id))
        conn.commit()

        # Notify Admins
        notify_admins("Issue Completed", f"Task for Issue #{issue_id} has been completed by staff.")
        
        # Notify Original Reporter
        if issue_data and issue_data['user_id']:
            send_push_notification(issue_data['user_id'], "Issue Completed", f"Your issue (#{issue_id}) has been marked as completed by the maintenance team.")


        conn.close()
        abs_completion_url = (request.host_url.rstrip('/') + completion_image_url) if completion_image_url else None
        return jsonify({"message": "Issue completed successfully", "completion_image": abs_completion_url}), 200
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 500

@app.route('/admin/verify_issue', methods=['PUT'])
def verify_issue():
    data = request.get_json()
    issue_id = data.get('issue_id')
    status = data.get('status') # 'Resolved' or 'Reopened'
    
    if not issue_id or not status:
        return jsonify({"error": "Issue ID and Status are required"}), 400
        
    if status not in ['Resolved', 'Reopened']:
        return jsonify({"error": "Invalid status. Must be 'Resolved' or 'Reopened'"}), 400

    conn = get_db_connection()
    try:
        # Get reporter and assigned staff info before update
        issue = conn.execute('SELECT user_id, assigned_to FROM issues WHERE id = ?', (issue_id,)).fetchone()
        
        conn.execute('UPDATE issues SET status = ? WHERE id = ?', (status, issue_id))
        conn.commit()

        if issue:
            if status == 'Resolved':
                # Notify Student (reporter)
                send_push_notification(issue['user_id'], "Issue Resolved", f"Your issue #{issue_id} has been marked as resolved.")
            elif status == 'Reopened':
                # Notify Staff (assigned_to)
                if issue['assigned_to']:
                    send_push_notification(issue['assigned_to'], "Issue Reopened", f"Issue #{issue_id} was rejected by admin and has been reopened.")

        conn.close()
        return jsonify({"message": f"Issue {status.lower()} successfully"}), 200
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 500

@app.route('/save_fcm_token', methods=['POST'])
def save_fcm_token():
    data = request.get_json()
    user_id = data.get('user_id')
    fcm_token = data.get('fcm_token')
    
    if not user_id or not fcm_token:
        return jsonify({"error": "User ID and FCM token are required"}), 400
        
    conn = get_db_connection()
    try:
        conn.execute('UPDATE users SET fcm_token = ? WHERE id = ?', (fcm_token, user_id))
        conn.commit()
        conn.close()
        return jsonify({"message": "FCM token saved successfully"}), 200
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 500

@app.route('/create-admin', methods=['GET'])
def create_admin():
    conn = get_db_connection()
    cursor = conn.cursor()

    # Check if admin already exists (prevent duplicates)
    cursor.execute("SELECT * FROM users WHERE email = ?", ("admin@mcc.edu.in",))
    existing_admin = cursor.fetchone()

    if existing_admin:
        conn.close()
        return {"message": "Admin already exists"}

    hashed_password = generate_password_hash("123456")

    cursor.execute("""
        INSERT INTO users (name, email, password_hash, role)
        VALUES (?, ?, ?, ?)
    """, ("Admin", "admin@mcc.edu.in", hashed_password, "admin"))

    conn.commit()
    conn.close()

    return {"message": "Admin created successfully"}

if __name__ == '__main__':
    # Run on 0.0.0.0 to be accessible from emulator/device/Render
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
