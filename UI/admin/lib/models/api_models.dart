class AuthSession {
  final String token;
  final int id;
  final bool isAdmin;
  final bool isActive;

  const AuthSession({
    required this.token,
    required this.id,
    required this.isAdmin,
    required this.isActive,
  });

  factory AuthSession.fromJson(Map<String, Object?> json) {
    return AuthSession(
      token: json['token'] as String? ?? json['Token'] as String? ?? '',
      id: (json['id'] as num?)?.toInt() ?? 0,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class PagedResponse<T> {
  final List<T> results;
  final int count;

  const PagedResponse({required this.results, required this.count});

  factory PagedResponse.fromJson(
    Map<String, Object?> json,
    T Function(Map<String, Object?> item) fromJson,
  ) {
    final rawResults = json['results'] as List? ?? const [];

    return PagedResponse<T>(
      results: rawResults
          .whereType<Map>()
          .map((item) => fromJson(item.cast<String, Object?>()))
          .toList(),
      count: (json['count'] as num?)?.toInt() ?? rawResults.length,
    );
  }
}