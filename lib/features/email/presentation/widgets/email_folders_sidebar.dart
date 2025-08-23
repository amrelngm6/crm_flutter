import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class EmailFoldersSidebar extends StatelessWidget {
  final String selectedFolder;
  final Function(String) onFolderSelected;

  const EmailFoldersSidebar({
    super.key,
    required this.selectedFolder,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          right: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildFolderItem(
                  icon: Icons.inbox,
                  label: tr('Inbox'),
                  folder: 'inbox',
                  count: 0, // TODO: Get actual count
                ),
                _buildFolderItem(
                  icon: Icons.send,
                  label: tr('Sent'),
                  folder: 'sent',
                  count: 0,
                ),
                _buildFolderItem(
                  icon: Icons.drafts,
                  label: tr('Drafts'),
                  folder: 'drafts',
                  count: 0,
                ),
                _buildFolderItem(
                  icon: Icons.archive,
                  label: tr('Archive'),
                  folder: 'archive',
                  count: 0,
                ),
                _buildFolderItem(
                  icon: Icons.delete,
                  label: tr('Trash'),
                  folder: 'trash',
                  count: 0,
                ),
                _buildFolderItem(
                  icon: Icons.report,
                  label: tr('Spam'),
                  folder: 'spam',
                  count: 0,
                ),
                const Divider(height: 32),
                _buildFolderItem(
                  icon: Icons.star,
                  label: tr('Starred'),
                  folder: 'starred',
                  count: 0,
                ),
                _buildFolderItem(
                  icon: Icons.flag,
                  label: tr('Flagged'),
                  folder: 'flagged',
                  count: 0,
                ),
                _buildFolderItem(
                  icon: Icons.attach_file,
                  label: tr('Attachments'),
                  folder: 'attachments',
                  count: 0,
                ),
                const Divider(height: 32),
                _buildFolderItem(
                  icon: Icons.folder,
                  label: tr('Custom Folder 1'),
                  folder: 'custom1',
                  count: 0,
                ),
                _buildFolderItem(
                  icon: Icons.folder,
                  label: tr('Custom Folder 2'),
                  folder: 'custom2',
                  count: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder,
            color: const Color(0xFF1B4D3E),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            tr('Folders'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4D3E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem({
    required IconData icon,
    required String label,
    required String folder,
    required int count,
  }) {
    final isSelected = selectedFolder == folder;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[600],
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[700],
        ),
      ),
      trailing: count > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF1B4D3E).withOpacity(0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[600],
                ),
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: const Color(0xFF1B4D3E).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () => onFolderSelected(folder),
    );
  }
}