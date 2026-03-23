import requests
import json
import time

BASE_URL = "http://127.0.0.1:5000"

def test_signup_maintenance():
    print("\n--- Testing Maintenance Signup ---")
    data = {
        "name": "Maintenance",
        "email": "maint@mcc.edu.in",
        "password": "password123",
        "role": "maintenance",
        "phone": "9876543210",
        "department": "Electrical",
        "staff_id": "M001"
    }
    try:
        response = requests.post(f"{BASE_URL}/signup", json=data)
        if response.status_code == 201:
            print("Signup Successful:", response.json())
            return response.json()['user_id']
        elif response.status_code == 409:
            print("User already exists, proceeding...")
            # We need to find the ID of this user if possible, or just ignore for now
            return None
        else:
            print("Signup Failed:", response.status_code, response.text)
            return None
    except Exception as e:
        print(f"Error: {e}")
        return None

def test_get_staff_list():
    print("\n--- Testing Get Staff List (Should include Maintenance) ---")
    try:
        response = requests.get(f"{BASE_URL}/admin/staff")
        if response.status_code == 200:
            staff_list = response.json()
            print(f"Found {len(staff_list)} staff members.")
            found_maintenance = False
            for staff in staff_list:
                print(f" - {staff['name']} ({staff.get('role', 'N/A')})")
                if staff.get('role') == 'maintenance':
                    found_maintenance = True
            
            if found_maintenance:
                print("SUCCESS: Maintenance staff found in list.")
            else:
                print("FAILURE: Maintenance staff NOT found in list.")
        else:
            print("Failed to get staff list:", response.status_code, response.text)
    except Exception as e:
        print(f"Error: {e}")

def test_issue_flow(maint_user_id):
    if not maint_user_id:
        print("\nSkipping issue flow test due to missing maintenance user ID.")
        return

    print("\n--- Testing Issue Reporting & Assignment ---")
    # 1. Report Issue
    report_data = {
        "user_id": 1, # Assuming user 1 exists (admin or student)
        "title": "Broken Light",
        "description": "Light is broken in corridor",
        "category": "Electrical",
        "location": "Main Block 1st Floor"
    }
    # Using multipart form data simulation via requests is complex, skipping image for now
    # Actually, let's just use the API correctly
    try:
        # We need a user ID. Let's create a dummy student first just in case
        student_data = {
            "name": "Test Student",
            "email": "student@mcc.edu.in",
            "password": "password",
            "role": "student",
            "phone": "1212121212",
            "roll_no": "123",
             "department": "MCA",
        }
        requests.post(f"{BASE_URL}/signup", json=student_data)
        
        # Login to get ID
        login_resp = requests.post(f"{BASE_URL}/login", json={"email": "student@mcc.edu.in", "password": "password"})
        student_id = login_resp.json()['user_id']

        # Report
        files = {'image': ('test.jpg', b'fake image data')}
        report_resp = requests.post(f"{BASE_URL}/citizen/report-issue", data={
            "user_id": student_id,
            "title": "Broken Light",
            "description": "Light is broken",
            "category": "Electrical",
            "location": "Corridor"
        }, files=files)
        
        print(f"Report Response Status: {report_resp.status_code}")
        print(f"Report Response Body: {report_resp.text}")
        
        if report_resp.status_code != 201:
             print("Report failed.")
             return

        issue_id = report_resp.json()['issue_id']
        print(f"Reported Issue ID: {issue_id}")

        # 2. Assign Issue
        print(f"Assigning issue {issue_id} to maintenance user {maint_user_id}...")
        assign_resp = requests.put(f"{BASE_URL}/admin/issue/assign", json={
            "issue_id": issue_id,
            "staff_id": maint_user_id
        })
        print("Assign Response:", assign_resp.json())

        # 3. Verify Assignment (Maintenance View)
        print(f"Checking maintenance view for user {maint_user_id}...")
        maint_view_resp = requests.get(f"{BASE_URL}/maintenance/issues/{maint_user_id}")
        issues = maint_view_resp.json()
        found_issue = False
        for issue in issues:
            if issue['id'] == issue_id:
                found_issue = True
                print(f"Found assigned issue: {issue['title']} - status: {issue['status']}")
        
        if found_issue:
            print("SUCCESS: Issue assignment verified.")
        else:
            print("FAILURE: Assigned issue not found in maintenance view.")

    except Exception as e:
        print(f"Error in issue flow: {e}")

if __name__ == "__main__":
    # Ensure server is up
    try:
        requests.get(BASE_URL)
    except:
        print("Server not running. Please start app.py")
        exit(1)

    maint_id = test_signup_maintenance()
    
    # If signup failed because user exists, try to login to get ID
    if not maint_id:
        try:
             login_resp = requests.post(f"{BASE_URL}/login", json={"email": "maint@mcc.edu.in", "password": "password123"})
             if login_resp.status_code == 200:
                 maint_id = login_resp.json()['user_id']
                 print(f"Logged in as existing maintenance user. ID: {maint_id}")
        except:
            pass

    test_get_staff_list()
    test_issue_flow(maint_id)
