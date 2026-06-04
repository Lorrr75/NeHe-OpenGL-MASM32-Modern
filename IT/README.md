# Tutorial: Fondamenta di OpenGL in MASM32 (Versione Italiana)

Benvenuti nel porting dei classici tutorial di NeHe per l'ambiente **MASM32**. Questo codice non è solo una traduzione letterale dal C++, ma un adattamento ragionato per le moderne architetture Windows a basso livello.

## 🐞 Bug risolti e Note Tecniche
In questa versione abbiamo affrontato e risolto diverse criticità che spesso scoraggiano chi si avvicina all'Assembly:

* **Il Mistero dei 16-bit:** Molti tutorial originali usano i 16-bit per il colore in modalità schermo intero. Sui monitor moderni questo causa un fallimento critico. Abbiamo aggiornato il codice per supportare i **32-bit**, garantendo la compatibilità con le GPU attuali.
* **FPU e Parametri a 64-bit:** OpenGL richiede spesso precisione doppia (`REAL8`). Abbiamo implementato il passaggio manuale dei parametri sullo stack per funzioni come `gluPerspective` e `glClearDepth`.

## 🛠️ Focus Tecnico: La Macro `MpushReal4`

Una delle sfide principali nel porting dei tutorial OpenGL da C++ a MASM32 è la gestione dei parametri in virgola mobile. 

Funzioni come `glTranslatef`, `glVertex3f` e `glColor3f` richiedono valori a 32 bit in virgola mobile (`REAL4`). Tuttavia, l'istruzione nativa x86 `push` non accetta direttamente valori decimali testuali in MASM, e l'uso di registri di uso generale (come `EAX`) può andare in conflitto con lo stato interno di OpenGL o con i valori di ritorno delle funzioni.

Per risolvere questo problema in modo elegante, è stata progettata la macro ad allineamento di memoria `MpushReal4`:

```assembly
MpushReal4 MACRO valore_reale
    LOCAL esadecimale
    .data
        ALIGN 4
        esadecimale REAL4 valore_reale
    .code
    push DWORD PTR [esadecimale]
ENDM

## 🤝 Ringraziamenti
Un ringraziamento speciale a **Gemini**, il mio collaboratore IA, che mi ha supportato nel debug attivo del codice, aiutandomi a scovare i bug più ostici legati alla gestione dei registri e alla compatibilità hardware.

---
*Sviluppato con passione per preservare l'arte dell'Assembly.*

