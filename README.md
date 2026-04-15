# Math as a Service (MaaS) – Cloud-Native Architecture

## 📌 Overview
This project implements a **cloud-native, serverless, and event-driven backend architecture** to estimate the value of π using the Monte Carlo simulation method. The system exposes a REST API that accepts requests and processes them asynchronously.

---

## 🚀 Architecture
The system follows a **cloud-native architecture** using managed services:

User → API Gateway → Service 1 → Pub/Sub → Service 2 → Firestore

### Components:
- **API Gateway**: Exposes the endpoint `POST /estimate_pi`
- **Service 1 (Receiver Service)**: Receives requests and publishes events
- **Google Pub/Sub**: Event system that decouples services
- **Service 2 (Worker Service)**: Performs Monte Carlo simulation
- **Cloud Firestore**: Stores simulation results

---

## ⚙️ Technologies Used
- Google Cloud Platform (GCP)
- Cloud Run (Serverless services)
- Google Pub/Sub (Event system)
- Cloud Firestore (NoSQL database)
- API Gateway
- Terraform (Infrastructure as Code)
- Docker (Containerization)
- Python (Flask)

---

## 📥 API Endpoint

### POST /estimate_pi

#### Request Body:
```json
{
  "total_points": 10000000
}
