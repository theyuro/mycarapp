import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Abre o seletor de imagem do sistema uma vez por vez. Toques repetidos
/// enquanto o seletor está aberto são ignorados em vez de lançar
/// `PlatformException(already_active)`.
class ImagePickService {
  ImagePickService._();

  static bool _active = false;

  static Future<XFile?> pick({
    required ImageSource source,
    required int imageQuality,
    required double maxWidth,
    required double maxHeight,
  }) async {
    if (_active) return null;
    _active = true;
    try {
      return await ImagePicker().pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } on PlatformException catch (error) {
      if (error.code == 'already_active') return null;
      rethrow;
    } finally {
      _active = false;
    }
  }
}
