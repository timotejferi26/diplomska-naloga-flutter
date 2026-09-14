// lib/libraries/watch_it/widgets/watchit_user_form_sheet.dart
//
// Plain StatefulWidget — no watch_it needed for local form state.
// onSubmit is passed in from the page so the sheet stays decoupled.

import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:flutter/material.dart';

class WatchItUserFormSheet extends StatefulWidget {
  final User? existing;
  final Future<String?> Function(String name, String email, List<String> tags)
  onSubmit;

  const WatchItUserFormSheet({
    super.key,
    this.existing,
    required this.onSubmit,
  });

  @override
  State<WatchItUserFormSheet> createState() => _WatchItUserFormSheetState();
}

class _WatchItUserFormSheetState extends State<WatchItUserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _tags;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _email = TextEditingController(text: widget.existing?.email ?? '');
    _tags = TextEditingController(text: widget.existing?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final tags = _tags.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await widget.onSubmit(
      _name.text.trim(),
      _email.text.trim(),
      tags,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              _isEdit ? 'Edit User' : 'Add User',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              key: const Key('field_name'),
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_email'),
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Email is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_tags'),
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
                hintText: 'flutter, dart, mobile',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : (_isEdit
                        ? const Text('Save Changes')
                        : const Text('Add User')),
            ),
          ],
        ),
      ),
    );
  }
}
