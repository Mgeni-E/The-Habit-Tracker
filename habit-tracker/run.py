import os
import sys
from dotenv import load_dotenv
from app import create_app

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

load_dotenv()

app = create_app()

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
