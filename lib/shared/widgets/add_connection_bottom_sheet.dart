import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AddConnectionBottomSheet extends StatefulWidget {
  final Function(String name, String relationship) onAdd;

  const AddConnectionBottomSheet({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddConnectionBottomSheet> createState() =>
      _AddConnectionBottomSheetState();
}

class _AddConnectionBottomSheetState extends State<AddConnectionBottomSheet> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController(text: 'Riya Patel');
  String _selectedRelationship = 'Friend';
  bool _isEmergencyContact = true;
  bool _canReceiveSos = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    widget.onAdd(name, _selectedRelationship);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.tertiaryContainer,
        content: Text(
          'Connection request sent to $name!',
          style: const TextStyle(color: AppColors.onTertiaryContainer),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add RAKSHA Connection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.onSurfaceVariant),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Method choices
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Icon(Icons.dialpad_rounded,
                              color: AppColors.onPrimaryContainer),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Search by\nphone number',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Icon(Icons.qr_code_scanner_rounded,
                              color: AppColors.onPrimaryContainer),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Scan QR\ncode',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Name',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Enter contact name',
                hintStyle: const TextStyle(color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: AppColors.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Relationship',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['Friend', 'Family', 'Other'].map((rel) {
                final isSelected = _selectedRelationship == rel;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(rel),
                    selected: isSelected,
                    selectedColor: AppColors.primaryContainer,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedRelationship = rel);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isEmergencyContact,
              activeColor: AppColors.primary,
              checkColor: AppColors.onPrimary,
              title: const Text('Emergency Contact',
                  style: TextStyle(color: AppColors.onSurface, fontSize: 14)),
              subtitle: const Text(
                'Notify them immediately during an SOS',
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
              ),
              onChanged: (val) =>
                  setState(() => _isEmergencyContact = val ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _canReceiveSos,
              activeColor: AppColors.primary,
              checkColor: AppColors.onPrimary,
              title: const Text('I can receive their SOS',
                  style: TextStyle(color: AppColors.onSurface, fontSize: 14)),
              subtitle: const Text(
                'Allow them to add you as a guardian',
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
              ),
              onChanged: (val) =>
                  setState(() => _canReceiveSos = val ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  'Send Request',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
