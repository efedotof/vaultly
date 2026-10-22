class PageDto<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;

  const PageDto({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
  });

  factory PageDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    return PageDto(
      content: (json['content'] as List? ?? [])
          .map((e) => itemFromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isEmpty => content.isEmpty;
  bool get hasNext => number + 1 < totalPages;
}