# Bluetooth Flutter App

Applicazione Flutter multipiattaforma per la scansione e la connessione a dispositivi Bluetooth Low Energy (BLE).

## Descrizione
Questa app consente di:
- Attivare/disattivare il Bluetooth e visualizzarne lo stato
- Richiedere i permessi necessari su Android/iOS
- Scansionare i dispositivi BLE nelle vicinanze
- Visualizzare la lista dei dispositivi trovati (nome, RSSI, ID)
- Connettersi a un dispositivo selezionato e ricevere feedback sulla connessione

L'interfaccia è semplice e reattiva, con gestione automatica dei permessi e feedback visivo per ogni stato.

## Tecnologie e dipendenze principali
- [Flutter](https://flutter.dev/) (multipiattaforma)
- [flutter_reactive_ble](https://pub.dev/packages/flutter_reactive_ble) per gestione BLE
- [permission_handler](https://pub.dev/packages/permission_handler) per la gestione dei permessi

## Come iniziare

1. **Clona il repository**
   ```sh
   git clone https://github.com/SuperQubit/bluetooth_flutter_app.git
   cd bluetooth_flutter_app
   ```
2. **Installa le dipendenze**
   ```sh
   flutter pub get
   ```
3. **Esegui l'app**
   ```sh
   flutter run
   ```

## Note importanti
- Su Android e iOS sono necessarie autorizzazioni specifiche per il Bluetooth e la posizione
- Verifica che il dispositivo abbia il Bluetooth attivo
- La scansione dura 15 secondi per evitare consumi eccessivi

## Screenshot
*Aggiungi qui eventuali screenshot dell'app in funzione*

## Licenza
MIT
