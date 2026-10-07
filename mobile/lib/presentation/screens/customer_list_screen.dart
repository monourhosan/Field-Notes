import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/sync_status.dart';
import '../bloc/customer/customer_bloc.dart';
import '../bloc/customer/customer_event.dart';
import '../bloc/customer/customer_state.dart';
import '../widgets/empty_state.dart';
import 'customer_details_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  void _showCustomerDialog({String? id, String? currentName, String? currentContact}) {
    final nameController = TextEditingController(text: currentName ?? '');
    final contactController = TextEditingController(text: currentContact ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(id == null ? 'Add Customer' : 'Edit Customer'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Customer Name *'),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: 'Contact Information'),
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
                  if (id == null) {
                    context.read<CustomerBloc>().add(
                          CreateCustomerEvent(
                            name: nameController.text.trim(),
                            contactInformation: contactController.text.trim(),
                          ),
                        );
                  } else {
                    context.read<CustomerBloc>().add(
                          UpdateCustomerEvent(
                            id: id,
                            name: nameController.text.trim(),
                            contactInformation: contactController.text.trim(),
                          ),
                        );
                  }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _showCustomerDialog(),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomerError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is CustomerLoaded) {
            if (state.customers.isEmpty) {
              return EmptyState(
                icon: Icons.business_outlined,
                title: 'No Customers Found',
                message: 'Add your first customer to organize sites and inspection notes.',
                actionLabel: 'Add Customer',
                onAction: () => _showCustomerDialog(),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: state.customers.length,
              itemBuilder: (context, index) {
                final customer = state.customers[index];
                final isPending = customer.syncStatus != SyncStatus.synced;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (isPending)
                          Tooltip(
                            message: 'Offline changes pending sync',
                            child: Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.amber.shade800),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      customer.contactInformation?.isNotEmpty == true
                          ? customer.contactInformation!
                          : 'No contact information',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerDetailsScreen(customer: customer),
                        ),
                      );
                      if (context.mounted) {
                        context.read<CustomerBloc>().add(LoadCustomers());
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
