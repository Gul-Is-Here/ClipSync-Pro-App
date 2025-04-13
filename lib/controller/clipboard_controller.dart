import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:history_manager/model/clipItem.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_clipboard/super_clipboard.dart';

enum ClipFilter { all, text }

class ClipboardController extends GetxController {
  // Main data stores
  final RxList<ClipItem> clips = <ClipItem>[].obs;
  final RxList<ClipItem> filteredClips = <ClipItem>[].obs;
  final RxList<String> categories =
      <String>['All', 'Work', 'Personal', 'Code'].obs;

  // State management
  final Rx<ClipFilter> currentFilter = ClipFilter.all.obs;
  final RxString searchTerm = ''.obs;
  final RxString currentCategory = 'All'.obs;
  final RxBool pinMode = false.obs;
  final RxBool secureMode = false.obs;
  final RxBool isLoading = true.obs;
  // Storage keys
  final String _storageKey = "clipboard_history_v2";
  final String _categoriesKey = "clipboard_categories";
  final String _settingsKey = "clipboard_settings";

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await loadClips();
    await loadCategories();
    await loadSettings();
    everAll([
      clips,
      currentFilter,
      searchTerm,
      pinMode,
      currentCategory,
      secureMode,
    ], (_) => filterClips());
  }

  Future<void> loadClips() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_storageKey);
      if (saved != null) {
        clips.assignAll(saved.map((e) => ClipItem.fromJson(json.decode(e))));
      }
      filterClips();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_categoriesKey);
    if (saved != null && saved.isNotEmpty) {
      categories.assignAll(saved);
    }
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    secureMode.value = prefs.getBool('secure_mode') ?? false;
    pinMode.value = prefs.getBool('pin_mode') ?? false;
  }

  Future<void> _saveClips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      clips.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('secure_mode', secureMode.value);
    await prefs.setBool('pin_mode', pinMode.value);
  }

  void filterClips() {
    filteredClips.assignAll(
      clips.where((clip) {
        // Apply filter type
        final filterMatch =
            currentFilter.value == ClipFilter.all ||
            (currentFilter.value == ClipFilter.text);

        // Apply search term
        final searchMatch =
            searchTerm.value.isEmpty ||
            clip.content.toLowerCase().contains(searchTerm.value.toLowerCase());

        // Apply category filter
        final categoryMatch =
            currentCategory.value == 'All' ||
            clip.category == currentCategory.value;

        // Apply pin mode
        final pinMatch = !pinMode.value || clip.isPinned;

        return filterMatch && searchMatch && categoryMatch && pinMatch;
      }),
    );

    // Sort with pinned items first, then by recency
    filteredClips.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.time.compareTo(a.time);
    });
  }

  // Clipboard Operations
  Future<void> addFromClipboard() async {
    if (secureMode.value) {
      Get.snackbar('Secure Mode', 'Clipboard access disabled in secure mode');
      return;
    }

    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      Get.snackbar('Error', 'Clipboard not supported on this platform');
      return;
    }

    final reader = await clipboard.read();
    String? content;

    if (reader.canProvide(Formats.plainText)) {
      content = await reader.readValue<String>(Formats.plainText);
    } else if (reader.canProvide(Formats.htmlText)) {
      content = await reader.readValue<String>(Formats.htmlText);
    }

    if (content != null && content.isNotEmpty) {
      _addClip(content, category: currentCategory.value);
    } else {
      Get.snackbar('Info', 'No supported content found in clipboard');
    }
  }

  Future<void> addQuickNote(String content) async {
    if (content.trim().isEmpty) return;
    _addClip(content, isQuickNote: true, category: currentCategory.value);
  }

  void _addClip(
    String content, {
    bool isFavorite = false,
    bool isQuickNote = false,
    bool isPinned = false,
    String category = 'All',
  }) {
    if (content.trim().isEmpty) return;

    // Check for duplicates
    if (clips.any((clip) => clip.content == content && !clip.isQuickNote)) {
      Get.snackbar('Info', 'This content is already in your history');
      return;
    }

    clips.insert(
      0,
      ClipItem(
        content: content,
        time: DateTime.now(),
        isFavorite: isFavorite,
        isQuickNote: isQuickNote,
        isPinned: isPinned,
        category: category,
      ),
    );
    _saveClips();
  }

  // Clip Management
  Future<void> toggleFavorite(int index) async {
    final clip = filteredClips[index];
    final mainIndex = clips.indexWhere((c) => c.identifier == clip.identifier);
    if (mainIndex != -1) {
      clips[mainIndex].isFavorite = !clips[mainIndex].isFavorite;
      await _saveClips();
    }
  }

  Future<void> togglePin(int index) async {
    final clip = filteredClips[index];
    final mainIndex = clips.indexWhere((c) => c.identifier == clip.identifier);
    if (mainIndex != -1) {
      clips[mainIndex].isPinned = !clips[mainIndex].isPinned;
      await _saveClips();
    }
  }

  Future<void> editClip(
    int index,
    String newContent, {
    String? category,
  }) async {
    if (newContent.trim().isEmpty) {
      Get.snackbar('Error', 'Content cannot be empty');
      return;
    }

    final clip = filteredClips[index];
    final mainIndex = clips.indexWhere((c) => c.identifier == clip.identifier);
    if (mainIndex != -1) {
      clips[mainIndex].content = newContent;
      clips[mainIndex].time = DateTime.now();
      if (category != null) {
        clips[mainIndex].category = category;
      }
      await _saveClips();
    }
  }

  Future<void> deleteClip(int index) async {
    final clip = filteredClips[index];
    clips.removeWhere((c) => c.identifier == clip.identifier);
    await _saveClips();
  }

  clearAll() async {
    final confirmed = await Get.defaultDialog<bool>(
      title: "Confirm Clear",
      middleText: "This will permanently delete ALL clipboard history",
      textConfirm: "Delete All",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );

    if (confirmed == true) {
      clips.clear();
      filteredClips.clear(); // Clear filtered list too
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey); // Remove from storage completely
      Get.snackbar(
        'Cleared',
        'All history deleted',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Data Transfer
  Future<String> exportClips() async {
    final exportData = clips.map((clip) => clip.toJson()).toList();
    return json.encode(exportData);
  }

  Future<void> importClips(String jsonData) async {
    try {
      final imported =
          (json.decode(jsonData) as List)
              .map((e) => ClipItem.fromJson(e))
              .toList();

      // Merge without duplicates
      for (var clip in imported) {
        if (!clips.any((c) => c.content == clip.content)) {
          clips.add(clip);
        }
      }

      // Sort by time
      clips.sort((a, b) => b.time.compareTo(a.time));
      await _saveClips();
      Get.snackbar('Success', 'Clips imported successfully');
    } catch (e) {
      Get.snackbar('Error', 'Invalid import format');
    }
  }

  // Categories
  Future<void> addCategory(String name) async {
    if (name.trim().isEmpty) return;
    if (!categories.contains(name)) {
      categories.add(name);
      await _saveCategories();
    }
  }

  Future<void> removeCategory(String name) async {
    if (name == 'All') return;
    categories.remove(name);
    // Reset clips in this category to 'All'
    for (var clip in clips) {
      if (clip.category == name) {
        clip.category = 'All';
      }
    }
    await _saveCategories();
    await _saveClips();
  }

  // Security
  Future<void> toggleSecureMode() async {
    secureMode.value = !secureMode.value;
    await _saveSettings();
  }

  Future<void> togglePinMode() async {
    pinMode.value = !pinMode.value;
    await _saveSettings();
  }

  // Helpers
  Future<void> copyToClipboard(ClipItem clip) async {
    if (secureMode.value) {
      Get.snackbar('Secure Mode', 'Clipboard access disabled in secure mode');
      return;
    }

    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      Get.snackbar('Error', 'Clipboard not supported on this platform');
      return;
    }

    final item = DataWriterItem();
    item.add(Formats.plainText(clip.content));
    await clipboard.write([item]);
    Get.snackbar('Copied', 'Content copied to clipboard');
  }
}
