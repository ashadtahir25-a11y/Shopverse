enum AddressLabel { home, office, other }

extension AddressLabelX on AddressLabel {
  String get display => switch (this) {
    AddressLabel.home => 'Home',
    AddressLabel.office => 'Office',
    AddressLabel.other => 'Other',
  };
}

class Address {
  final String id;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String area;
  final String postalCode;
  final String? instructions;
  final AddressLabel label;
  final bool isDefault;

  const Address({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.area,
    required this.postalCode,
    this.instructions,
    this.label = AddressLabel.home,
    this.isDefault = false,
  });

  String get formatted => '$addressLine, $area, $city $postalCode';

  Map<String, dynamic> toFirestoreMap(String userId) => {
    'userId': userId,
    'fullName': fullName,
    'phone': phone,
    'addressLine': addressLine,
    'city': city,
    'area': area,
    'postalCode': postalCode,
    'instructions': instructions,
    'label': label.name,
    'isDefault': isDefault,
  };

  factory Address.fromFirestore(String id, Map<String, dynamic> data) {
    return Address(
      id: id,
      fullName: data['fullName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      addressLine: data['addressLine'] as String? ?? '',
      city: data['city'] as String? ?? '',
      area: data['area'] as String? ?? '',
      postalCode: data['postalCode'] as String? ?? '',
      instructions: data['instructions'] as String?,
      label: AddressLabel.values.firstWhere(
        (l) => l.name == data['label'],
        orElse: () => AddressLabel.home,
      ),
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }
}
