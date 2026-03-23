class Issue {
  final int id;
  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? completionImage;
  final String status;
  final String priority;

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.completionImage,
    required this.status,
    required this.priority,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] ?? json['issue_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      latitude: json['latitude'] is String 
          ? double.tryParse(json['latitude']) ?? 0.0 
          : (json['latitude'] ?? 0.0).toDouble(),
      longitude: json['longitude'] is String 
          ? double.tryParse(json['longitude']) ?? 0.0 
          : (json['longitude'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'],
      completionImage: json['completion_image'],
      status: json['status'] ?? 'Pending',
      priority: json['priority'] ?? 'Medium',
    );
  }
}
