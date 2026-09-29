import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';
import '../../models/branch.dart';
import '../../services/firestore_service.dart';

class MemberTransferScreen extends ConsumerStatefulWidget {
  final AppUser member;

  const MemberTransferScreen({super.key, required this.member});

  @override
  ConsumerState<MemberTransferScreen> createState() => _MemberTransferScreenState();
}

class _MemberTransferScreenState extends ConsumerState<MemberTransferScreen> {
  String? _selectedTrainerId;
  String? _selectedBranchId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final trainersAsync = ref.watch(firestoreServiceProvider).getTrainers();
    final branchesAsync = ref.watch(branchesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer ${widget.member.displayName}'),
      ),
      body: FutureBuilder<List<AppUser>>(
        future: trainersAsync,
        builder: (context, trainerSnapshot) {
          return branchesAsync.when(
            data: (branches) {
              final trainers = trainerSnapshot.data ?? [];
              final activeBranches = branches.where((b) => b.isActive).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                widget.member.displayName.isNotEmpty
                                    ? widget.member.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.member.displayName,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      )),
                                  Text(widget.member.email,
                                      style: Theme.of(context).textTheme.bodyMedium),
                                  if (widget.member.trainerId != null)
                                    Text('Current Trainer: ${widget.member.trainerId}',
                                        style: Theme.of(context).textTheme.bodySmall),
                                  if (widget.member.branchId != null)
                                    Text('Current Branch: ${widget.member.branchId}',
                                        style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('New Trainer', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTrainerId,
                      decoration: const InputDecoration(
                        labelText: 'Select Trainer',
                        border: OutlineInputBorder(),
                      ),
                      items: trainers.map((trainer) {
                        return DropdownMenuItem(
                          value: trainer.uid,
                          child: Text('${trainer.displayName} (${trainer.email})'),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedTrainerId = value),
                    ),
                    const SizedBox(height: 24),
                    Text('New Branch', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Select Branch',
                        border: OutlineInputBorder(),
                      ),
                      items: activeBranches.map((branch) {
                        return DropdownMenuItem(
                          value: branch.id,
                          child: Text(branch.name),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedBranchId = value),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Transfer Notes (optional)',
                        hintText: 'Reason for transfer...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading || _selectedTrainerId == null || _selectedBranchId == null
                            ? null
                            : () => _transferMember(
                                context,
                                ref,
                                trainers,
                                activeBranches,
                              ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Transfer Member'),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
      ),
    );
  }

  Future<void> _transferMember(
    BuildContext context,
    WidgetRef ref,
    List<AppUser> trainers,
    List<Branch> branches,
  ) async {
    setState(() => _isLoading = true);

    try {
      final selectedTrainer = trainers.firstWhere((t) => t.uid == _selectedTrainerId);
      final selectedBranch = branches.firstWhere((b) => b.id == _selectedBranchId);
      final previousTrainerId = widget.member.trainerId ?? '';
      final previousBranchId = widget.member.branchId ?? '';

      await ref.read(firestoreServiceProvider).transferMember(
        memberId: widget.member.uid,
        memberName: widget.member.displayName,
        newTrainerId: selectedTrainer.uid,
        newTrainerName: selectedTrainer.displayName,
        newBranchId: selectedBranch.id,
        newBranchName: selectedBranch.name,
        previousTrainerId: previousTrainerId,
        previousBranchId: previousBranchId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member transferred successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}