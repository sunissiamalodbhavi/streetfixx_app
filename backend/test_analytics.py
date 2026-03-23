import sys
import os
import json

app_dir = os.path.abspath(r"d:\streetf\streetfixx_app\backend")
sys.path.insert(0, app_dir)

import app

# Mock request context to call the route
with app.app.test_request_context('/admin/analytics'):
    try:
        response, status = app.get_admin_analytics()
        print("STATUS:", status)
        print("RESPONSE:", json.dumps(response.get_json(), indent=2))
    except Exception as e:
        print("ERROR:", e)
