import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_color.dart';

/// Sebuah widget *reusable* input teks standar yang konsisten dengan tema desain TBCare.
///
/// Widget ini membungkus label teks di atas kolom input dan [TextFormField],
/// serta mendukung pengelolaan state `obscureText` internal saat [isPassword] bernilai `true`.
class AppTextField extends StatefulWidget {
  /// Label teks yang dirender tebal di atas kolom input.
  /// Jika bernilai `null`, label tidak akan ditampilkan.
  final String? label;

  /// Placeholder teks yang ditampilkan saat kolom input kosong.
  final String? hint;

  /// Pesan bantuan berupa teks kecil di bawah kolom input.
  final String? helperText;

  /// Pesan error berupa teks merah kecil di bawah kolom input.
  final String? errorText;

  /// Controller untuk mengontrol teks di dalam input field.
  final TextEditingController controller;

  /// Menentukan apakah input ini didesain khusus untuk password.
  /// Jika `true`, visual input akan disamarkan secara default dan menampilkan ikon
  /// toggle (show/hide password) yang terkelola secara otomatis di sebelah kanan.
  final bool isPassword;

  /// Menentukan apakah input field aktif/dapat diinteraksi.
  final bool enabled;

  /// Menentukan apakah input field bersifat read-only.
  final bool readOnly;

  /// Tipe keyboard yang akan dimunculkan saat input field aktif.
  final TextInputType? keyboardType;

  /// Aksi tombol enter pada keyboard (misal: next, done, search).
  final TextInputAction? textInputAction;

  /// Kapitalisasi teks otomatis yang berlaku pada input field.
  final TextCapitalization textCapitalization;

  /// Jumlah baris maksimal untuk input multiline (seperti textarea).
  /// Default-nya adalah `1`.
  final int maxLines;

  /// Daftar formatter untuk membatasi input teks (misal: membatasi angka saja).
  final List<TextInputFormatter>? inputFormatters;

  /// Callback yang dipicu setiap kali nilai input teks berubah.
  final ValueChanged<String>? onChanged;

  /// Callback ketika pengguna menekan tombol aksi enter/kirim pada keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Callback saat input field diklik (misal: untuk memicu BottomSheet atau DatePicker).
  final VoidCallback? onTap;

  /// Fungsi validator opsional untuk integrasi dengan form validation bawaan Flutter.
  final FormFieldValidator<String>? validator;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    required this.controller,
    this.isPassword = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColor.darkGray,
              ),
            ),
          ),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          validator: widget.validator,
          style: const TextStyle(fontSize: 14, color: AppColor.darkGray),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColor.neutralGray.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            helperText: widget.helperText,
            helperStyle: TextStyle(
              color: AppColor.neutralGray.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            errorText: widget.errorText,
            errorStyle: const TextStyle(color: AppColor.error, fontSize: 12),
            filled: true,
            fillColor: widget.enabled
                ? AppColor.white
                : AppColor.lightGray.withValues(alpha: 0.2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColor.neutralGray.withValues(alpha: 0.25),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColor.neutralGray.withValues(alpha: 0.5),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColor.neutralGray.withValues(alpha: 0.1),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColor.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColor.error, width: 2),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    splashRadius: 24,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        key: ValueKey(_obscureText),
                        color: AppColor.neutralGray,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
