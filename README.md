# Prova Finale di Reti Logiche 2023-2024
La Prova Finale di Reti Logiche prevede la progettazione e lo sviluppo di un modulo hardware, descritto utilizzando il linguaggio VHDL, in grado di interfacciarsi con una memoria esterna ed elaborare una sequenza di dati nel rispetto delle specifiche tecniche fornite.
## Specifica Generale
Il modulo hardware deve:
- Elaborare una sequenza di K parole W memorizzate in una memoria esterna, ciascuna con un valore compreso tra 0 e 255.
- Gestire i valori mancanti (pari a 0), sostituendoli con l'ultimo valore valido letto nella sequenza.
- Calcolare un livello di credibilità C associato a ciascun dato: 
  - C = 31 per i dati validi (W ≠ 0). 
  - Decresce progressivamente ogni volta che si incontra un valore mancante (W = 0), fino a un minimo di 0.
- Scrivere i risultati in memoria.
## Funzionamento
Il modulo opera seguendo un protocollo definito:
1. Inizia con un reset che configura il sistema.
2. Riceve in ingresso i parametri di elaborazione, inclusi l'indirizzo iniziale della sequenza (ADD) e la lunghezza (K).
3. Elabora i dati, aggiornando le sequenza e i valori di credibilità, e segnala il completamento dell'operazione tramite un segnale DONE.
4. Supporta elaborazioni multiple senza richiedere ulteriori reset.
## Requisiti Tecnici
- Implementazione in VHDL.
- Simulazione e sintesi tramite Xilinx Vivado WebPACK.
