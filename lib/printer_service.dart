import 'dart:async';
import 'package:http/http.dart' as http;

class PrinterService {
  /// Etiket verisini PC üzerindeki yazıcı sunucusuna gönderir
  static Future<String> printLabel(
      String name, String barcode, String declaration) async {
    try {
      // ⚙️ Buraya yazıcının bağlı olduğu PC'nin IP adresini yaz
      const String serverIp = "192.168.64.109"; // örnek
      const int port = 5000;

      // GODEX yazıcı için TSPL komut dizisi
      final tspl = """
SIZE 60 mm,40 mm
GAP 2 mm,0
DENSITY 8
SPEED 4
DIRECTION 1
CLS
TEXT 100,50,"3",0,1,1,"$name"
BARCODE 100,100,"128",100,1,0,2,2,"$barcode"
TEXT 100,230,"3",0,1,1,"$declaration"
PRINT 1
""";

      // Yazıcı sunucusuna HTTP POST isteği gönder
      final response = await http.post(
        Uri.parse("http://$serverIp:$port/print"),
        body: tspl,
        headers: {'Content-Type': 'text/plain'},
      );

      if (response.statusCode == 200) {
        return "Yazdırma başarılı ✅";
      } else {
        return "Sunucu hatası: ${response.statusCode}";
      }
    } catch (e) {
      return "Yazdırma hatası: $e";
    }
  }
}
