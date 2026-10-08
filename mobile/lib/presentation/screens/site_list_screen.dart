import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/sync_status.dart';
import '../bloc/customer/customer_bloc.dart';
import '../bloc/customer/customer_event.dart';
import '../bloc/customer/customer_state.dart';
import '../bloc/site/site_bloc.dart';
import '../bloc/site/site_event.dart';
import '../bloc/site/site_state.dart';
import '../widgets/empty_state.dart';
import 'site_details_screen.dart';

class SiteListScreen extends StatefulWidget {
  const SiteListScreen({super.key});

  @override
  State<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SiteBloc>().add(const LoadSites());
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  void _showAddSiteDialog() {
    final customerState = context.read<CustomerBloc>().state;
    if (customerState is! CustomerLoaded || customerState.customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please create at least one customer before adding a site.',
          ),
        ),
      );
      return;
    }

    String selectedCustomerId = customerState.customers.first.id;
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Site'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCustomerId,
                      decoration: const InputDecoration(
                        labelText: 'Customer *',
                      ),
                      items: customerState.customers.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCustomerId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Site Name *',
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter site name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      context.read<SiteBloc>().add(
                        CreateSiteEvent(
                          customerId: selectedCustomerId,
                          siteName: nameController.text.trim(),
                          address: addressController.text.trim(),
                        ),
                      );
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sites')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        onPressed: _showAddSiteDialog,
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<SiteBloc, SiteState>(
        builder: (context, state) {
          if (state is SiteLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SiteError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is SiteLoaded) {
            if (state.sites.isEmpty) {
              return EmptyState(
                icon: Icons.location_city_outlined,
                title: 'No Sites Found',
                message: 'Add sites under your customers to organize field inspection notes.',
                actionLabel: 'Add Site',
                onAction: _showAddSiteDialog,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: state.sites.length,
              itemBuilder: (context, index) {
                final site = state.sites[index];
                final isPending = site.syncStatus != SyncStatus.synced;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFCCFBF1),
                      child: Icon(
                        Icons.location_city,
                        color: AppTheme.secondaryColor,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            site.siteName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (isPending)
                          Tooltip(
                            message: 'Offline changes pending sync',
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 16,
                              color: Colors.amber.shade800,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer: ${site.customerName ?? "Unknown"}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (site.address?.isNotEmpty == true)
                          Text(
                            site.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textSecondary,
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SiteDetailsScreen(site: site),
                        ),
                      );
                      if (context.mounted) {
                        context.read<SiteBloc>().add(const LoadSites());
                      }
                    },
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
