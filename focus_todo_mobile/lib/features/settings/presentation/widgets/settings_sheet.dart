import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../localization/app_strings.dart';
import '../../../../shared/models/task_sync_metadata.dart';
import '../../../tasks/presentation/providers/tasks_providers.dart';
import '../providers/app_preferences_provider.dart';
import '../state/app_preferences_state.dart';

class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  String? _syncMessage;
  bool _syncFailed = false;
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = ref.watch(appPreferencesProvider);
    final tasksState = ref.watch(tasksProvider);
    final notifier = ref.read(appPreferencesProvider.notifier);
    final tasksNotifier = ref.read(tasksProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final syncConfigured = tasksNotifier.isManualSyncConfigured();
    final pendingSyncCount = _pendingSyncCount(tasksState.syncMetadata);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                strings.settings,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                '${strings.theme} / ${strings.language}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              _CardSection(
                child: _Section(
                  title: 'Senkronizasyon',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        syncConfigured
                            ? strings.manualSyncHelp
                            : strings.syncUnavailable,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (pendingSyncCount > 0) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          '$pendingSyncCount pending local change${pendingSyncCount == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                      if (_syncMessage != null) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          _syncMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _syncFailed
                                    ? colors.error
                                    : colors.primary,
                              ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _isSyncing || !syncConfigured
                            ? null
                            : () => _runManualSync(context),
                        icon: Icon(_isSyncing ? Icons.sync : Icons.sync_outlined),
                        label: Text(
                          _isSyncing ? strings.syncing : 'Şimdi senkronize et',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _CardSection(
                child: _Section(
                  title: strings.theme,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppThemePreference.values
                        .map(
                          (AppThemePreference preference) => ChoiceChip(
                            label: Text(strings.themeLabel(preference)),
                            selected: state.themePreference == preference,
                            onSelected: (_) =>
                                notifier.setThemePreference(preference),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _CardSection(
                child: _Section(
                  title: strings.language,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppLanguage.values
                        .map(
                          (AppLanguage language) => ChoiceChip(
                            label: Text(strings.languageLabel(language)),
                            selected: state.language == language,
                            onSelected: (_) => notifier.setLanguage(language),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _pendingSyncCount(List<TaskSyncMetadata> syncMetadata) {
    return syncMetadata
        .where(
          (TaskSyncMetadata item) =>
              item.syncStatus == TaskSyncStatus.pendingUpsert ||
              item.syncStatus == TaskSyncStatus.pendingDelete,
        )
        .length;
  }

  Future<void> _runManualSync(BuildContext context) async {
    setState(() {
      _isSyncing = true;
      _syncFailed = false;
      _syncMessage = null;
    });

    final result = await ref.read(tasksProvider.notifier).runManualSync();
    if (!mounted) {
      return;
    }

    final strings = AppStrings.of(context);
    final message = result.summary.success
        ? strings.syncSucceeded
        : '${strings.syncFailed}: ${result.summary.errorMessage ?? ''}';

    setState(() {
      _isSyncing = false;
      _syncFailed = !result.summary.success;
      _syncMessage = message;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
