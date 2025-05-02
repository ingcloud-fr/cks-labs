import os
import time

secret = os.environ.get("SECRET")
if secret:
    print("🔐 The secret is:", secret)
else:
    print("❌ No secret provided.")

# Sleep for 3600 seconds
print("🕒 Sleeping for 3600 seconds to keep the container alive...")
time.sleep(3600)
print("🏁 Exiting now.")