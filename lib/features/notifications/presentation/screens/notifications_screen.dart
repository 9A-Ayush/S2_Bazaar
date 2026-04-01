import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../../../features/profile/providers/profile_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _filterIndex = 0;
  final _filters = ['All', 'Orders', 'Offers', 'Alerts'];

  List<NotificationModel> _applyFilter(List<NotificationModel> all) {
    if (_filterIndex == 0) return all;
    final type = [
      null,
      NotifType.order,
      NotifType.offer,
      NotifType.alert,
    ][_filterIndex];
    return all.where((n) => n.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.text1),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: Text('Mark all read',
                style: AppTextStyles.captionBold(color: AppColors.primary)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: FilterChipRow(
              labels: _filters,
              selected: _filterIndex,
              onSelected: (i) => setState(() => _filterIndex = i),
            ),
          ),
          Expanded(
            child: notifAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final filtered = _applyFilter(all);
                final unread = filtered.where((n) => !n.isRead).toList();
                final read = filtered.where((n) => n.isRead).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    emoji: '🔔',
                    title: 'No notifications',
                    subtitle: "You're all caught up!",
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(notificationsProvider.notifier).load(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    children: [
                      if (unread.isNotEmpty) ...[
                        _DateLabel(label: 'NEW'),
                        ...unread.map((n) => Column(
                              children: [
                                _NotifItem(
                                  notif: n,
                                  onTap: () => ref
                                      .read(notificationsProvider.notifier)
                                      .markRead(n.id),
                                ),
                                const Divider(
                                    height: 1, indent: 18, endIndent: 18),
                              ],
                            )),
                      ],
                      if (read.isNotEmpty) ...[
                        _DateLabel(label: 'EARLIER'),
                        ...read.map((n) => Column(
                              children: [
                                _NotifItem(notif: n, onTap: null),
                                if (read.indexOf(n) < read.length - 1)
                                  const Divider(
                                      height: 1,
                                      indent: 18,
                                      endIndent: 18),
                              ],
                            )),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  final String label;
  const _DateLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Text(label, style: AppTextStyles.label(color: AppColors.text3)),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback? onTap;

  const _NotifItem({required this.notif, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: notif.isRead ? Colors.white : AppColors.primarySoft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!notif.isRead)
              Container(width: 4, height: 84, color: AppColors.primary),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    notif.isRead ? 18 : 12, 14, 18, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _iconBg(notif.type, notif.isRead),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text(_emoji(notif.type),
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notif.title,
                            style: notif.isRead
                                ? AppTextStyles.bodyBold(
                                    color: AppColors.text2)
                                : AppTextStyles.bodyBold(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notif.message,
                            style: AppTextStyles.caption(
                                color: notif.isRead
                                    ? AppColors.text3
                                    : AppColors.text2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _timeAgo(notif.time),
                            style: AppTextStyles.label(
                                color: notif.isRead
                                    ? AppColors.text3
                                    : AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    if (!notif.isRead)
                      const Padding(
                        padding: EdgeInsets.only(top: 4, left: 6),
                        child: CircleAvatar(
                            radius: 5,
                            backgroundColor: AppColors.primary),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _iconBg(NotifType type, bool isRead) {
    if (isRead) return AppColors.surface;
    switch (type) {
      case NotifType.order: return AppColors.primary;
      case NotifType.offer: return const Color(0xFFFFF9C4);
      case NotifType.alert: return AppColors.greenSoft;
      case NotifType.general: return AppColors.surface;
    }
  }

  String _emoji(NotifType type) {
    switch (type) {
      case NotifType.order: return '📦';
      case NotifType.offer: return '🏷️';
      case NotifType.alert: return '✅';
      case NotifType.general: return '🔔';
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }
}
