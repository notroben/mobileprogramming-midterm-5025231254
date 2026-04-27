class Report {
  final int? id;
  final String imagePath;
  final String caption;
  final double latitude;
  final double longitude;
  final String timestamp;

  Report({
    this.id,
    required this.imagePath,
    required this.caption,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'caption': caption,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }
}