class Person {
  final int? personId;
  final String name;
  final String? birthDate;
  final String? deathDate;
  final String description;
  final String? imageUrl;

  Person({
    this.personId,
    required this.name,
    this.birthDate,
    this.deathDate,
    required this.description,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'person_id': personId,
      'name': name,
      'birth_date': birthDate,
      'death_date': deathDate,
      'description': description,
      'image_url': imageUrl,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      personId: map['person_id'] as int?,
      name: map['name'] as String,
      birthDate: map['birth_date'] as String?,
      deathDate: map['death_date'] as String?,
      description: map['description'] as String,
      imageUrl: map['image_url'] as String?,
    );
  }

  Person copyWith({
    int? personId,
    String? name,
    String? birthDate,
    String? deathDate,
    String? description,
    String? imageUrl,
  }) {
    return Person(
      personId: personId ?? this.personId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
