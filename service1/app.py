from flask import Flask, request, jsonify
from google.cloud import pubsub_v1
import json
import os

app = Flask(__name__)

# Read values from Cloud Run environment variables
PROJECT_ID = os.environ.get("PROJECT_ID")
TOPIC_ID = os.environ.get("TOPIC_ID")

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)


@app.route("/estimate_pi", methods=["POST"])
def estimate_pi():
    data = request.get_json()

    # Validate request body
    if not data or "total_points" not in data:
        return jsonify({"error": "total_points is required"}), 400

    total_points = data["total_points"]

    # Extra simple validation
    if not isinstance(total_points, int) or total_points <= 0:
        return jsonify({"error": "total_points must be a positive integer"}), 400

    # Prepare Pub/Sub message
    message = json.dumps({
        "total_points": total_points
    }).encode("utf-8")

    # Publish event
    publisher.publish(topic_path, message)

    print(f"Accepted request: total_points={total_points}")

    # Return immediately
    return jsonify({"message": "Request accepted"}), 202


@app.route("/", methods=["GET"])
def health_check():
    return jsonify({"status": "service1 is running"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)