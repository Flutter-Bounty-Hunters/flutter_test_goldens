import 'package:image/image.dart';
import 'package:zxing2/qrcode.dart';

/// QR code extensions on [Image].
extension ImageQrScanning on Image {
  /// Returns the first QR code found within this [Image], or `null` if no QR code is found.
  ///
  /// If there are multiple QR codes in the image, it returns the first one it finds
  /// from top to bottom.
  QrCode? readQrCode() {
    return _readQrCode(this);
  }

  /// Attempts to find and decode all QR codes within this [Image].
  List<QrCode> readAllQrCodes() {
    final qrCodes = <QrCode>[];

    final image = clone();

    // Keep looking for QR codes until we can't find anymore.
    bool keepSearching = true;
    while (keepSearching) {
      final qrcode = _readQrCode(image);
      if (qrcode == null) {
        keepSearching = false;
        continue;
      }

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
      fillRect(
        image,
        x1: left,
        y1: top,
        x2: right,
        y2: bottom,
        color: ColorRgb8(0, 0, 0),
      );
    }

    return qrCodes;
  }
}

QrCode? _readQrCode(Image image) {
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
  } on ReaderException {
    // We didn't find a QR code in the image.
    return null;
  }
}

typedef QrCode = Result;
