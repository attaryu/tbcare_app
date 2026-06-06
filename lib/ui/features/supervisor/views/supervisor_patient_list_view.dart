import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';

class PatientDummy {
  final String id;
  final String name;
  final String avatarUrl;
  final String phase;

  PatientDummy({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.phase,
  });
}

class RequestDummy {
  final String id;
  final String name;
  final String avatarUrl;
  final String time;

  RequestDummy({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.time,
  });
}

class SupervisorPatientListView extends StatefulWidget {
  const SupervisorPatientListView({super.key});

  @override
  State<SupervisorPatientListView> createState() => _SupervisorPatientListViewState();
}

class _SupervisorPatientListViewState extends State<SupervisorPatientListView> {
  // Local state for mockup manipulation
  late List<RequestDummy> _requests;
  late List<PatientDummy> _patients;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Mockup testing states: 'normal', 'empty', 'error'
  String _uiState = 'normal';

  @override
  void initState() {
    super.initState();
    _resetData();
  }

  void _resetData() {
    _requests = [
      RequestDummy(
        id: 'req1',
        name: 'Jaxson Donin',
        avatarUrl: 'https://i.pravatar.cc/150?img=11',
        time: 'Hari ini, 12:30 WIB',
      ),
      RequestDummy(
        id: 'req2',
        name: 'Skylar Aminoff',
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
        time: 'Kemarin, 14:30 WIB',
      ),
    ];
    _patients = [
      PatientDummy(
        id: 'pat1',
        name: 'Rayna Levin',
        avatarUrl: 'https://i.pravatar.cc/150?img=9',
        phase: 'Fase Intensif - Bulan ke-2',
      ),
      PatientDummy(
        id: 'pat2',
        name: 'Terry Korsgaard',
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        phase: 'Fase Intensif - Bulan ke-2',
      ),
    ];
    _searchQuery = '';
    _searchCtrl.clear();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _copySupervisorCode() {
    Clipboard.setData(const ClipboardData(text: 'A7B29C'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kode unik pengawas berhasil disalin!'),
        backgroundColor: AppColor.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _acceptRequest(RequestDummy request) {
    setState(() {
      _requests.removeWhere((r) => r.id == request.id);
      _patients.add(
        PatientDummy(
          id: 'pat_${DateTime.now().millisecondsSinceEpoch}',
          name: request.name,
          avatarUrl: request.avatarUrl,
          phase: 'Fase Intensif - Bulan ke-1',
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permintaan ${request.name} diterima'),
        backgroundColor: AppColor.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rejectRequest(RequestDummy request) {
    setState(() {
      _requests.removeWhere((r) => r.id == request.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permintaan ${request.name} ditolak'),
        backgroundColor: AppColor.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPatientDetail(PatientDummy patient) {
    AppDialog.info(
      context,
      title: 'Detail Pasien',
      icon: Icons.person_outline,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(patient.avatarUrl),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              patient.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.darkGray,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              patient.phase,
              style: const TextStyle(
                fontSize: 14,
                color: AppColor.neutralGray,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          _buildInfoRow('ID Pasien', patient.id),
          const SizedBox(height: 8),
          _buildInfoRow('Status Pengobatan', 'Aktif'),
          const SizedBox(height: 8),
          _buildInfoRow('Kepatuhan Minum Obat', '95%'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColor.neutralGray, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColor.darkGray,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _deletePatient(PatientDummy patient) {
    AppDialog.confirm(
      context,
      title: 'Hapus Pasien',
      message: 'Apakah Anda yakin ingin menghapus ${patient.name} dari daftar pengawasan?',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      confirmColor: AppButtonColor.danger,
      icon: Icons.person_remove_outlined,
      onConfirm: () {
        setState(() {
          _patients.removeWhere((p) => p.id == patient.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${patient.name} dihapus dari daftar pengawasan'),
            backgroundColor: AppColor.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine datasets based on mockup UI test states
    final displayRequests = _uiState == 'normal' ? _requests : <RequestDummy>[];
    final filteredPatients = _uiState == 'normal'
        ? _patients
            .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList()
        : <PatientDummy>[];

    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Area
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kelola Pasien',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColor.darkGray,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/patients/history'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppColor.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _resetData();
                  });
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Error state top warning banner
                    if (_uiState == 'error')
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: AppColor.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColor.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColor.error),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Gagal memuat data pengawasan. Silakan coba lagi nanti.',
                                  style: TextStyle(
                                    color: AppColor.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, color: AppColor.error),
                                onPressed: () {
                                  setState(() {
                                    _uiState = 'normal';
                                    _resetData();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Section 1: Unique Code Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: AppColor.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kode Unik Pengawas',
                                style: TextStyle(
                                  color: AppColor.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                decoration: BoxDecoration(
                                  color: AppColor.primaryLight.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'A7B29C',
                                      style: TextStyle(
                                        color: AppColor.darkGray,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _copySupervisorCode,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          color: AppColor.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.copy_rounded,
                                          color: AppColor.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Bagikan kode ini agar pasien dapat terhubung dengan Anda',
                                style: TextStyle(
                                  color: AppColor.white.withOpacity(0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Section 2: Join Request Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Permintaan Bergabung',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColor.darkGray,
                              ),
                            ),
                            if (displayRequests.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColor.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${displayRequests.length} Baru',
                                  style: const TextStyle(
                                    color: AppColor.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Section 2 content
                    if (_uiState == 'error')
                      SliverToBoxAdapter(
                        child: _buildSectionErrorPlaceholder(),
                      )
                    else if (displayRequests.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyRequestState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final request = displayRequests[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: AppColor.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColor.lightGray, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColor.primaryLight,
                                      backgroundImage: NetworkImage(request.avatarUrl),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            request.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColor.darkGray,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            request.time,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColor.neutralGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Action buttons: cross & checkmark
                                    IconButton(
                                      onPressed: () => _rejectRequest(request),
                                      icon: const Icon(Icons.close_rounded),
                                      color: AppColor.white,
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColor.error,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        minimumSize: const Size(36, 36),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _acceptRequest(request),
                                      icon: const Icon(Icons.check_rounded),
                                      color: AppColor.white,
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColor.success,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        minimumSize: const Size(36, 36),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: displayRequests.length,
                          ),
                        ),
                      ),

                    // Section 3: Patient List Title & Search
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 20.0, bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daftar Pasien',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColor.darkGray,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Search bar
                            TextField(
                              controller: _searchCtrl,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Cari nama pasien...',
                                hintStyle: const TextStyle(color: AppColor.neutralGray),
                                prefixIcon: const Icon(Icons.search_rounded, color: AppColor.neutralGray),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: AppColor.neutralGray),
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = '';
                                            _searchCtrl.clear();
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColor.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: AppColor.neutralGray.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: AppColor.neutralGray.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: AppColor.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Section 3 content
                    if (_uiState == 'error')
                      SliverToBoxAdapter(
                        child: _buildSectionErrorPlaceholder(),
                      )
                    else if (filteredPatients.isEmpty)
                      SliverToBoxAdapter(
                        child: _searchQuery.isNotEmpty
                            ? _buildSearchEmptyState()
                            : _buildEmptyPatientState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final patient = filteredPatients[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: AppColor.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColor.lightGray, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColor.primaryLight,
                                      backgroundImage: NetworkImage(patient.avatarUrl),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            patient.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColor.darkGray,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            patient.phase,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColor.neutralGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Dropdown Menu Button
                                    PopupMenuButton<String>(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColor.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.more_horiz_rounded,
                                          color: AppColor.white,
                                          size: 18,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'detail') {
                                          _showPatientDetail(patient);
                                        } else if (value == 'delete') {
                                          _deletePatient(patient);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'detail',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_outline, color: AppColor.darkGray, size: 20),
                                              SizedBox(width: 8),
                                              Text('Lihat Detail', style: TextStyle(color: AppColor.darkGray)),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_remove_outlined, color: AppColor.error, size: 20),
                                              SizedBox(width: 8),
                                              Text(
                                                'Hapus dari Pengawasan',
                                                style: TextStyle(color: AppColor.error),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: filteredPatients.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Demo/Preview State Toggles (Only visible in prototype to test UI variations)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: AppColor.lightGray,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('State Demo:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.darkGray)),
                  _buildStateSelectorButton('Normal', 'normal'),
                  _buildStateSelectorButton('Kosong', 'empty'),
                  _buildStateSelectorButton('Error', 'error'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateSelectorButton(String label, String state) {
    final isSelected = _uiState == state;
    return InkWell(
      onTap: () {
        setState(() {
          _uiState = state;
          if (state == 'normal') {
            _resetData();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary : AppColor.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColor.primary : AppColor.neutralGray.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColor.white : AppColor.darkGray,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRequestState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColor.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Permintaan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColor.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Belum ada pasien yang meminta bergabung.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColor.neutralGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPatientState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColor.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Pasien',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColor.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bagikan kode pengawasan Anda agar pasien dapat terhubung dengan Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColor.neutralGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColor.neutralGray,
          ),
          const SizedBox(height: 12),
          Text(
            'Pencarian Tidak Ditemukan',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColor.darkGray,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pasien dengan nama "$_searchQuery" tidak terdaftar.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColor.neutralGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionErrorPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.error.withOpacity(0.3), width: 1.5),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 40,
            color: AppColor.error,
          ),
          SizedBox(height: 8),
          Text(
            'Gagal Memuat Data',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColor.error,
            ),
          ),
        ],
      ),
    );
  }
}
