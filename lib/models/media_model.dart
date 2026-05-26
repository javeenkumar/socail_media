// Helper model for post/story creation
class MediaFile {
  final String path;
  final String type; // 'image', 'video', 'audio'
  final String? thumbnailPath;
  final int? duration; // in seconds for video/audio
  final int? size; // in bytes

  MediaFile({
    required this.path,
    required this.type,
    this.thumbnailPath,
    this.duration,
    this.size,
  });
}

// Filter model for stories
class StoryFilter {
  final String id;
  final String name;
  final String preview;
  final Map<String, dynamic> filterData;

  StoryFilter({
    required this.id,
    required this.name,
    required this.preview,
    required this.filterData,
  });
}