import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final file = File('assets/images/images.png');
  final image = img.decodeImage(await file.readAsBytes());
  if (image != null) {
    int size = image.width > image.height ? image.width : image.height;
    final paddedImage = img.Image(width: size, height: size);
    img.fill(paddedImage, color: img.ColorRgba8(255, 255, 255, 0)); // Transparent background
    
    int dstX = (size - image.width) ~/ 2;
    int dstY = (size - image.height) ~/ 2;
    img.compositeImage(paddedImage, image, dstX: dstX, dstY: dstY);
    
    File('assets/images/images_square.png').writeAsBytesSync(img.encodePng(paddedImage));
    print('Image padded successfully');
  } else {
    print('Failed to decode image');
  }
}
