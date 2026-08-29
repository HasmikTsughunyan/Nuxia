// core/utils/image_picker_service.dart
//import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  /// Универсальный метод выбора изображения из галереи с автоматическим сжатием.
  /// Возвращает объект с байтами и именем файла, или null, если пользователь передумал.
  static Future<PickedImageData?> pickAndCompressImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Вызываем пикер с эталонными параметрами сочности и веса (1024px, 75% качества)
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        
        debugPrint('=== IMAGE SERVICE: Файл оптимизирован: ${image.name} ===');
        debugPrint('=== IMAGE SERVICE: Финальный вес: ${(bytes.length / 1024).toStringAsFixed(1)} КБ ===');
        
        return PickedImageData(
          bytes: bytes,
          name: image.name,
        );
      }
    } catch (e) {
      debugPrint('❌ Критическая ошибка внутри ImagePickerService: $e');
    }
    return null; // Пользователь закрыл диалог выбора
  }
}

/// Удобный класс-контейнер для возвращаемых данных
class PickedImageData {
  final Uint8List bytes;
  final String name;

  PickedImageData({required this.bytes, required this.name});
}
