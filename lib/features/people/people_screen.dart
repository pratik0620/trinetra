import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/connection_request_model.dart';
import '../../providers/app_providers.dart';
import '../../providers/mock_state_provider.dart';
import '../../shared/widgets/add_connection_bottom_sheet.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  void _openAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AddConnectionBottomSheet(
          onAdd: (name, rel) {
            ref.read(mockStateProvider.notifier).addConnection(name, rel);
          },
        );
      },
    );
  }

  void _acceptRequest(BuildContext context, WidgetRef ref, ConnectionRequestModel request) async {
    final connRepo = ref.read(connectionRepositoryProvider);
    try {
      await connRepo.acceptRequest(request);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.tertiaryContainer,
            content: Text(
              'Accepted connection request from ${request.senderName}!',
              style: const TextStyle(color: AppColors.onTertiaryContainer),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorContainer,
            content: Text('Failed to accept request: $e'),
          ),
        );
      }
    }
  }

  void _rejectRequest(BuildContext context, WidgetRef ref, String requestId) async {
    final connRepo = ref.read(connectionRepositoryProvider);
    try {
      await connRepo.rejectRequest(requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surfaceContainerHigh,
            content: Text('Request rejected'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorContainer,
            content: Text('Failed to reject request: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mockStateProvider);
    final incomingRequestsAsync = ref.watch(incomingConnectionRequestsProvider);
    final firestoreConnectionsAsync = ref.watch(userFirestoreConnectionsProvider);

    final incomingRequests = incomingRequestsAsync.value ?? [];
    final firestoreConnections = firestoreConnectionsAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ref),
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add RAKSHA Connection',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My RAKSHA Network',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your trusted contacts and view safety statuses.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // REAL-TIME INCOMING REQUESTS SECTION
              if (incomingRequests.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.mark_email_unread_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'INCOMING REQUESTS (${incomingRequests.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...incomingRequests.map((request) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryContainer),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryContainer,
                              child: Text(
                                request.senderName.isNotEmpty
                                    ? request.senderName[0].toUpperCase()
                                    : 'R',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.senderName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    request.senderPhone,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _acceptRequest(context, ref, request),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Accept',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _rejectRequest(context, ref, request.id),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.onSurfaceVariant,
                                  side: const BorderSide(color: AppColors.outline),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // Section 1: People I Protect
              const Text(
                'PEOPLE I PROTECT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),

              // Render Firestore Connections first if present
              if (firestoreConnections.isNotEmpty) ...[
                ...firestoreConnections.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                        left: BorderSide(
                          color: AppColors.tertiary,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            item.displayName.isNotEmpty
                                ? item.displayName[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: AppColors.tertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Connected (${item.phoneNumber})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                // Fallback Mock Network
                ...state.peopleIProtect.map((contact) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: contact.sosActive
                          ? AppColors.errorContainer.withOpacity(0.2)
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        left: BorderSide(
                          color: contact.sosActive
                              ? AppColors.emergency
                              : AppColors.tertiary,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(contact.avatarUrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    contact.sosActive
                                        ? Icons.warning_rounded
                                        : Icons.check_circle_rounded,
                                    size: 14,
                                    color: contact.sosActive
                                        ? AppColors.emergency
                                        : AppColors.tertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    contact.sosActive
                                        ? 'SOS Active'
                                        : 'Safe (Updated 2 min ago)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: contact.sosActive
                                          ? AppColors.emergency
                                          : AppColors.onSurfaceVariant,
                                      fontWeight: contact.sosActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 24),

              // Section 2: People Who Protect Me
              const Text(
                'PEOPLE WHO PROTECT ME',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),

              if (firestoreConnections.isNotEmpty) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: firestoreConnections.length,
                  itemBuilder: (context, index) {
                    final item = firestoreConnections[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryContainer,
                            child: Text(
                              item.displayName.isNotEmpty
                                  ? item.displayName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Guardian',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: state.peopleWhoProtectMe.length,
                  itemBuilder: (context, index) {
                    final contact = state.peopleWhoProtectMe[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(contact.avatarUrl),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            contact.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            contact.relationship,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
