class DashboardData {
  const DashboardData({
    required this.greeting,
    required this.dailyScore,
    required this.streakDays,
    required this.categories,
  });

  final String greeting;
  final int dailyScore;
  final int streakDays;
  final Map<String, dynamic> categories;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        greeting: json['greeting']?.toString() ?? 'Welcome',
        dailyScore: (json['dailyScore'] as num?)?.toInt() ?? 0,
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
        categories: (json['categories'] as Map<String, dynamic>?) ?? {},
      );
}

class ProductData {
  const ProductData({
    required this.id,
    required this.name,
    required this.category,
    required this.timeOfDay,
    required this.completed,
    this.brand = '',
    this.notes = '',
    this.ingredients = const [],
    this.imageUrl,
    this.externalSource,
    this.frequency = 'daily',
    this.stepOrder = 1,
  });

  final String id;
  final String name;
  final String category;
  final String timeOfDay;
  final bool completed;
  final String brand;
  final String notes;
  final List<String> ingredients;
  final String? imageUrl;
  final String? externalSource;
  final String frequency;
  final int stepOrder;

  ProductData copyWith({bool? completed}) => ProductData(
        id: id,
        name: name,
        category: category,
        timeOfDay: timeOfDay,
        completed: completed ?? this.completed,
        brand: brand,
        notes: notes,
        ingredients: ingredients,
        imageUrl: imageUrl,
        externalSource: externalSource,
        frequency: frequency,
        stepOrder: stepOrder,
      );

  factory ProductData.fromJson(Map<String, dynamic> json) => ProductData(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        timeOfDay: json['time_of_day']?.toString() ?? '',
        completed: json['completed'] == true,
        brand: json['brand']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        ingredients: (json['ingredients'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        imageUrl: json['image_url']?.toString(),
        externalSource: json['external_source']?.toString(),
        frequency: json['frequency']?.toString() ?? 'daily',
        stepOrder: (json['step_order'] as num?)?.toInt() ?? 1,
      );
}

class ChatMessageData {
  const ChatMessageData({required this.role, required this.content});

  final String role;
  final String content;

  factory ChatMessageData.fromJson(Map<String, dynamic> json) => ChatMessageData(
        role: json['role']?.toString() ?? 'assistant',
        content: json['content']?.toString() ?? '',
      );
}
