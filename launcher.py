import os
import sys
import threading
import time
import webview
from waitress import serve
from django.core.management import execute_from_command_line
from django.core.wsgi import get_wsgi_application

# Configure environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

def run_server():
    """Run the Waitress WSGI server."""
    # Initialize Django
    import django
    django.setup()

    # Ensure media folder exists
    from django.conf import settings
    if not os.path.exists(settings.MEDIA_ROOT):
        os.makedirs(settings.MEDIA_ROOT, exist_ok=True)

    # Run migrations
    print("Initializing database...")
    execute_from_command_line(['manage.py', 'migrate', '--noinput'])

    # Get WSGI application
    application = get_wsgi_application()

    # Serve using Waitress
    print("Server starting on http://127.0.0.1:8000")
    serve(application, host='127.0.0.1', port=8000, threads=6)

if __name__ == '__main__':
    try:
        # Start server in a background thread
        server_thread = threading.Thread(target=run_server, daemon=True)
        server_thread.start()

        # Give the server a moment to start
        time.sleep(2)

        # Create and start the desktop window
        print("Opening desktop window...")
        webview.create_window(
            'Saree by Pallu - Premium POS', 
            'http://127.0.0.1:8000', 
            width=1280, 
            height=800,
            min_size=(1024, 768),
            background_color='#ffffff'
        )
        # Use edgechromium backend specifically
        webview.start(gui='edgechromium')

    except Exception as e:
        import traceback
        with open("error_log.txt", "w") as f:
            f.write(str(e))
            f.write("\n")
            f.write(traceback.format_exc())
        sys.exit(1)
