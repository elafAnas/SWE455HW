from flask import Flask, request, jsonify
import base64
import json
import random
from google.cloud import firestore

app = Flask(__name__)

# Firestore client
db = firestore.Client()


def estimate_pi(n):
    inside_circle = 0

    for _ in range(n):
        x = random.uniform(-1, 1)
        y = random.uniform(-1, 1)

        if x**2 + y**2 <= 1:
            inside_circle += 1

    return (4 * inside_circle) / n


@app.route("/", methods=["POST"])
def handler():
    envelope = request.get_json()

    # Validate Pub/Sub push body
    if not envelope or "message" not in envelope:
        return jsonify({"error": "Invalid Pub/Sub message format"}), 400

    pubsub_message = envelope["message"]

    if "data" not in pubsub_message:
        return jsonify({"error": "No data found in Pub/Sub message"}), 400

    try:
        # Decode message
        message_data = base64.b64decode(pubsub_message["data"]).decode("utf-8")
        data = json.loads(message_data)

        total_points = data["total_points"]

        print(f"Simulation started: total_points={total_points}")

        # Run Monte Carlo simulation
        pi_value = estimate_pi(total_points)

        # Save result in Firestore
        db.collection("pi_results").add({
            "total_points": total_points,
            "pi_estimate": pi_value
        })

        print(f"Simulation finished: pi={pi_value}")

        return jsonify({"status": "done"}), 200

    except Exception as e:
        print(f"Error in service2: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route("/", methods=["GET"])
def health_check():
    return jsonify({"status": "service2 is running"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)