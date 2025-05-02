# server.py 
from flask import Flask, request, jsonify
import json
import functools

# Force le flush immédiat de tous les print()
print = functools.partial(print, flush=True)

app = Flask(__name__)

@app.route('/validate', methods=['POST'])
def validate():
    try:
        review = request.get_json(force=True)
        print("=== 🔍 ImageReview received ===")
        print(json.dumps(review, indent=2))

        # Vérifie que la clé spec existe
        spec = review.get("spec", {})
        containers = spec.get("containers", [])

        images = [c.get("image", "") for c in containers]
        print("📦 Scanned image :", images)

        unauthorized = [img for img in images if not img.startswith("nginx")]

        if unauthorized:
            print("⛔ Non allowed image :", unauthorized)
            response_obj = {
                "apiVersion": "imagepolicy.k8s.io/v1alpha1",
                "kind": "ImageReview",
                "status": {
                    "allowed": False,
                    "reason": f"Non allowed image : {', '.join(unauthorized)}"
                }
            }
            print("❌ Response :")
            print(json.dumps(response_obj, indent=2))
            return jsonify(response_obj)

        print("✅ Toutes les images sont autorisées")
        response_obj = {
            "apiVersion": "imagepolicy.k8s.io/v1alpha1",
            "kind": "ImageReview",
            "status": {
                "allowed": True
            }
        }
        print("✅ Response :")
        print(json.dumps(response_obj, indent=2))
        return jsonify(response_obj)

    except Exception as e:
        print("❌ Internal error :", str(e))
        response_obj = {
            "apiVersion": "imagepolicy.k8s.io/v1alpha1",
            "kind": "ImageReview",
            "status": {
                "allowed": False,
                "reason": "Internal error in the webhook"
            }
        }
        print("❌ Response :")
        print(json.dumps(response_obj, indent=2))
        return jsonify(response_obj)

if __name__ == '__main__':
    print("🔧 Webhook démarré sur port 443...")
    app.run(host='0.0.0.0', port=443, ssl_context=('/certs/tls.crt', '/certs/tls.key'))