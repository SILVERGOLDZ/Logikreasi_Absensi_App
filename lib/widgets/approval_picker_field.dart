import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/approver_model.dart';
import '../models/leave_model.dart';

class ApproverPickerField extends StatelessWidget {
  const ApproverPickerField({
    super.key,
    required this.approvers,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<ApproverModel> approvers;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _ApproverPickerSheet(approvers: approvers, initialSelected: selectedIds),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final selected = approvers.where((a) => selectedIds.contains(a.id)).toList();

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: 'Ajukan kepada',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: selected.isEmpty
            ? const Text('Pilih approver...', style: TextStyle(color: Colors.grey))
            : Wrap(
          spacing: 6,
          runSpacing: 6,
          children: selected.map((a) {
            final hasPhoto = a.photoUrl != null && a.photoUrl!.isNotEmpty;
            return Chip(
              avatar: CircleAvatar(
                backgroundImage: hasPhoto ? NetworkImage(AppConfig.photoUrl(a.photoUrl)) : null,
                child: hasPhoto ? null : Text(a.username[0].toUpperCase()),
              ),
              label: Text(a.username),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ApproverPickerSheet extends StatefulWidget {
  const _ApproverPickerSheet({required this.approvers, required this.initialSelected});

  final List<ApproverModel> approvers;
  final List<int> initialSelected;

  @override
  State<_ApproverPickerSheet> createState() => _ApproverPickerSheetState();
}

class _ApproverPickerSheetState extends State<_ApproverPickerSheet> {
  late List<int> _selected = List.of(widget.initialSelected);

  void _toggle(int id) {
    setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ajukan kepada siapa?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Tap foto/nama untuk memilih (bisa lebih dari satu)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: widget.approvers.isEmpty
                  ? const Padding(padding: EdgeInsets.all(24), child: Text('Belum ada approver tersedia'))
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.approvers.length,
                itemBuilder: (context, index) {
                  final a = widget.approvers[index];
                  final isSelected = _selected.contains(a.id);
                  final hasPhoto = a.photoUrl != null && a.photoUrl!.isNotEmpty;
                  return ListTile(
                    onTap: () => _toggle(a.id),
                    leading: CircleAvatar(
                      backgroundImage: hasPhoto ? NetworkImage(AppConfig.photoUrl(a.photoUrl)) : null,
                      child: hasPhoto ? null : Text(a.username[0].toUpperCase()),
                    ),
                    title: Text(a.username),
                    subtitle: Text(a.role),
                    trailing: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Colors.green : Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: Text('Pilih (${_selected.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}