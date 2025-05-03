import 'package:image/image.dart';
import 'package:zxing2/qrcode.dart';

/// QR code extensions on [Image].
extension ImageQrScanning on Image {
  /// Attempts to find and decode a QR code within this [Image].
  QrCode readQrCode() {
    final rgbLuminanceSource = RGBLuminanceSource(
      width,
      height,
      convert(numChannels: 4) //
          .getBytes(order: ChannelOrder.abgr)
          .buffer
          .asInt32List(),
    );

    try {
      final binarizer = HybridBinarizer(rgbLuminanceSource);
      final binaryBitmap = BinaryBitmap(binarizer);
      return QRCodeReader().decode(binaryBitmap);
    } on ReaderException {
      // We failed to find a QR code when looking for a dark QR code
      // on a light background. Ignore this exception and try to look
      // for inverted colors.
    }

    try {
      final binarizer = HybridBinarizer(
        InvertedLuminanceSource(
          rgbLuminanceSource,
        ),
      );
      final binaryBitmap = BinaryBitmap(binarizer);
      return QRCodeReader().decode(binaryBitmap);
    } on ReaderException catch (exception) {
      throw CouldNotReadQrCodeException(exception);
    }
  }
}

typedef QrCode = Result;

class CouldNotReadQrCodeException implements Exception {
  const CouldNotReadQrCodeException([this.rootCause]);

  final Exception? rootCause;

  @override
  String toString() => "CouldNotReadQrCodeException";
}
