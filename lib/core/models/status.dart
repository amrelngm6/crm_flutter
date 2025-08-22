class Status {
  final int id;
  final String name;
  final String color;

  Status({
    required this.id,
    required this.name,
    required this.color,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      id: json['status_id'] ?? 0,
      name: json['name'] ?? '',
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

  static List<Status> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Status.fromJson(json)).toList();
  }
}
