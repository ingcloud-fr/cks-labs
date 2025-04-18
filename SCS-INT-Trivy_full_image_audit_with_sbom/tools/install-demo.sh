#!/bin/bash
set -e

echo "📁 Preparing demo application..."
rm -rf /home/vagrant/demo-app
mkdir -p /home/vagrant/demo-app
cat <<EOF > /home/vagrant/demo-app/app.py
print("Hello from the demo app!")
EOF

cat <<EOF > /home/vagrant/demo-app/Dockerfile
FROM python:3.9-slim
COPY app.py /app.py
CMD ["python", "/app.py"]
EOF
