import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'booking_detail_screen.dart';

/// "My sessions": the student's 1v1 bookings grouped into
/// Pending / Upcoming / Past.
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.myBookings),
          bottom: const TabBar(
            tabs: [
              Tab(text: S.pendingRequests),
              Tab(text: S.upcomingSessions),
              Tab(text: S.pastSessions),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GroupList(group: _Group.pending),
            _GroupList(group: _Group.upcoming),
            _GroupList(group: _Group.past),
          ],
        ),
      ),
    );
  }
}

enum _Group { pending, upcoming, past }

class _GroupList extends StatelessWidget {
  const _GroupList({required this.group});

  final _Group group;

  List<TutorBooking> _forGroup(List<TutorBooking> all) {
    final now = DateTime.now().toUtc();
    switch (group) {
      case _Group.pending:
        return all.where((b) => b.status == 'pending').toList();
      case _Group.upcoming:
        return all
            .where((b) =>
                b.status == 'accepted' &&
                (b.startsAtUtc == null ||
                    b.startsAtUtc!.isAfter(now)))
            .toList();
      case _Group.past:
        return all
            .where((b) =>
                b.status == 'declined' ||
                b.status == 'cancelled' ||
                b.status == 'completed' ||
                (b.status == 'accepted' &&
                    b.startsAtUtc != null &&
                    !b.startsAtUtc!.isAfter(now)))
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    final list = _forGroup(store.myBookings());
    if (list.isEmpty) {
      return EmptyState(
        icon: group == _Group.pending
            ? Icons.hourglass_empty_rounded
            : Icons.event_note_outlined,
        title: group == _Group.pending
            ? S.pendingRequests
            : group == _Group.upcoming
                ? S.upcomingSessions
                : S.pastSessions,
        subtitle: 'Nothing here yet.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final b = list[i];
        final local = b.startsAtUtc == null
            ? null
            : utcToViewer(b.startsAtUtc!, me);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                b.tutorName.isEmpty
                    ? '?'
                    : b.tutorName[0].toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w800),
              ),
            ),
            title: Text(b.tutorName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700)),
            subtitle: Text(local == null
                ? 'No time set'
                : '${fmtDateTime(local)} · ${b.durationMin} ${S.minutes}'),
            trailing: Text(
              b.status[0].toUpperCase() + b.status.substring(1),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    BookingDetailScreen(bookingId: b.id),
              ),
            ),
          ),
        );
      },
    );
  }
}
