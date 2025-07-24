# 🧠 CapstoneHRV – Apple Watch ECG Retriever (Swift)

This Swift-based application is part of my university capstone project. It is designed to **retrieve ECG data recorded on Apple Watch**, manage the data in structured folders, and prepare it for further HRV (Heart Rate Variability) analysis.

While the actual HRV analysis is performed separately (e.g., in Python), this app acts as a **data collection and management layer** using the **HealthKit** framework.

---

## 📱 What This App Does

CapstoneHRV (iOS/watchOS):
- Retrieves Apple Watch ECG samples using **HealthKit**
- Extracts high-resolution voltage-time pairs (512 Hz)
- Stores data in **CSV format** for later analysis
- Allows foldering and session-based ECG management
- Exports individual files or entire folders as ZIP

This app focuses purely on **data gathering and organization**, not HRV metric computation or graph rendering.

---

## 🔧 Features

- ✅ Retrieve ECGs sampled at **512 Hz** (`appleWatchSimilarToLeadI`)
- ✅ Store ECG sessions in named folders
- ✅ Export ECG recordings to **CSV** format:
