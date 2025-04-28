import 'package:image/image.dart';
import 'package:zxing2/qrcode.dart';

extension ImageQrScanning on Image {
  QrCode readQrCode() {
    final rgbLuminanceSource = RGBLuminanceSource(
      width,
      height,
      convert(numChannels: 4) //
          .getBytes(order: ChannelOrder.abgr)
          .buffer
          .asInt32List(),
    );
    final binarizer = HybridBinarizer(rgbLuminanceSource);
    final binaryBitmap = BinaryBitmap(binarizer);
    return QRCodeReader().decode(binaryBitmap);
  }
}

typedef QrCode = Result;
