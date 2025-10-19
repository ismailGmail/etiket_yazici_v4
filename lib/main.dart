import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'printer_service.dart';
import 'print_preview_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Etiket Yazıcı',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? scannedCode;
  Map<String, Map<String, String>> productList = {};
  bool loading = false;

  final String spreadsheetId = "1UOYEA95mhM0mlgJ2u-RumgipaOMczHURNWhoXAfYDQw";
  final String gid = "0";

  String get sheetUrl =>
      "https://docs.google.com/spreadsheets/d/$spreadsheetId/export?format=csv&gid=$gid";

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse(sheetUrl));
      if (response.statusCode == 200) {
        final csvTable =
            const CsvToListConverter().convert(utf8.decode(response.bodyBytes));
        for (int i = 1; i < csvTable.length; i++) {
          final row = csvTable[i];
          if (row.isNotEmpty && row.length >= 3) {
            productList[row[0].toString()] = {
              "name": row[1].toString(),
              "link": row[2].toString(),
            };
          }
        }
      }
    } catch (e) {
      debugPrint("CSV yükleme hatası: $e");
    }
    setState(() => loading = false);
  }

  void _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (result != null) setState(() => scannedCode = result);
  }

  @override
  Widget build(BuildContext context) {
    final product = scannedCode != null ? productList[scannedCode!] : null;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          "Etiket Yazıcı",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 40),
                    ),
                    onPressed: _scanBarcode,
                    child: const Text(
                      "BARKOD OKU",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (scannedCode != null)
                    if (product != null) ...[
                      Text("Ürün: ${product["name"]}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 40),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrintPreviewScreen(
                                name: product["name"]!,
                                barcode: scannedCode!,
                                declaration: product["link"]!,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "ÖNİZLEME / YAZDIR",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      )
                    ] else
                      const Text(
                        "Ürün bulunamadı",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                ],
              ),
      ),
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});
  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Barkod Okut")),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (scanned) return;
          final code = capture.barcodes.first.rawValue;
          if (code != null) {
            scanned = true;
            controller.stop();
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
