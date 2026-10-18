import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'folder_detail_screen.dart';
import 'lesson_detail_screen.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

/// Smart school organizer: subject folders, lesson capture, tasks, calendar.
class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.plannerTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: S.tabFolders, icon: Icon(Icons.folder_outlined)),
            Tab(text: S.tabTasks, icon: Icon(Icons.checklist_rounded)),
            Tab(text: S.tabCalendar, icon: Icon(Icons.calendar_month_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _FoldersView(),
          _TasksView(),
          _CalendarView(),
        ],
      ),
    );
  }
}

// ── Subjects / folders ───────────────────────────────────

class _FoldersView extends StatefulWidget {
  const _FoldersView();

  @override
  State<_FoldersView> createState() => _FoldersViewState();
}

class _FoldersViewState extends State<_FoldersView> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final folders = store.myFolders;
    final searching = _query.trim().isNotEmpty;
    return Scaffold(
      floatingActionButton: searching
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _folderDialog(context, null),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text(S.newFolder),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: S.searchLessons,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searching
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() {
                          _query = '';
                          _search.clear();
                        }),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: searching
                ? LessonSearchResults(query: _query)
                : folders.isEmpty
                    ? EmptyState(
                        icon: Icons.folder_outlined,
                        title: S.noFolders,
                        subtitle: S.noFoldersHint,
                        actionLabel: S.newFolder,
                        onAction: () => _folderDialog(context, null),
                      )
                    : ReorderableListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(12, 4, 12, 80),
                        itemCount: folders.length,
                        onReorderItem: (o, n) =>
                            store.moveFolder(o, n),
                        itemBuilder: (context, i) =>
                            _FolderTile(
                          key: ValueKey(folders[i].id),
                          folder: folders[i],
                          onEdit: () =>
                              _folderDialog(context, folders[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _folderDialog(
      BuildContext context, SubjectFolder? folder) async {
    final store = context.read<AppStore>();
    final result = await showDialog<_FolderForm>(
      context: context,
      builder: (ctx) => _FolderFormDialog(initial: folder),
    );
    if (result == null || !context.mounted) return;
    try {
      if (folder == null) {
        await store.addFolder(
            name: result.name,
            colorValue: result.color,
            icon: result.icon);
      } else {
        await store.renameFolder(folder.id,
            name: result.name,
            colorValue: result.color,
            icon: result.icon);
      }
    } on StoreException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }
}

/// Result of the folder create/rename dialog.
class _FolderForm {
  _FolderForm(
      {required this.name, required this.color, required this.icon});
  final String name;
  final int color;
  final String icon;
}

/// Dialog that owns its TextEditingController — the controller's lifecycle is
/// tied to the dialog route, so it can never be used after disposal while the
/// route animates out.
class _FolderFormDialog extends StatefulWidget {
  const _FolderFormDialog({this.initial});

  final SubjectFolder? initial;

  @override
  State<_FolderFormDialog> createState() =>
      _FolderFormDialogState();
}

class _FolderFormDialogState
    extends State<_FolderFormDialog> {
  late final TextEditingController _name;
  late int _color;
  late String _icon;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
        text: widget.initial?.name ?? '');
    _color =
        widget.initial?.colorValue ?? C.folderColors.first;
    _icon = widget.initial?.icon ?? C.folderIcons.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? S.renameFolder : S.newFolder),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              textCapitalization:
                  TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: S.folderName,
                hintText: S.folderNameHint,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(S.folderColor,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: C.folderColors
                  .map(
                    (c) => InkWell(
                      onTap: () =>
                          setState(() => _color = c),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: _color == c
                              ? Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  width: 3)
                              : null,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(S.folderIcon,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: C.folderIcons
                  .map(
                    (k) => InkWell(
                      onTap: () =>
                          setState(() => _icon = k),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _icon == k
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(folderIconFor(k)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(S.cancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              showSnack(context, S.folderNameHint);
              return;
            }
            Navigator.of(context).pop(_FolderForm(
                name: name,
                color: _color,
                icon: _icon));
          },
          child: const Text(S.save),
        ),
      ],
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile(
      {super.key, required this.folder, required this.onEdit});

  final SubjectFolder folder;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final count = store.lessonsIn(folder.id).length;
    final scheme = Theme.of(context).colorScheme;
    final color = Color(folder.colorValue);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) =>
                  FolderDetailScreen(folderId: folder.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(folderIconFor(folder.icon),
                    color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '$count ${S.lessonCount}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color:
                                  scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (v) async {
                  if (v == 'edit') {
                    onEdit();
                  } else if (v == 'delete') {
                    final ok = await confirmDialog(
                      context,
                      title: S.deleteFolder,
                      body: S.deleteFolderConfirm,
                    );
                    if (ok) {
                      await store
                          .deleteFolder(folder.id);
                    }
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                      value: 'edit',
                      child: Text(S.renameFolder)),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text(S.deleteFolder)),
                ],
              ),
              const Icon(Icons.drag_handle_rounded,
                  color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class LessonSearchResults extends StatelessWidget {
  const LessonSearchResults({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final results = store.searchLessons(query);
    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: S.noLessonResults,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: results.length,
      itemBuilder: (context, i) =>
          LessonRow(lesson: results[i]),
    );
  }
}

// ── Tasks ────────────────────────────────────────────────

class _TasksView extends StatefulWidget {
  const _TasksView();

  @override
  State<_TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<_TasksView> {
  String _segment = 'todo';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final isDone = _segment == 'done';
    final tasks = isDone ? store.doneTasks() : store.openTasks();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const TaskFormScreen()),
        ),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text(S.newTask),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'todo',
                  icon: Icon(Icons.checklist_rounded, size: 18),
                  label: Text(S.statusTodo),
                ),
                ButtonSegment(
                  value: 'done',
                  icon:
                      Icon(Icons.emoji_events_outlined, size: 18),
                  label: Text(S.doneFolder),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (s) =>
                  setState(() => _segment = s.first),
            ),
          ),
          if (isDone)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(S.doneFolderSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: tasks.isEmpty
                ? EmptyState(
                    icon: Icons.checklist_rounded,
                    title: S.noTasks,
                    subtitle: S.noTasksHint,
                    actionLabel: S.newTask,
                    onAction: () =>
                        Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              const TaskFormScreen()),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) => isDone
                        ? _DoneTaskTile(task: tasks[i])
                        : TaskTile(task: tasks[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Done-folder row: title, type, completed date, grade badge if logged.
/// The performance record lives here.
class _DoneTaskTile extends StatelessWidget {
  const _DoneTaskTile({required this.task});

  final StudyTask task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) =>
                  TaskDetailScreen(taskId: task.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check_rounded,
                    color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniChip(
                            icon: Icons.category_outlined,
                            label: task.typeLabel.isEmpty
                                ? S.notSet
                                : task.typeLabel),
                        if (task.completedAt != null)
                          _MiniChip(
                              icon:
                                  Icons.event_available_outlined,
                              label: fmtDate(task.completedAt!)),
                      ],
                    ),
                  ],
                ),
              ),
              if (task.gradeScore.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grade_rounded,
                          size: 15,
                          color: scheme.onTertiaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        task.gradeScore,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});

  final StudyTask task;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final scheme = Theme.of(context).colorScheme;
    final folder =
        task.folderId == null ? null : store.folderById(task.folderId!);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) =>
                  TaskDetailScreen(taskId: task.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 10),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.isDone,
                onChanged: (v) => store.setTaskStatus(
                    task.id, v == true ? 'done' : 'todo'),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isDone
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (folder != null)
                          _MiniChip(
                              icon: folderIconFor(
                                  folder.icon),
                              label: folder.name),
                        if (task.dueAtLocal != null)
                          _MiniChip(
                            icon: Icons.schedule_outlined,
                            label: _dueLabel(task),
                            highlight: task.isOverdue,
                          ),
                        if (task.priority == 'high' &&
                            !task.isDone)
                          _MiniChip(
                            icon:
                                Icons.priority_high_rounded,
                            label: S.priorityHigh,
                            highlight: true,
                          ),
                        _MiniChip(
                          icon: Icons.flag_outlined,
                          label: _statusLabel(task.status),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dueLabel(StudyTask task) {
    final d = task.dueAtLocal!;
    final now = DateTime.now();
    final today =
        DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (task.isOverdue) return '${S.overdue} · ${fmtDate(d)}';
    if (diff == 0) return '${S.dueToday} · ${fmtTime(d)}';
    if (diff == 1) return '${S.dueTomorrow} · ${fmtTime(d)}';
    return fmtDateTime(d);
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'doing':
        return S.statusDoing;
      case 'done':
        return S.statusDone;
      case 'todo':
      default:
        return S.statusTodo;
    }
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip(
      {required this.icon,
      required this.label,
      this.highlight = false});

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.errorContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: highlight
                  ? scheme.onErrorContainer
                  : scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: highlight
                  ? scheme.onErrorContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calendar ─────────────────────────────────────────────

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  late DateTime _month;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(_month.year, _month.month, 1);
    // Monday-first grid.
    final leading = (first.weekday - 1) % 7;
    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    final tasksByDay = <int, int>{};
    for (final t in store.myTasks) {
      final d = t.dueAtLocal;
      if (d != null &&
          d.year == _month.year &&
          d.month == _month.month &&
          !t.isDone) {
        tasksByDay[d.day] = (tasksByDay[d.day] ?? 0) + 1;
      }
    }
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _month =
                    DateTime(_month.year, _month.month - 1)),
              ),
              Expanded(
                child: Text(
                  '${_month.year}-${two(_month.month)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() => _month =
                    DateTime(_month.year, _month.month + 1)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 7 + leading + daysInMonth,
            itemBuilder: (context, i) {
              if (i < 7) {
                return Center(
                  child: Text(
                    weekdays[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              final day = i - 7 - leading + 1;
              if (day < 1 || day > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date =
                  DateTime(_month.year, _month.month, day);
              final isSelected = _selected != null &&
                  _selected!.year == date.year &&
                  _selected!.month == date.month &&
                  _selected!.day == date.day;
              final isToday = date.year ==
                      DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final count = tasksByDay[day] ?? 0;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    setState(() => _selected = date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary
                        : isToday
                            ? scheme.primaryContainer
                            : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.onSurface,
                        ),
                      ),
                      if (count > 0)
                        Container(
                          margin:
                              const EdgeInsets.only(top: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 24),
        Expanded(
          child: _selected == null
              ? const SizedBox.shrink()
              : Builder(
                  builder: (context) {
                    final dayTasks =
                        store.tasksForDay(_selected!);
                    if (dayTasks.isEmpty) {
                      return EmptyState(
                        icon:
                            Icons.event_available_outlined,
                        title: S.noTasks,
                        actionLabel: S.newTask,
                        onAction: () =>
                            Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const TaskFormScreen()),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          12, 0, 12, 16),
                      itemCount: dayTasks.length,
                      itemBuilder: (context, i) =>
                          TaskTile(task: dayTasks[i]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Lesson row shared by folder detail + search results.
class LessonRow extends StatelessWidget {
  const LessonRow({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final folder = store.folderById(lesson.folderId);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) =>
                  LessonDetailScreen(lessonId: lesson.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  // ignore: avoid_unnecessary_containers
                  File(lesson.photoPath),
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  cacheWidth: 160,
                  errorBuilder: (_, _, _) =>
                      Container(
                    width: 64,
                    height: 64,
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(
                        Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fmtDate(lesson.lessonDate)}${folder != null ? ' · ${folder.name}' : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color:
                                  scheme.onSurfaceVariant),
                    ),
                    if (lesson.tags.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 4),
                        child: TagChips(tags: lesson.tags),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
