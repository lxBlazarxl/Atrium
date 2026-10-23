import 'package:core_models/core_models.dart';
import 'package:core_router/core_router.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen displaying a searchable and categorized grid of all supported services.
///
/// Tapping a service directs the user to the instance configuration form
/// pre-populated for that service.
class ServiceGridScreen extends StatefulWidget {
  const ServiceGridScreen({super.key});

  @override
  State<ServiceGridScreen> createState() => _ServiceGridScreenState();
}

class _ServiceGridScreenState extends State<ServiceGridScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ServiceRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  List<ServiceKind> _filteredServices() {
    return ServiceKind.sortedValues.where((ServiceKind kind) {
      if (_selectedRole != null && kind.role != _selectedRole) {
        return false;
      }
      if (_searchQuery.isEmpty) {
        return true;
      }
      final String name = kind.displayName.toLowerCase();
      final String tagline = kind.tagline.toLowerCase();
      final String role = ServiceVisuals.roleLabel(kind.role).toLowerCase();
      final String key = kind.name.toLowerCase();
      return name.contains(_searchQuery) ||
          tagline.contains(_searchQuery) ||
          role.contains(_searchQuery) ||
          key.contains(_searchQuery);
    }).toList(growable: false);
  }

  Future<void> _selectService(BuildContext context, ServiceKind kind) async {
    final Object? result = await context.pushNamed(
      AtriumRoutes.addInstanceFormName,
      pathParameters: <String, String>{'kind': kind.name},
    );
    if (result == true && context.mounted && context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final List<ServiceKind> services = _filteredServices();
    final double width = MediaQuery.sizeOf(context).width;
    final int crossAxisCount = width > 900
        ? 4
        : width > 600
            ? 3
            : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add service'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              Insets.xs,
            ),
            child: SearchBar(
              key: const Key('service_search_bar'),
              controller: _searchController,
              hintText: 'Search services...',
              leading: const Icon(Icons.search),
              trailing: <Widget>[
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged();
                    },
                  ),
              ],
              elevation: const WidgetStatePropertyAll<double>(0),
              backgroundColor: WidgetStatePropertyAll<Color>(
                cs.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.lg,
              vertical: Insets.xs,
            ),
            child: Row(
              children: <Widget>[
                FilterChip(
                  key: const Key('category_chip_all'),
                  label: const Text('All'),
                  selected: _selectedRole == null,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() => _selectedRole = null);
                    }
                  },
                ),
                for (final ServiceRole role in ServiceRole.values) ...<Widget>[
                  const SizedBox(width: Insets.sm),
                  FilterChip(
                    key: Key('category_chip_${role.name}'),
                    label: Text(ServiceVisuals.roleLabel(role)),
                    selected: _selectedRole == role,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedRole = selected ? role : null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: services.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Insets.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: Insets.md),
                          Text(
                            'No services found',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: Insets.xs),
                          Text(
                            'Try a different search query or filter category.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Insets.md),
                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedRole = null;
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(Insets.lg),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: Insets.md,
                      mainAxisSpacing: Insets.md,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: services.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ServiceKind kind = services[index];
                      return _ServiceGridCard(
                        kind: kind,
                        onTap: () => _selectService(context, kind),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ServiceGridCard extends StatelessWidget {
  const _ServiceGridCard({
    required this.kind,
    required this.onTap,
  });

  final ServiceKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color accent = ServiceVisuals.accent(kind);

    return Semantics(
      button: true,
      label: 'Add ${kind.displayName}',
      child: Card(
        key: ValueKey<String>('service_card_${kind.name}'),
        elevation: 0,
        color: cs.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Insets.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(Insets.xs),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Center(
                        child: ServiceIcon(kind: kind, size: 28),
                      ),
                    ),
                    const Spacer(),
                    if (kind.isBeta) const BetaBadge(),
                  ],
                ),
                const Spacer(),
                Text(
                  kind.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Insets.xxs),
                Text(
                  kind.tagline,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Insets.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ServiceVisuals.roleLabel(kind.role),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
