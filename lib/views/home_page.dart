import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:history_manager/controller/clipboard_controller.dart';
import 'package:history_manager/model/clipItem.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ClipboardController _controller = Get.put(ClipboardController());
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showPrivacyDialog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _showPrivacyDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final privacyAccepted = prefs.getBool('privacy_accepted') ?? false;

    if (!privacyAccepted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text("Privacy Policy"),
              content: const SingleChildScrollView(
                child: Text(
                  "This app accesses your clipboard to save text history locally on your device. "
                  "No data is collected, shared, or stored externally. "
                  "All information remains private on your device.\n\n"
                  "By using this app, you agree to our Terms of Service and Privacy Policy.",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    prefs.setBool('privacy_accepted', true);
                  },
                  child: const Text("I Agree"),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          _buildFilterRow(),
          const SizedBox(height: 8),
          _buildClipboardList(),
        ],
      ),
      floatingActionButton: _buildMultiActionFab(),
    );
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text("ClipSync Pro"),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => setState(() => _isSearching = true),
          tooltip: "Search clips",
        ),
        _buildMoreMenu(),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: _exitSearchMode,
      ),
      title: TextField(
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
          hintText: "Search clipboard history...",
          border: InputBorder.none,
        ),
        onChanged: (value) => _controller.searchTerm.value = value,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _clearSearch,
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildCategoryDropdown()),
          const SizedBox(width: 8),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Obx(
      () => DropdownButtonFormField<String>(
        value: _controller.currentCategory.value,
        items:
            _controller.categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            _controller.currentCategory.value = value;
          }
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        isExpanded: true,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Obx(
      () => Wrap(
        spacing: 8,
        children:
            ClipFilter.values.map((filter) {
              return FilterChip(
                label: Text(
                  filter.toString().split('.').last,
                  style: TextStyle(
                    color:
                        _controller.currentFilter.value == filter
                            ? Colors.white
                            : Colors.black,
                  ),
                ),
                selected: _controller.currentFilter.value == filter,
                onSelected: (selected) {
                  _controller.currentFilter.value = filter;
                },
                shape: StadiumBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                showCheckmark: false,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildClipboardList() {
    return Expanded(
      child: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.filteredClips.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _controller.filteredClips.length,
          itemBuilder: (ctx, index) {
            final clip = _controller.filteredClips[index];
            return _buildClipItem(clip, index);
          },
        );
      }),
    );
  }

  Widget _buildClipItem(ClipItem clip, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleClipTap(clip),
        onLongPress: () => _showClipOptions(clip, index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClipHeader(clip),
              const SizedBox(height: 8),
              Text(
                clip.previewText ?? clip.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (clip.content.length > 100) ...[
                const SizedBox(height: 8),
                Text(
                  clip.sizeDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClipHeader(ClipItem clip) {
    return Row(
      children: [
        Badge(
          backgroundColor: _getBadgeColor(clip),
          smallSize: 8,
          child: Icon(
            _getClipIcon(clip),
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          DateFormat('MMM dd, hh:mm a').format(clip.time),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),
        if (clip.isFavorite)
          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
        if (clip.category != 'All') ...[
          const SizedBox(width: 8),
          InputChip(
            label: Text(clip.category),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            onDeleted: null,
          ),
        ],
      ],
    );
  }

  Color _getBadgeColor(ClipItem clip) {
    if (clip.isPinned) return Colors.orange;
    if (clip.isQuickNote) return Colors.green;
    return Colors.transparent;
  }

  IconData _getClipIcon(ClipItem clip) {
    if (clip.isQuickNote) return Icons.note_rounded;
    if (clip.typeDescription == 'URL') return Icons.link_rounded;
    if (clip.typeDescription == 'Email') return Icons.email_rounded;
    if (clip.typeDescription == 'Phone') return Icons.phone_rounded;
    return Icons.content_paste_rounded;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.content_paste_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            "Your clipboard history is empty",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            "Copy something or create a quick note",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: _handleMenuSelection,
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'pin',
              child: ListTile(
                leading: Obx(
                  () => Icon(
                    _controller.pinMode.value
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                  ),
                ),
                title: const Text("Pin Mode"),
              ),
            ),
            const PopupMenuItem(
              value: 'privacy',
              child: ListTile(
                leading: Icon(Icons.privacy_tip_rounded),
                title: Text("Privacy Policy"),
              ),
            ),
            const PopupMenuItem(
              value: 'categories',
              child: ListTile(
                leading: Icon(Icons.category_rounded),
                title: Text("Categories"),
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.upload_rounded),
                title: Text("Export Clips"),
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: Icon(Icons.download_rounded),
                title: Text("Import Clips"),
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: ListTile(
                leading: Icon(Icons.delete_outline_rounded),
                title: Text("Clear All"),
              ),
            ),
          ],
    );
  }

  Widget _buildMultiActionFab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'quickNote',
          onPressed: _createQuickNote,
          tooltip: "Quick Note",
          child: const Icon(Icons.note_add_rounded),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'paste',
          onPressed: _controller.addFromClipboard,
          tooltip: "Paste from clipboard",
          child: const Icon(Icons.paste_rounded),
        ),
      ],
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'clear':
        _showClearConfirmation();
        break;
      case 'export':
        _exportClips();
        break;
      case 'import':
        _importClips();
        break;
      case 'pin':
        _controller.togglePinMode();
        break;
      case 'categories':
        _showCategoryDialog();
        break;
      case 'privacy':
        _showPrivacyPolicy();
        break;
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Privacy Policy"),
            content: const SingleChildScrollView(
              child: Text(
                "ClipSync Pro respects your privacy:\n\n"
                "• All clipboard data stays on your device\n"
                "• No data is collected or shared\n"
                "• No internet permissions required\n"
                "• You can export/delete your data anytime\n\n"
                "This app only accesses your clipboard when you explicitly paste content.",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  void _handleClipTap(ClipItem clip) {
    _controller.copyToClipboard(clip);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Copied to clipboard"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _exitSearchMode() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _controller.searchTerm.value = '';
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.searchTerm.value = '';
  }

  void _showClipOptions(ClipItem clip, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (clip.containsUrl)
                _buildActionTile(
                  context,
                  icon: Icons.link_rounded,
                  title: "Open URL",
                  action: () => _launchUrl(clip.content),
                ),
              if (clip.containsEmail)
                _buildActionTile(
                  context,
                  icon: Icons.email_rounded,
                  title: "Send Email",
                  action: () => _launchEmail(clip.content),
                ),
              if (clip.containsPhone)
                _buildActionTile(
                  context,
                  icon: Icons.phone_rounded,
                  title: "Call Number",
                  action: () => _launchPhone(clip.content),
                ),
              _buildActionTile(
                context,
                icon: Icons.copy_rounded,
                title: "Copy to clipboard",
                action: () {
                  Navigator.pop(context);
                  _handleClipTap(clip);
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.share_rounded,
                title: "Share",
                action: () {
                  Navigator.pop(context);
                  Share.share(clip.content);
                },
              ),
              _buildActionTile(
                context,
                icon:
                    clip.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                title: clip.isFavorite ? "Remove favorite" : "Add favorite",
                action: () {
                  _controller.toggleFavorite(index);
                  Navigator.pop(context);
                },
              ),
              _buildActionTile(
                context,
                icon:
                    clip.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                title: clip.isPinned ? "Unpin" : "Pin",
                action: () {
                  _controller.togglePin(index);
                  Navigator.pop(context);
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.edit_rounded,
                title: "Edit",
                action: () {
                  Navigator.pop(context);
                  _editClip(clip, index);
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.delete_rounded,
                title: "Delete",
                isDestructive: true,
                action: () {
                  _controller.deleteClip(index);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  ListTile _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback action,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(
        title,
        style:
            isDestructive
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : null,
      ),
      onTap: action,
    );
  }

  void _launchUrl(String url) {
    // Implement URL launcher with proper error handling
    Navigator.pop(context);
    Get.snackbar("Opening URL", "Launching $url");
  }

  void _launchEmail(String email) {
    // Implement email launcher
    Navigator.pop(context);
    Get.snackbar("Send Email", "Opening email client for $email");
  }

  void _launchPhone(String phone) {
    // Implement phone dialer
    Navigator.pop(context);
    Get.snackbar("Call Number", "Dialing $phone");
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Manage Categories"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: "New Category",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () {
                      if (_categoryController.text.trim().isNotEmpty) {
                        _controller.addCategory(
                          _categoryController.text.trim(),
                        );
                        _categoryController.clear();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => Wrap(
                  spacing: 8,
                  children:
                      _controller.categories.where((c) => c != 'All').map((
                        category,
                      ) {
                        return Chip(
                          label: Text(category),
                          onDeleted: () => _controller.removeCategory(category),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _editClip(ClipItem clip, int index) {
    final textController = TextEditingController(text: clip.content);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Edit Clip",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (textController.text.trim().isNotEmpty) {
                            _controller.editClip(
                              index,
                              textController.text.trim(),
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text("Clear All Items?"),
        content: const Text(
          "This will permanently remove all your clipboard history.",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog immediately
              final success = await _controller.clearAll();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All clipboard history cleared"),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _exportClips() async {
    try {
      final exported = await _controller.exportClips();
      Share.share(exported, subject: 'Exported Clipboard History');
    } catch (e) {
      Get.snackbar("Error", "Failed to export clips");
    }
  }

  Future<void> _importClips() async {
    final textController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Import Clips",
                style: Theme.of(Get.context!).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: textController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Paste exported JSON here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        try {
                          _controller.importClips(textController.text);
                          Get.back();
                          Get.snackbar(
                            "Success",
                            "Clips imported successfully",
                          );
                        } catch (e) {
                          Get.snackbar("Error", "Invalid import format");
                        }
                      },
                      child: const Text("Import"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createQuickNote() {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Create Quick Note",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: "Type your note here...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (textController.text.trim().isNotEmpty) {
                            _controller.addQuickNote(
                              textController.text.trim(),
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
