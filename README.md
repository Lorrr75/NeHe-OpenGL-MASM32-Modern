# NeHe OpenGL Framework - MASM32 Porting

This repository contains a modern porting of the famous **NeHe OpenGL Tutorials** from C++ to **80386 Assembly (MASM32)**. 

The goal of this project is to provide a solid, documented, and working framework for learning low-level graphics programming on modern Windows systems (tested on Windows 10/11).

---

## 📂 Project Structure / Struttura del Progetto

To make this project accessible to everyone, the documentation and source code comments are available in two languages:

### :uk: [English Version](./en/README.md)
Inside the `en/` folder, you will find the source code with full English comments and a dedicated English README.

### :it: [Versione Italiana](./it/README.md)
All'interno della cartella `it/` troverai il codice sorgente con commenti approfonditi in italiano e un README dedicato per gli sviluppatori del Bel Paese.

---

## 🛠️ Requirements / Requisiti
* **Assembler:** MASM32 SDK (installed in `C:\masm32`)
* **Operating System:** Windows 7/10/11
* **Video Card:** Modern GPU with OpenGL support (32-bit color recommended for Fullscreen mode)

## 🚀 Quick Start
1. Clone the repository.
2. Navigate to your preferred language folder (`en/` or `it/`).
3. Use the MASM32 `ml.exe` and `link.exe` (or your favorite IDE like RadASM or Visual Studio) to build the `.asm` file. 
4. 3. Build Automation: > A helper script (a.bat) is provided for quick compilation via CMD. Usage example:

a filename (without extension)

(e.g., a lesson1 to build lesson1.asm).

⚠️ Important - If the script fails: > If you get an error like "command not found" or the build doesn't start, it's likely because your MASM32 SDK is installed in a different path or not added to your System PATH.

To fix this: Open a.bat with a text editor and change the paths (e.g., \masm32\bin\ml) to match your actual installation folder (e.g., C:\masm32\bin or D:\masm32\bin).