import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BluetoothHomePage(title: 'Bluetooth Demo'),
    );
  }
}

class BluetoothHomePage extends StatefulWidget {
  const BluetoothHomePage({super.key, required this.title});

  final String title;

  @override
  State<BluetoothHomePage> createState() => _BluetoothHomePageState();
}

class _BluetoothHomePageState extends State<BluetoothHomePage> {
  // Istanza di FlutterReactiveBle
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  
  // Lista dei dispositivi Bluetooth rilevati
  final List<DiscoveredDevice> _discoveredDevices = [];
  
  // Stream di sottoscrizione per la scansione
  StreamSubscription? _scanSubscription;
  
  // Stato della scansione
  bool _isScanning = false;
  
  // Stato del Bluetooth
  BleStatus _bleStatus = BleStatus.unknown;
  
  // Stream di sottoscrizione per lo stato del Bluetooth
  late StreamSubscription _statusSubscription;

  @override
  void initState() {
    super.initState();
    // Richiesta dei permessi necessari
    _requestPermissions();
    
    // Listener per i cambiamenti dello stato Bluetooth
    _statusSubscription = _ble.statusStream.listen((status) {
      setState(() {
        _bleStatus = status;
      });
      
      // Ferma la scansione se il Bluetooth viene disattivato
      if (status != BleStatus.ready && _isScanning) {
        _stopScan();
      }
    });
  }

  @override
  void dispose() {
    // Pulizia delle sottoscrizioni
    _scanSubscription?.cancel();
    _statusSubscription.cancel();
    super.dispose();
  }

  // Richiesta dei permessi necessari (posizione e Bluetooth)
  Future<void> _requestPermissions() async {
    if (await Permission.bluetooth.isDenied ||
        await Permission.bluetoothScan.isDenied ||
        await Permission.bluetoothConnect.isDenied ||
        await Permission.location.isDenied) {
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.location.request();
    }
  }

  // Controllo se il Bluetooth è attivo
  bool get _isBluetoothOn => _bleStatus == BleStatus.ready;

  // Avvia la scansione dei dispositivi Bluetooth
  void _startScan() {
    // Richiedi permessi prima di iniziare la scansione
    _requestPermissions().then((_) {
      setState(() {
        _discoveredDevices.clear();
        _isScanning = true;
      });

      // Avvia la scansione con timeout di 15 secondi
      _scanSubscription = _ble.scanForDevices(
        withServices: [], // Nessun servizio specifico, scansiona tutti i dispositivi
        scanMode: ScanMode.balanced,
      ).listen(
        (device) {
          // Verifica se il dispositivo è già nella lista
          final deviceIndex = _discoveredDevices.indexWhere(
            (d) => d.id == device.id,
          );
          
          setState(() {
            if (deviceIndex >= 0) {
              // Aggiorna il dispositivo se già presente
              _discoveredDevices[deviceIndex] = device;
            } else {
              // Aggiungi il nuovo dispositivo alla lista
              _discoveredDevices.add(device);
            }
          });
        },
        onError: (error) {
          print('Errore durante la scansione: $error');
          _stopScan();
        },
      );

      // Ferma la scansione dopo 15 secondi
      Future.delayed(const Duration(seconds: 15), () {
        if (_isScanning) {
          _stopScan();
        }
      });
    });
  }

  // Ferma la scansione dei dispositivi Bluetooth
  void _stopScan() {
    _scanSubscription?.cancel();
    setState(() {
      _isScanning = false;
    });
  }

  // Connessione a un dispositivo Bluetooth
  Future<void> _connectToDevice(DiscoveredDevice device) async {
    try {
      // Mostra un indicatore di caricamento
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connessione a ${device.name.isNotEmpty ? device.name : device.id}...')),
      );
      
      // Stabilisci la connessione
      final connection = _ble.connectToDevice(
        id: device.id,
        connectionTimeout: const Duration(seconds: 5),
      );
      
      connection.listen(
        (connectionState) {
          if (!mounted) return;
          
          // Mostra lo stato della connessione
          if (connectionState.connectionState == DeviceConnectionState.connected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Connesso a ${device.name.isNotEmpty ? device.name : device.id}')),
            );
          } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Disconnesso da ${device.name.isNotEmpty ? device.name : device.id}')),
            );
          }
        },
        onError: (error) {
          if (!mounted) return;
          
          print('Errore durante la connessione: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore di connessione: $error')),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      
      print('Eccezione durante il tentativo di connessione: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  // Ottieni il testo per lo stato del Bluetooth
  String _getBleStatusText() {
    switch (_bleStatus) {
      case BleStatus.ready:
        return 'Attivo';
      case BleStatus.poweredOff:
        return 'Disattivato';
      case BleStatus.unauthorized:
        return 'Non autorizzato';
      case BleStatus.unsupported:
        return 'Non supportato';
      default:
        return 'Sconosciuto';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Stato Bluetooth
          Container(
            padding: const EdgeInsets.all(16),
            color: _isBluetoothOn ? Colors.green.shade100 : Colors.red.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bluetooth: ${_getBleStatusText()}',
                  style: TextStyle(
                    color: _isBluetoothOn ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Apri le impostazioni Bluetooth del sistema
                    await openAppSettings();
                  },
                  child: const Text('Impostazioni'),
                ),
              ],
            ),
          ),
          
          // Stato scansione
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Scansione in corso...'),
                ],
              ),
            ),
          
          // Lista dispositivi trovati
          Expanded(
            child: _discoveredDevices.isEmpty
                ? const Center(child: Text('Nessun dispositivo trovato'))
                : ListView.builder(
                    itemCount: _discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = _discoveredDevices[index];
                      final name = device.name.isNotEmpty ? device.name : 'Dispositivo sconosciuto';
                      
                      return ListTile(
                        title: Text(name),
                        subtitle: Text(
                          'RSSI: ${device.rssi} dBm | ID: ${device.id}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: ElevatedButton(
                          child: const Text('Connetti'),
                          onPressed: () => _connectToDevice(device),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isBluetoothOn
            ? (_isScanning ? _stopScan : _startScan)
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bluetooth non attivo. Attivalo dalle impostazioni')),
                ),
        tooltip: _isScanning ? 'Ferma scansione' : 'Avvia scansione',
        child: Icon(_isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}
