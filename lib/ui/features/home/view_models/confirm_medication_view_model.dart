import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/services/supabase_service.dart';
import './home_view_model.dart';

class ConfirmMedicationViewModel extends ChangeNotifier {
  final HomeViewModel homeViewModel;
  final int scheduleId;
  final String medName;
  final String scheduleTime;
  final SupabaseService _supabaseService;

  ConfirmMedicationViewModel({
    required this.homeViewModel,
    required this.scheduleId,
    required this.medName,
    required this.scheduleTime,
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  File? _imageFile;
  File? get imageFile => _imageFile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final ImagePicker _picker = ImagePicker();

  bool _showSimulationOption = false;
  bool get showSimulationOption => _showSimulationOption;

  Future<void> pickImage(ImageSource source) async {
    _error = null;
    notifyListeners();
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
        _showSimulationOption = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Gagal mengambil gambar: $e';
      notifyListeners();
    }
  }

  Uint8List _compressImage(Uint8List originalBytes) {
    // Decode image safely
    final image = img.decodeImage(originalBytes);
    if (image == null) return originalBytes;

    // Resize image to max 400px width/height to make it extremely lightweight
    final resized = img.copyResize(
      image,
      width: image.width > image.height ? 400 : null,
      height: image.height >= image.width ? 400 : null,
    );

    // Encode to JPEG with low quality (30%)
    return Uint8List.fromList(img.encodeJpg(resized, quality: 30));
  }

  Future<void> submitConfirmation(BuildContext context) async {
    if (_imageFile == null) {
      _error = 'Silakan ambil foto bukti minum obat terlebih dahulu.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final originalBytes = await _imageFile!.readAsBytes();
      final compressedBytes = _compressImage(originalBytes);

      // Unique filename
      final fileName = '${scheduleId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'evidence/$fileName';

      // Ensure bucket exists in Supabase storage
      try {
        await _supabaseService.client.storage.createBucket('medication_evidence');
      } catch (_) {
        // Bucket might already exist, ignore error
      }

      // Upload binary to Supabase Storage
      await _supabaseService.client.storage
          .from('medication_evidence')
          .uploadBinary(
            path,
            compressedBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      // Get public URL
      final String publicUrl = _supabaseService.client.storage
          .from('medication_evidence')
          .getPublicUrl(path);

      // Call homeViewModel to confirm and update UI
      await homeViewModel.confirmMedicationTaken(scheduleId, photoUrl: publicUrl);

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfirmasi minum obat berhasil disimpan!'),
            backgroundColor: Color(0xFF1CB37D),
          ),
        );
      }
    } catch (e) {
      _error = 'Gagal menyimpan konfirmasi: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}
