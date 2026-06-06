import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../ui/router/app_router.dart';
import '../view_models/notification_view_model.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppRouter.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<NotificationViewModel>().fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationViewModel>();

    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        title: const Text(
          'Pemberitahuan',
          style: TextStyle(
            color: AppColor.darkGray,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColor.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColor.darkGray),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (viewModel.notifications.isNotEmpty && viewModel.unreadCount > 0)
            TextButton(
              onPressed: () => viewModel.markAllAsRead(),
              child: const Text(
                'Baca Semua',
                style: TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.fetchNotifications(),
        color: AppColor.primary,
        child: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : viewModel.error != null
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(viewModel.error!),
                      ),
                    ),
                  )
                : viewModel.notifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationList(context, viewModel),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Pemberitahuan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColor.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Anda akan menerima pemberitahuan tentang aktivitas pengobatan di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context, NotificationViewModel viewModel) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: viewModel.notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.8),
      itemBuilder: (context, index) {
        final notif = viewModel.notifications[index];
        return InkWell(
          onTap: () {
            if (!notif.isRead) {
              viewModel.markAsRead(notif.id);
            }
            // Navigate based on type
            _handleNotificationTap(context, notif.type);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            color: notif.isRead ? Colors.transparent : AppColor.primaryLight.withOpacity(0.3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar / Icon
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getIconBackgroundColor(notif.type),
                  backgroundImage: notif.senderPhotoUrl != null
                      ? NetworkImage(notif.senderPhotoUrl!)
                      : null,
                  child: notif.senderPhotoUrl == null
                      ? Icon(
                          _getNotificationIcon(notif.type),
                          color: _getIconColor(notif.type),
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: AppColor.darkGray,
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColor.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: notif.isRead ? AppColor.neutralGray : AppColor.darkGray.withOpacity(0.8),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(notif.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'medication_proof_submitted':
        return Icons.image_outlined;
      case 'medication_proof_confirmed':
        return Icons.check_circle_outline;
      case 'medication_proof_rejected':
        return Icons.cancel_outlined;
      case 'supervision_requested':
        return Icons.person_add_alt_1_outlined;
      case 'supervision_accepted':
        return Icons.group_add_outlined;
      case 'supervision_rejected':
        return Icons.group_remove_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconBackgroundColor(String type) {
    switch (type) {
      case 'medication_proof_confirmed':
      case 'supervision_accepted':
        return AppColor.success.withOpacity(0.15);
      case 'medication_proof_rejected':
      case 'supervision_rejected':
        return AppColor.error.withOpacity(0.15);
      case 'supervision_requested':
      case 'medication_proof_submitted':
        return AppColor.primary.withOpacity(0.15);
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'medication_proof_confirmed':
      case 'supervision_accepted':
        return AppColor.success;
      case 'medication_proof_rejected':
      case 'supervision_rejected':
        return AppColor.error;
      case 'supervision_requested':
      case 'medication_proof_submitted':
        return AppColor.primary;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    }
  }

  void _handleNotificationTap(BuildContext context, String type) {
    // Navigate user based on the notification type
    switch (type) {
      case 'medication_proof_submitted':
        // Supervisor Home shows verifying list
        context.go('/');
        break;
      case 'supervision_requested':
        // Supervisor Patients list shows requests
        context.go('/patients');
        break;
      case 'medication_proof_confirmed':
      case 'medication_proof_rejected':
        // Patient History
        context.go('/history');
        break;
      case 'supervision_accepted':
      case 'supervision_rejected':
        // Patient Home
        context.go('/');
        break;
      default:
        break;
    }
  }
}
