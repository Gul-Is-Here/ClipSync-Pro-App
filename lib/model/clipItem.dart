class ClipItem {
   String content;
   DateTime time;

   bool isFavorite;
   bool isPinned;
   bool isQuickNote;
   String category;
   String identifier;
   String? previewText;

  ClipItem({
    required this.content,
    required this.time,
 
    this.isFavorite = false,
    this.isPinned = false,
    this.isQuickNote = false,
    this.category = 'All',
    String? identifier,
  }) : 
    identifier = identifier ?? '${time.millisecondsSinceEpoch}_${content.hashCode}',
    previewText =  content.length > 100 
      ? '${content.substring(0, 100)}...' 
      : null;

  // Content type classification
  String get typeDescription {

    if (isQuickNote) return 'Quick Note';
    if (content.length > 500) return 'Long Text';
    if (content.contains('\n')) return 'Multiline';
    if (Uri.tryParse(content)?.hasAbsolutePath ?? false) return 'URL';
    if (content.contains(RegExp(r'\d{10}'))) return 'Phone';
    if (content.contains('@')) return 'Email';
    return 'Text';
  }

  // // Smart size description
String get sizeDescription {
  final length = content.length;
  if (length >= 1000000) {
    return '${(length / 1000000).toStringAsFixed(1)}M chars';
  }
  if (length >= 1000) {
    return '${(length / 1000).toStringAsFixed(1)}K chars';
  }
  return '$length ${length == 1 ? 'char' : 'chars'}';
}

  // Enhanced JSON serialization
  Map<String, dynamic> toJson() => {
    'content': content,
    'time': time.toIso8601String(),
    'isFavorite': isFavorite,
    'isPinned': isPinned,
    'isQuickNote': isQuickNote,
    'category': category,
    'identifier': identifier,
    'v': 2 // Version identifier for migration
  };

  factory ClipItem.fromJson(Map<String, dynamic> json) {
    // Handle migration from older versions
    final version = json['v'] ?? 1;
    return ClipItem(
      content: json['content'],
      time: DateTime.parse(json['time']),
    
      isFavorite: json['isFavorite'] ?? false,
      isPinned: version > 1 ? json['isPinned'] ?? false : false,
      isQuickNote: version > 1 ? json['isQuickNote'] ?? false : false,
      category: version > 1 ? json['category'] ?? 'All' : 'All',
      identifier: json['identifier'] ?? 
        '${DateTime.parse(json['time']).millisecondsSinceEpoch}_${json['content'].hashCode}',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipItem &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier;

  @override
  int get hashCode => identifier.hashCode;

  // Enhanced copyWith with all new fields
  ClipItem copyWith({
    String? content,
    DateTime? time,
    bool? isImage,
    bool? isFavorite,
    bool? isPinned,
    bool? isQuickNote,
    String? category,
    String? identifier,
  }) {
    return ClipItem(
      content: content ?? this.content,
      time: time ?? this.time,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      isQuickNote: isQuickNote ?? this.isQuickNote,
      category: category ?? this.category,
      identifier: identifier ?? this.identifier,
    );
  }

  // Smart content analysis
  bool get containsUrl => Uri.tryParse(content)?.hasAbsolutePath ?? false;
  bool get containsEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(content);
  bool get containsPhone => RegExp(r'^[\d\s\-+]{10,}$').hasMatch(content);

  // Quick actions
  List<String> get quickActions {
    final actions = <String>[];
    if (containsUrl) actions.add('Open URL');
    if (containsEmail) actions.add('Send Email');
    if (containsPhone) actions.add('Call Number');
    actions.addAll(['Copy', 'Share', 'Favorite']);
    return actions;
  }
}