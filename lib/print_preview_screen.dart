import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'printer_service.dart';

class PrintPreviewScreen extends StatefulWidget {
  final String name;
  final String barcode;
  final String declaration;

  const PrintPreviewScreen({
    super.key,
    required this.name,
    required this.barcode,
    required this.declaration,
  });

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen> {
  String? declarationText;
  bool loading = false;
  int printCount = 1; // Yazdırılacak kopya sayısı

  @override
  void initState() {
    super.initState();
    _loadDocx();
  }

  /// Google Drive linkini .docx dosyası olarak indirip metni parse eder
  Future<void> _loadDocx() async {
    setState(() => loading = true);
    try {
      final fileId = _extractFileId(widget.declaration);
      final downloadUrl =
          "https://drive.google.com/uc?export=download&id=$fileId";

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);
        final documentXml = archive
            .firstWhere((f) => f.name == 'word/document.xml')
            .content as List<int>;

        final xml = XmlDocument.parse(utf8.decode(documentXml));
        final text =
            xml.findAllElements('w:t').map((node) => node.innerText).join(' ');
        setState(() => declarationText = text);
      } else {
        setState(() => declarationText =
            "Belge indirilemedi (HTTP ${response.statusCode})");
      }
    } catch (e) {
      setState(() => declarationText = "Belge okunamadı: $e");
    }
    setState(() => loading = false);
  }

  /// Google Drive linkinden dosya ID'sini çıkarır
  String _extractFileId(String url) {
    final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match != null ? match.group(1)! : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Önizleme / Yazdır")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ürün: ${widget.name}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Barkod: ${widget.barcode}",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    const Text("Deklarasyon:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      declarationText ?? "Belge yükleniyor...",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Adet",
                            ),
                            onChanged: (value) {
                              setState(() {
                                printCount = int.tryParse(value) ?? 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            for (int i = 0; i < printCount; i++) {
                              await PrinterService.printLabel(
                                widget.name,
                                widget.barcode,
                                declarationText ?? '',
                              );
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("$printCount kopya yazdırıldı."),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: const Text("YAZDIR",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
