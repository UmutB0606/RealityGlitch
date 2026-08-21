import 'package:flutter/material.dart';

import '../models/scan_history_entry.dart';
import '../services/scan_history_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glitch_text.dart';
import 'result_screen.dart';

/// Lists every scan that finished successfully, most recent first, so the
/// user can find their way back to a previously generated 3D model.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ScanHistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ScanHistoryService.getAll();
  }

  Future<void> _refresh() async {
    setState(() => _historyFuture = ScanHistoryService.getAll());
  }

  Future<void> _delete(ScanHistoryEntry entry) async {
    await ScanHistoryService.remove(entry.taskId);
    _refresh();
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.toxicGreen),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(child: GlitchText(text: 'TARAMA_GEÇMİŞİ', fontSize: 15)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.dimGreen),
            Expanded(
              child: FutureBuilder<List<ScanHistoryEntry>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.toxicGreen));
                  }

                  final entries = snapshot.data ?? const <ScanHistoryEntry>[];
                  if (entries.isEmpty) {
                    return const Center(
                      child: Text(
                        'HENÜZ TARAMA YOK.\nBİR ŞEY TARA VE BURADA GÖR.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.dimGreen, fontFamily: 'monospace', fontSize: 13, height: 1.6),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.toxicGreen,
                    backgroundColor: AppColors.nearBlack,
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _HistoryTile(
                        entry: entries[index],
                        dateLabel: _formatDate(entries[index].createdAt),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ResultScreen(asset: entries[index].toSceneAsset())),
                        ),
                        onDelete: () => _delete(entries[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.dateLabel, required this.onTap, required this.onDelete});

  final ScanHistoryEntry entry;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.dimGreen)),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: AppColors.toxicGreen.withValues(alpha: 0.5))),
              child: entry.thumbnailUrl != null
                  ? Image.network(
                      entry.thumbnailUrl!,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      errorBuilder: (_, _, _) => const Icon(Icons.view_in_ar, color: AppColors.toxicGreen, size: 22),
                    )
                  : const Icon(Icons.view_in_ar, color: AppColors.toxicGreen, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCAN_${entry.taskId.substring(0, entry.taskId.length < 8 ? entry.taskId.length : 8)}',
                    style: const TextStyle(color: AppColors.toxicGreen, fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: TextStyle(color: AppColors.toxicGreen.withValues(alpha: 0.6), fontFamily: 'monospace', fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.neonRed, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
