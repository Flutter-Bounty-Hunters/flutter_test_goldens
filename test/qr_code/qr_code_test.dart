import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

import 'package:image/image.dart' as img;

void main() {
  group('QR Code scanning >', () {
    test('reads single QR code from an image', () async {
      final image = img.decodePng(File('test/qr_code/multiple_qrcodes.png').readAsBytesSync())!;

      final qrCode = image.readQrCode();

      // In top to bottom order, the third QR code is the first one.
      expect(qrCode.text, 'Third QR Code');
    });

    test('reads multiple QR codes from a single image', () async {
      final image = img.decodePng(File('test/qr_code/multiple_qrcodes.png').readAsBytesSync())!;

      final qrCodes = image.readAllQrCodes();

      expect(qrCodes.length, 3);

      // In top to bottom order, the third QR code is the first one.
      expect(qrCodes[0].text, 'Third QR Code');
      expect(qrCodes[1].text, 'First QR Code');
      expect(qrCodes[2].text, 'Second QR Code');
    });
  });
}
