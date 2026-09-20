import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// MySpeed service home screen.
class MySpeedHome extends ConsumerWidget {
  const MySpeedHome({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: Insets.page,
        child: EmptyView(
          icon: ServiceVisuals.icon(instance.kind),
          title: 'MySpeed',
          message: 'MySpeed service integration ready.',
        ),
      ),
    );
  }
}
