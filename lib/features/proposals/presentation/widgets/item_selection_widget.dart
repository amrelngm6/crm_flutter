import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/proposals_provider.dart';
import '../../../../core/models/proposal.dart';
import '../../../../core/theme/app_colors.dart';

class ItemSelectionWidget extends StatefulWidget {
  final Function(AvailableItem) onItemSelected;
  final String? searchHint;

  const ItemSelectionWidget({
    super.key,
    required this.onItemSelected,
    this.searchHint = 'Search items...',
  });

  @override
  State<ItemSelectionWidget> createState() => _ItemSelectionWidgetState();
}

class _ItemSelectionWidgetState extends State<ItemSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProposalsProvider>();
      provider.loadAvailableItems(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final provider = context.read<ProposalsProvider>();
    provider.loadAvailableItems(
      search: query.isNotEmpty ? query : null,
      groupId: _selectedGroupId,
      refresh: true,
    );
  }

  void _onGroupFilterChanged(int? groupId) {
    setState(() {
      _selectedGroupId = groupId;
    });

    final provider = context.read<ProposalsProvider>();
    provider.loadAvailableItems(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      groupId: groupId,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProposalsProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildSearchAndFilter(provider),
            const SizedBox(height: 16),
            Expanded(
              child: _buildItemsList(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilter(ProposalsProvider provider) {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: widget.searchHint?.tr(),
            prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Group filter
        if (provider.itemGroups.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.itemGroups.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('All'.tr()),
                      selected: _selectedGroupId == null,
                      onSelected: (_) => _onGroupFilterChanged(null),
                      selectedColor:
                          AppColors.primaryGreen.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primaryGreen,
                    ),
                  );
                }

                final group = provider.itemGroups[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${group.name} (${group.itemsCount})'),
                    selected: _selectedGroupId == group.id,
                    onSelected: (_) => _onGroupFilterChanged(group.id),
                    selectedColor:
                        AppColors.primaryGreen.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primaryGreen,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildItemsList(ProposalsProvider provider) {
    if (provider.isLoadingItems) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadAvailableItems(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (provider.availableItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Items Available'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No items found matching your search criteria'.tr(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.availableItems.length,
      itemBuilder: (context, index) {
        final item = provider.availableItems[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(AvailableItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => widget.onItemSelected(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  Text(
                    item.formattedPrice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (item.unit != null || item.group?.name != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (item.unit != null) ...[
                      Icon(Icons.straighten, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${'Unit'.tr()}: ${item.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    if (item.unit != null && item.group?.name != null)
                      Text(
                        ' • ',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    if (item.group?.name != null) ...[
                      Icon(Icons.category, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        item.group!.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to select'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryGreen,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog for selecting items
class ItemSelectionDialog extends StatelessWidget {
  final Function(AvailableItem) onItemSelected;

  const ItemSelectionDialog({
    super.key,
    required this.onItemSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(AvailableItem) onItemSelected,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ItemSelectionDialog(
        onItemSelected: onItemSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Item'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ItemSelectionWidget(
                onItemSelected: (item) {
                  Navigator.pop(context);
                  onItemSelected(item);
                },
                searchHint: 'Search available items...'.tr(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
