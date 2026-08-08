import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';

class AddConnectionBottomSheet extends ConsumerStatefulWidget {
  final Function(String name, String relationship) onAdd;

  const AddConnectionBottomSheet({
    super.key,
    required this.onAdd,
  });

  @override
  ConsumerState<AddConnectionBottomSheet> createState() =>
      _AddConnectionBottomSheetState();
}

class _AddConnectionBottomSheetState
    extends ConsumerState<AddConnectionBottomSheet> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRelationship = 'Friend';
  bool _isEmergencyContact = true;
  bool _canReceiveSos = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    final rawPhone = _phoneController.text.trim();

    if (rawPhone.isEmpty) {
      setState(() => _errorMessage = 'Please enter a phone number.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final connRepo = ref.read(connectionRepositoryProvider);
    final currentUserProfile = ref.read(currentUserProfileProvider).value;

    final normalizedPhone = authService.normalizePhoneNumber(rawPhone);

    try {
      // 1. Search Firestore users collection for User B
      final foundUser = await userRepo.searchUserByPhone(normalizedPhone);

      if (foundUser == null) {
        // User B does not exist -> Do NOT show "Request Sent"
        setState(() {
          _errorMessage = 'No RAKSHA user found with this phone number.';
          _isSubmitting = false;
        });
        return;
      }

      if (currentUserProfile == null) {
        setState(() {
          _errorMessage = 'User profile not found. Please log in again.';
          _isSubmitting = false;
        });
        return;
      }

      if (foundUser.uid == currentUserProfile.uid) {
        setState(() {
          _errorMessage = 'You cannot add yourself as a connection.';
          _isSubmitting = false;
        });
        return;
      }

      // 2. Create connection request in Firestore (checks duplicates inside repository)
      await connRepo.sendConnectionRequest(
        sender: currentUserProfile,
        receiver: foundUser,
      );

      // 3. Only AFTER Firestore write succeeds -> Show success notification
      widget.onAdd(foundUser.name, _selectedRelationship);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.tertiaryContainer,
            content: Text(
              'Request Sent to ${foundUser.name}!',
              style: const TextStyle(color: AppColors.onTertiaryContainer),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
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

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.emergency),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.emergency, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: AppColors.onErrorContainer, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'e.g. 8369775954 or +91 8369775954',
                hintStyle: const TextStyle(color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                prefixIcon: const Icon(Icons.phone_outlined,
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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
                style:
                    TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
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
                style:
                    TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
              ),
              onChanged: (val) => setState(() => _canReceiveSos = val ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Sending Request...' : 'Send Request',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
