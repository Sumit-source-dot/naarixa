import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/owner_properties_header.dart';
import '../providers/accommodation_provider.dart';
import '../widgets/accommodation_card.dart';
import 'add_property_screen.dart';
import 'owner_property_detail_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../shared/providers/trust_score_provider.dart';
import '../../../../shared/widgets/verification_status_banner.dart';

class AccommodationScreen extends ConsumerWidget {
  const AccommodationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final statsAsync = ref.watch(ownerPropertiesStatsProvider);
    final contactVerification = ref.watch(contactVerificationProvider);
    final showLowTrust = contactVerification.bothUnverified;

    return Scaffold(
      body: propertiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading properties: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(ownerPropertiesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (properties) {
          return statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    OwnerPropertiesHeader(
                      totalProperties: properties.length,
                      verifiedProperties: properties
                          .where((p) => p.verificationStatus == 1)
                          .length,
                      availableProperties: properties
                          .where((p) => p.isActive)
                          .length,
                      onAddPressed: () async {
                        final created = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const AddPropertyScreen(),
                          ),
                        );
                        if (created == true) {
                          ref.invalidate(ownerPropertiesProvider);
                          ref.invalidate(ownerPropertiesStatsProvider);
                        }
                      },
                    ),
                    if (properties.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_work_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Properties Yet',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Post your first property to get started\nand start earning today!',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AddPropertyScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Post Your Property'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 20,
                                childAspectRatio: 0.6,
                              ),
                          itemCount: properties.length,
                          itemBuilder: (context, index) {
                            final property = properties[index];
                            return AccommodationCard(
                              property: property,
                              showLowTrust: showLowTrust,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => OwnerPropertyDetailScreen(
                                      property: property,
                                    ),
                                  ),
                                );
                              },
                              onVerify: () => _showPropertyVerificationDialog(
                                context,
                                ref,
                                property,
                              ),
                              onEdit: () async {
                                final updated = await Navigator.of(context)
                                    .push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => AddPropertyScreen(
                                          propertyToEdit: property,
                                        ),
                                      ),
                                    );
                                if (updated == true) {
                                  ref.invalidate(ownerPropertiesProvider);
                                  ref.invalidate(ownerPropertiesStatsProvider);
                                }
                              },
                              onDelete: () {
                                // Show confirmation dialog
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete Property'),
                                    content: const Text(
                                      'Are you sure you want to delete this property?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(dialogContext);
                                          // Show loading indicator
                                          if (!context.mounted) return;
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (loadingContext) =>
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                          );

                                          // Delete from backend
                                          final result = await ref.read(
                                            deletePropertyProvider(
                                              property.id,
                                            ).future,
                                          );

                                          if (!context.mounted) return;
                                          Navigator.pop(
                                            context,
                                          ); // Close loading dialog

                                          if (result) {
                                            ref.invalidate(
                                              ownerPropertiesProvider,
                                            );
                                            ref.invalidate(
                                              ownerPropertiesStatsProvider,
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Property deleted successfully!',
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Failed to delete property',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            data: (stats) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OwnerPropertiesHeader(
                  totalProperties: stats['total'] ?? 0,
                  verifiedProperties: stats['verified'] ?? 0,
                  availableProperties: stats['available'] ?? 0,
                  onAddPressed: () async {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const AddPropertyScreen(),
                      ),
                    );
                    if (created == true) {
                      ref.invalidate(ownerPropertiesProvider);
                      ref.invalidate(ownerPropertiesStatsProvider);
                    }
                  },
                ),
                ref
                    .watch(trustScoreProvider)
                    .when(
                      loading: () => const SizedBox.shrink(),
                      error: (err, _) => const SizedBox.shrink(),
                      data: (trust) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: VerificationStatusBanner(
                          trust: trust,
                          onVerifyPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ProfileScreen(initialTab: 0),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                if (properties.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.home_work_outlined,
                              size: 80,
                              color: Colors.purple.shade400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Properties Yet',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Post your first property to get started\nand start earning today!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddPropertyScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Post Your First Property'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final property = properties[index];
                      return AccommodationCard(
                        property: property,
                        showLowTrust: showLowTrust,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  OwnerPropertyDetailScreen(property: property),
                            ),
                          );
                        },
                        onEdit: () async {
                          final updated = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => AddPropertyScreen(
                                    propertyToEdit: property,
                                  ),
                                ),
                              );
                          if (updated == true) {
                            ref.invalidate(ownerPropertiesProvider);
                            ref.invalidate(ownerPropertiesStatsProvider);
                          }
                        },
                        onVerify: () => _showPropertyVerificationDialog(
                          context,
                          ref,
                          property,
                        ),
                        onDelete: () {
                          // Show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Property'),
                              content: const Text(
                                'Are you sure you want to delete this property?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(dialogContext);
                                    if (!context.mounted) return;

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (loadingContext) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );

                                    final result = await ref.read(
                                      deletePropertyProvider(
                                        property.id,
                                      ).future,
                                    );

                                    if (!context.mounted) return;
                                    Navigator.pop(context);

                                    if (result) {
                                      ref.invalidate(ownerPropertiesProvider);
                                      ref.invalidate(
                                        ownerPropertiesStatsProvider,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Property deleted successfully!',
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to delete property',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPropertyVerificationDialog(
    BuildContext context,
    WidgetRef ref,
    OwnerProperty property,
  ) async {
    final ownershipController = TextEditingController();
    final utilityController = TextEditingController();
    final otherDocumentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Property Verification Form'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: ownershipController,
                      decoration: const InputDecoration(
                        labelText: 'ownership_document_url',
                        hintText: 'https://.../ownership-doc.pdf',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: utilityController,
                      decoration: const InputDecoration(
                        labelText: 'utility_bill_url',
                        hintText: 'https://.../utility-bill.pdf',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: otherDocumentController,
                      decoration: const InputDecoration(
                        labelText: 'other_required_document_url',
                        hintText: 'https://.../property-tax-or-any-proof.pdf',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Status will be set to pending automatically. Admin will review and approve/reject.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final ownershipUrl = ownershipController.text.trim();
                    final utilityUrl = utilityController.text.trim();
                    final otherDocumentUrl = otherDocumentController.text
                        .trim();

                    if (ownershipUrl.isEmpty ||
                        utilityUrl.isEmpty ||
                        otherDocumentUrl.isEmpty) {
                      _showMessage(
                        context,
                        'Ownership, utility bill, and other required document URLs are required',
                      );
                      return;
                    }

                    final result = await ref.read(
                      submitPropertyVerificationProvider(
                        PropertyVerificationPayload(
                          propertyId: property.id,
                          ownershipDocumentUrl: ownershipUrl,
                          utilityBillUrl: utilityUrl,
                          otherRequiredDocumentUrl: otherDocumentUrl,
                        ),
                      ).future,
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);

                    if (result) {
                      _showMessage(
                        context,
                        'Verification form submitted successfully',
                      );
                    } else {
                      _showMessage(
                        context,
                        'Failed to submit verification form',
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
