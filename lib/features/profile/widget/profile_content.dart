import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/profile/cubit/profile_cubit.dart';
import 'package:vaulth_app/server/model/user/update_user_request/update_user_request.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto/user_profile_dto.dart';

import 'info_row.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({
    super.key,
    required this.profile,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
  });
  final UserProfileDto profile;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  void _showEditDialog(UserProfileDto profile) {
    widget.firstNameController.text = profile.firstName ?? '';
    widget.lastNameController.text = profile.lastName ?? '';
    widget.emailController.text = profile.email ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Редактировать профиль',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: widget.firstNameController,
                decoration: InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: widget.lastNameController,
                decoration: InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: widget.emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      final request = UpdateUserRequest(
                        firstName: widget.firstNameController.text.trim(),
                        lastName: widget.lastNameController.text.trim(),
                      );
                      context.read<ProfileCubit>().updateCurrentUser(request);
                      Navigator.pop(context);
                    },
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(UserProfileDto profile) {
    final first = profile.firstName?.isNotEmpty == true
        ? profile.firstName![0]
        : '';
    final last = profile.lastName?.isNotEmpty == true
        ? profile.lastName![0]
        : '';
    if (first.isEmpty && last.isEmpty) return 'U';
    return '$first$last'.toUpperCase();
  }

  String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double value = bytes.toDouble();
    while (value >= 1024 && i < suffixes.length - 1) {
      value /= 1024;
      i++;
    }
    return '${value.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    double usagePercent = 0.0;
    if (widget.profile.storageUsed != null &&
        widget.profile.storageLimit != null &&
        widget.profile.storageUsed! > 0) {
      usagePercent = widget.profile.storageUsed! / widget.profile.storageLimit!;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: kToolbarHeight + 24,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    _getInitials(widget.profile),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 4,
              shadowColor: Theme.of(context).colorScheme.shadow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(label: 'Имя', value: widget.profile.firstName),
                    const Divider(height: 24),
                    InfoRow(label: 'Фамилия', value: widget.profile.lastName),
                    const Divider(height: 24),
                    InfoRow(
                      label: 'Имя пользователя',
                      value: widget.profile.username,
                    ),
                    const Divider(height: 24),
                    InfoRow(label: 'Email', value: widget.profile.email),
                    const Divider(height: 24),
                    InfoRow(
                      label: 'ID пользователя',
                      value: widget.profile.id.toString(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (widget.profile.storageUsed != null &&
                widget.profile.storageLimit != null)
              Card(
                elevation: 4,
                shadowColor: Theme.of(context).colorScheme.shadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Хранилище',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${(usagePercent * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: usagePercent > 0.9
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: usagePercent.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usagePercent > 0.9
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatBytes(widget.profile.storageUsed!),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _formatBytes(widget.profile.storageLimit!),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),
            Center(
              child: FilledButton.icon(
                onPressed: () => _showEditDialog(widget.profile),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Редактировать профиль'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(220, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
