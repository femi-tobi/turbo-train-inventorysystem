class SupplierModel {
  final int? id;
  final String name;
  final String? phone;
  final DateTime createdAt;

  SupplierModel({
    this.id,
    required this.name,
    this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'created_at': createdAt.toIso8601String(),
      };

  factory SupplierModel.fromMap(Map<String, dynamic> map) => SupplierModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
