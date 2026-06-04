# Tutorial: OpenGL Basics in MASM32 (English Version)

Welcome to the port of the classic NeHe tutorials for the **MASM32** environment. This code is not just a literal translation from C++, but a thoughtful adaptation for modern low-level Windows architectures.

## 🐞 Fixed Bugs and Technical Notes
In this version, we’ve addressed and resolved several critical issues that often discourage beginners from learning Assembly:

* **The 16-bit Mystery:** Many original tutorials use 16-bit color in full-screen mode. On modern monitors, this causes a critical failure. We have updated the code to support **32-bit**, ensuring compatibility with current GPUs.
* **FPU and 64-bit Parameters:** OpenGL often requires double precision (`REAL8`). We have implemented manual parameter passing on the stack for functions such as `gluPerspective` and `glClearDepth`.

## 🛠️ Technical Focus: The `MpushReal4` Macro

One of the main challenges in porting OpenGL tutorials from C++ to MASM32 is handling floating-point parameters. 

Functions such as `glTranslatef`, `glVertex3f`, and `glColor3f` require 32-bit floating-point values (`REAL4`). However, the native x86 `push` instruction does not directly accept textual decimal values in MASM, and using general-purpose registers (such as `EAX`) can conflict with OpenGL’s internal state or function return values.

To elegantly solve this problem, the memory-aligned macro `MpushReal4` was designed:

```assembly
MpushReal4 MACRO real_value
    LOCAL hex
    .data
        ALIGN 4
        hex REAL4 real_value
    .code
    push DWORD PTR [hex]
ENDM

## 🤝 Acknowledgments
Special thanks to **Gemini**, my AI assistant, who helped me with active code debugging, assisting me in tracking down the most stubborn bugs related to register management and hardware compatibility.

---
*Developed with passion to preserve the art of Assembly.*