import 'package:absensi_app/widgets/snackbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api.dart';

// ── Design tokens ────────────────────────────────────────────────
const _ink = Color(0xFF10172A);
const _inkSoft = Color(0xFF1B2540);
const _teal = Color(0xFF1F8A70);
const _tealSoft = Color(0xFFE4F3EF);
const _paper = Color(0xFFF7F7F5);
const _textDark = Color(0xFF1B1F27);
const _muted = Color(0xFF8A93A6);
const _border = Color(0xFFE3E5E8);

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  String _role = 'user';

  bool _isSubmitting = false;
  String? _errorMessage;

  List<String> _availableRoles = ['admin', 'user'];
  bool _loadingRoles = true;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onPreviewChanged);
    _emailController.addListener(_onPreviewChanged);
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    try {
      final res = await DioClient.dio.get('/admin/user/roles');
      final roles = List<String>.from(res.data['roles'] ?? []);
      if (roles.isNotEmpty && mounted) {
        setState(() => _availableRoles = roles);
      }
    } catch (_) {
      // biarkan fallback default ['admin', 'user'] kalau gagal fetch
    } finally {
      if (mounted) setState(() => _loadingRoles = false);
    }
  }

  void _onPreviewChanged() => setState(() {});

  @override
  void dispose() {
    _usernameController.removeListener(_onPreviewChanged);
    _emailController.removeListener(_onPreviewChanged);
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String get _initials {
    final name = _usernameController.text.trim();
    if (name.isEmpty) return '?';
    if (name.length == 1) return name.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await DioClient.dio.post('/admin/user/register', data: {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _role,
      });

      if (!mounted) return;

      final generatedPassword = res.data['generatedPassword'] as String;
      final username = res.data['user']['username'] as String;

      _usernameController.clear();
      _emailController.clear();
      if (!_availableRoles.contains(_role)) {
        _availableRoles = [..._availableRoles, _role]..sort();
      }
      setState(() => _role = 'user');

      await _showGeneratedPasswordDialog(username, generatedPassword);
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? 'Gagal membuat user';
      setState(() => _errorMessage = message.toString());
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan, coba lagi');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showGeneratedPasswordDialog(String username, String password) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _tealSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_rounded, color: _teal, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('User Berhasil Dibuat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Username', username),
            const SizedBox(height: 14),
            const Text('PASSWORD SEMENTARA',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.1, color: _muted)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SelectableText(
                    password,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white70),
                    tooltip: 'Salin password',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: password));
                      showFloatingSuccessSnackbar(context, "Password disalin");
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catat password ini sekarang — tidak akan ditampilkan lagi setelah dialog ditutup. '
                          'Minta user menggantinya lewat menu Ubah Password setelah login pertama.',
                      style: TextStyle(fontSize: 12.5, color: Colors.amber.shade900, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _ink,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Saya Sudah Mencatat'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: _textDark),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(color: _muted)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const Border(),
        iconTheme: const IconThemeData(
          color: Colors.white30,
        ),
        title: const Text('Tambah User Baru'),
        titleTextStyle: TextStyle(color: Colors.white),
        centerTitle: true,
        backgroundColor: _ink,
        foregroundColor: _textDark,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: _buildBrandPanel()),
                Expanded(flex: 6, child: _buildFormPanel(isDesktop)),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMobileBanner(),
              Expanded(child: _buildFormPanel(isDesktop)),
            ],
          );
        },
      ),
    );
  }

  // ── Left brand / preview panel (desktop) ───────────────────────
  Widget _buildBrandPanel() {
    return Container(
      color: _ink,
      padding: const EdgeInsets.fromLTRB(48, 56, 48, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.badge_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 28),
          const Text(
            'Tambah\nAnggota Tim',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Akun baru dibuat dengan password sementara yang digenerate otomatis. '
                'Sistem tidak pernah menyimpan password ini dalam bentuk asli.',
            style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14, height: 1.5),
          ),
          const Spacer(),
          Text(
            'PRATINJAU KARTU ANGGOTA',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          _buildBadgeCard(),
        ],
      ),
    );
  }

  Widget _buildBadgeCard() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _inkSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(24)),
            child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username.isEmpty ? 'Nama pengguna' : username,
                  style: TextStyle(
                    color: username.isEmpty ? Colors.white.withOpacity(0.35) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email.isEmpty ? 'email@perusahaan.com' : email,
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
            child: Text(
              _role.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBanner() {
    return Container(
      width: double.infinity,
      color: _ink,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.badge_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Tambah Anggota Tim',
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBadgeCard(),
        ],
      ),
    );
  }

  // ── Right form panel ────────────────────────────────────────────
  Widget _buildFormPanel(bool isDesktop) {
    return Container(
      color: _paper,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(isDesktop ? 56 : 20, isDesktop ? 64 : 24, isDesktop ? 56 : 20, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DATA AKUN BARU',
                    style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                const Text('Lengkapi detail anggota',
                    style: TextStyle(color: _textDark, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _fieldLabel('USERNAME'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _usernameController,
                  hint: 'mis. budi.santoso',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib diisi' : null,
                ),
                const SizedBox(height: 22),
                _fieldLabel('EMAIL'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: 'mis. budi@perusahaan.com',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(v.trim())) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                _fieldLabel('ROLE'),
                const SizedBox(height: 8),
                _buildRoleSelector(),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Daftarkan Pengguna', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Password sementara akan digenerate otomatis dan hanya ditampilkan satu kali setelah user berhasil dibuat.',
                  style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 220),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: const TextStyle(color: _muted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.0));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _textDark, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _muted.withOpacity(0.7)),
        prefixIcon: Icon(icon, size: 20, color: _muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300)),
      ),
      validator: validator,
    );
  }

  Widget _buildRoleSelector() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _role),
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return _availableRoles;
        return _availableRoles.where(
              (r) => r.toLowerCase().contains(value.text.toLowerCase()),
        );
      },
      onSelected: (value) => setState(() => _role = value),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // auto-scroll field ini ke atas saat difokus, biar dropdown dapat ruang
        focusNode.addListener(() {
          if (focusNode.hasFocus) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (focusNode.context != null) {
                Scrollable.ensureVisible(
                  focusNode.context!,
                  alignment: 0.1, // field akan digeser mendekati bagian atas viewport
                  duration: const Duration(milliseconds: 250),
                );
              }
            });
          }
        });

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: _textDark, fontSize: 15),
          decoration: InputDecoration(
            hintText: _loadingRoles ? 'Memuat role...' : 'Pilih atau ketik role baru',
            hintStyle: TextStyle(color: _muted.withOpacity(0.7)),
            prefixIcon: const Icon(Icons.shield_outlined, size: 20, color: _muted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal, width: 1.5)),
          ),
          onChanged: (v) => setState(() => _role = v.trim().toLowerCase()),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Role wajib diisi';
            if (!RegExp(r'^[a-z_]+$').hasMatch(v.trim().toLowerCase())) {
              return 'Role hanya huruf kecil, tanpa spasi';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 520),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}