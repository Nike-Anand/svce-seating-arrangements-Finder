# SVCE Seating Arrangement Finder

<p align="center">
  <img src="icon.png" width="90" alt="App Icon" />
</p>

<p align="center">
  <b>Instant exam seating lookup for SVCE students — without digging through PDFs.</b>
</p>

<p align="center">
  <a href="SVCE_Seating_Finder.apk">
    <img src="https://img.shields.io/badge/Download_APK-Android_v1.0-blue?style=for-the-badge&logo=android" alt="Download APK" />
  </a>
</p>

---

## 🎬 Showcase

<p align="center">
  <img src="demo.gif" alt="App Demo" width="280" />
</p>

During exam days at SVCE, seating plans are published as multi-page PDFs on the college portal shortly before exams begin. Between slow campus networks, crowded notice boards, and long PDF tables, finding your seat on time can be stressful.

This app automates the entire process: it scrapes the official portal, parses the seat-to-hall mapping, and lets students check their exact seating allocation instantly on their phones.

---

## ✨ Features

- **Instant Register Search** — Type your register number to immediately get your Hall number, seat row, and exam session.
- **Offline Cache** — Cached database ensures you can find your seat even when campus mobile data drops outside exam halls.
- **Exam Reminders** — Background notifications alert you before your exam session begins.
- **Direct PDF Access** — View and verify directly against the original college notice with one tap.

---

## 📁 Repository Overview

```
├── lib/                     # Flutter mobile application
├── android/                 # Android platform files & manifest
├── backend/                 # Flask scraper engine & API
│   ├── app.py               # Scraper & REST endpoints
│   └── seating_data.json    # Cached seating data
├── demo.gif                 # App preview demo
└── SVCE_Seating_Finder.apk  # Pre-built release APK
```

---

## 📄 License

MIT
