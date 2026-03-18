# Tutorial 1: Fondamenta di OpenGL in MASM32 (Versione Italiana)

Benvenuti nel primo capitolo del porting dei tutorial di NeHe per l'ambiente **MASM32**. Questo codice non è solo una traduzione letterale dal C++, ma un adattamento ragionato per le moderne architetture Windows.

## 🐞 Bug risolti e Note Tecniche
In questa versione abbiamo affrontato e risolto diverse criticità che spesso scoraggiano chi si avvicina all'Assembly:

* **Il Mistero dei 16-bit:** Molti tutorial originali usano i 16-bit per il colore in modalità schermo intero. Sui monitor moderni questo causa un fallimento critico. Abbiamo aggiornato il codice per supportare i **32-bit**, garantendo la compatibilità con le GPU attuali.
* **FPU e Parametri a 64-bit:** OpenGL richiede spesso precisione doppia (`REAL8`). Abbiamo implementato il passaggio manuale dei parametri sullo stack per funzioni come `gluPerspective` e `glClearDepth`.

## 🤝 Ringraziamenti
Un ringraziamento speciale a **Gemini**, il mio collaboratore IA, che mi ha supportato nel debug attivo del codice, aiutandomi a scovare i bug più ostici legati alla gestione dei registri e alla compatibilità hardware.

---
*Sviluppato con passione per preservare l'arte dell'Assembly.*