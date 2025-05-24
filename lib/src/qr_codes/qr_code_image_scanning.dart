import 'package:image/image.dart';
import 'package:zxing2/qrcode.dart';

/// QR code extensions on [Image].
extension ImageQrScanning on Image {
  /// Attempts to find and decode a QR code within this [Image].
  QrCode readQrCode() {
    return _readQrCode(this);
  }

  /// Attempts to find and decode all QR codes within this [Image].
  List<QrCode> readAllQrCodes() {
    final qrCodes = <QrCode>[];

    Image image = this;

    // Keep looking for QR codes until we can't find anymore.
    while (true) {
      try {
        final qrcode = _readQrCode(image);
        qrCodes.add(qrcode);

        /// Extract the rectangles from the edge points.
        final bottomLeftRectangle = qrcode.resultPoints[0];
        final topLeftRectangle = qrcode.resultPoints[1];
        final topRightRectangle = qrcode.resultPoints[2];

        final top = topRightRectangle.y.truncate();
        final left = topLeftRectangle.x.truncate();
        final right = topRightRectangle.x.truncate();
        final bottom = bottomLeftRectangle.y.truncate();

        // Fill the QRCode region with black color to try to read other QR Codes.
        image = fillRect(
          image,
          x1: left,
          y1: top,
          x2: right,
          y2: bottom,
          color: ColorRgb8(0, 0, 0),
        );
      } on CouldNotReadQrCodeException catch (_) {
        // We didn't find any QR codes in the image. Stop looking.
        break;
      }
    }

    return qrCodes;
  }
}

QrCode _readQrCode(Image image) {
  final rgbLuminanceSource = RGBLuminanceSource(
    image.width,
    image.height,
    image
        .convert(numChannels: 4) //
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

typedef QrCode = Result;

class CouldNotReadQrCodeException implements Exception {
  const CouldNotReadQrCodeException([this.rootCause]);

  final Exception? rootCause;

  @override
  String toString() => "CouldNotReadQrCodeException";
}
