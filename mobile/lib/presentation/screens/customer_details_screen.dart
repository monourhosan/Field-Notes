import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/customer.dart';
import '../bloc/customer/customer_bloc.dart';
import '../bloc/customer/customer_event.dart';
import '../bloc/site/site_bloc.dart';
import '../bloc/site/site_event.dart';
import '../bloc/site/site_state.dart';
import 'site_details_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    context.read<SiteBloc>().add(LoadSites(customerId: _customer.id));
  }

  void _editCustomer() {
    final nameController = TextEditingController(text: _customer.name);
    final contactController = TextEditingController(
      text: _customer.contactInformation ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Customer'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Please enter name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Information',
                  ),
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
                  final newName = nameController.text.trim();
                  final newContact = contactController.text.trim();
                  context.read<CustomerBloc>().add(
                    UpdateCustomerEvent(
                      id: _customer.id,
                      name: newName,
                      contactInformation: newContact,
                    ),
                  );
                  setState(() {
                    _customer = _customer.copyWith(
                      name: newName,
                      contactInformation: newContact,
                    );
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete "${_customer.name}" and all its sites?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () {
              context.read<CustomerBloc>().add(
                DeleteCustomerEvent(_customer.id),
              );
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addSiteDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Site'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Site Name *'),
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
                      customerId: _customer.id,
                      siteName: nameController.text.trim(),
                      address: addressController.text.trim(),
                    ),
                  );
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Create Site'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(_customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editCustomer,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customer.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.contact_mail_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _customer.contactInformation?.isNotEmpty == true
                                ? _customer.contactInformation!
                                : 'No contact information provided',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Created: ${dateFormat.format(_customer.createdAt.toLocal())}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sites Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sites under Customer',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSiteDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Site'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sites list
            BlocBuilder<SiteBloc, SiteState>(
              builder: (context, state) {
                if (state is SiteLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (state is SiteLoaded) {
                  final visible = state.sites
                      .where((site) => site.customerId == _customer.id)
                      .toList();
                  if (visible.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'No sites created for this customer yet.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: visible.map((site) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFCCFBF1),
                            child: Icon(
                              Icons.location_city,
                              color: AppTheme.secondaryColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            site.siteName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            site.address?.isNotEmpty == true
                                ? site.address!
                                : 'No address provided',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
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
                              context.read<SiteBloc>().add(
                                LoadSites(customerId: _customer.id),
                              );
                            }
                          },
                        ),
                      );
                    }).toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
