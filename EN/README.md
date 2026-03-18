# Tutorial 1: OpenGL Foundations in MASM32 (English Version)

This folder contains the English version of the NeHe Tutorial 1 porting for **MASM32**. This project aims to bridge the gap between legacy graphics tutorials and modern Windows environments.

## 🚀 Key Improvements
While the logic follows NeHe's original structure, several "under-the-hood" improvements were necessary:

* **Fullscreen Compatibility:** Fixed the infamous "Display Settings Error" by switching from 16-bit to **32-bit color depth**, as modern monitors and drivers no longer support the old High Color mode in exclusive fullscreen.
* **Stack & FPU Handling:** Precise management of the x87 FPU stack during perspective calculations to prevent stack overflows and "invisible" scenes.

## 🤖 Special Credits
I would like to acknowledge **Gemini (AI)** for the invaluable assistance during the debugging phase. Its ability to analyze Assembly logic helped solve tricky bugs related to PixelFormat selection and hardware-specific display issues.

---
*Keeping low-level programming alive, one byte at a time.*