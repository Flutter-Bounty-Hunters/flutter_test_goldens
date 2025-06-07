import 'dart:convert';
import 'dart:typed_data';

typedef PngData = Uint8List;

extension PngMetadata on PngData {
  Map<String, String> readTextMetadata() {
    const pngHeader = [137, 80, 78, 71, 13, 10, 26, 10];
    if (!sublist(0, 8).every((b) => b == pngHeader[indexOf(b)])) {
      throw FormatException('Not a valid PNG file');
    }

    final result = <String, String>{};
    int offset = 8;
    while (offset < length) {
      final dataLength = _readUint32(offset);
      final chunkType = utf8.decode(sublist(offset + 4, offset + 8));
      final dataStart = offset + 8;
      final dataEnd = dataStart + dataLength;

      // Move data offset forward.
      offset = dataEnd + 4; // +4 to skip CRC

      if (chunkType != 'tEXt') {
        continue;
      }

      final data = sublist(dataStart, dataEnd);
      final separator = data.indexOf(0);
      if (separator <= 0) {
        continue;
      }

      result[utf8.decode(data.sublist(0, separator))] = utf8.decode(data.sublist(separator + 1));
    }

    return result;
  }

  Uint8List copyWithTextMetadata(String key, String value) {
    final keyUtf8 = utf8.encode(key);

    final valueUtf8 = utf8.encode(value);
    final valueOffset = keyUtf8.length + 1;

    final totalLength = valueOffset + valueUtf8.length;

    final chunkData = Uint8List(totalLength)
      ..setRange(0, keyUtf8.length, keyUtf8)
      ..[keyUtf8.length] = 0 // `0` is the key/value divider.
      ..setRange(valueOffset, valueOffset + valueUtf8.length, valueUtf8);

    final chunkType = utf8.encode('tEXt');
    final chunkLengthBytes = ByteData(4)..setUint32(0, chunkData.length);
    final crc = _crc32(Uint8List.fromList(chunkType + chunkData));
    final crcBytes = ByteData(4)..setUint32(0, crc);

    // Find position before IEND chunk.
    final iendOffset = _findIendChunkOffset();

    return Uint8List.fromList([
      ...sublist(0, iendOffset),
      ...chunkLengthBytes.buffer.asUint8List(),
      ...chunkType,
      ...chunkData,
      ...crcBytes.buffer.asUint8List(),
      ...sublist(iendOffset),
    ]);
  }

  int _crc32(Uint8List data) {
    const int polynomial = 0xEDB88320;
    final table = List<int>.generate(256, (i) {
      int c = i;
      for (int k = 0; k < 8; k += 1) {
        c = (c & 1) != 0 ? (polynomial ^ (c >>> 1)) : (c >>> 1);
      }
      return c;
    });

    int crc = 0xFFFFFFFF;
    for (final b in data) {
      crc = table[(crc ^ b) & 0xff] ^ (crc >>> 8);
    }
    return crc ^ 0xFFFFFFFF;
  }

  int _findIendChunkOffset() {
    int offset = 8;
    while (offset < length) {
      final dataLength = _readUint32(offset);
      final type = utf8.decode(sublist(offset + 4, offset + 8));
      if (type == 'IEND') {
        return offset;
      }

      offset += 12 + dataLength;
    }

    throw FormatException("No IEND chunk found");
  }

  int _readUint32(int offset) => ByteData.sublistView(this, offset, offset + 4).getUint32(0);
}
