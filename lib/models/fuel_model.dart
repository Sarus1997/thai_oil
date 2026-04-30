class FuelBrand {
  final String id;
  final String name;
  final String shortName;

  const FuelBrand({
    required this.id,
    required this.name,
    required this.shortName,
  });

  static const List<FuelBrand> all = [
    FuelBrand(id: 'ptt', name: 'ปตท.', shortName: 'PTT'),
    FuelBrand(id: 'shell', name: 'เชลล์', shortName: 'Shell'),
    FuelBrand(id: 'bcp', name: 'บางจาก', shortName: 'BCP'),
    FuelBrand(id: 'pt', name: 'พีที', shortName: 'PT'),
    FuelBrand(id: 'caltex', name: 'คาลเท็กซ์', shortName: 'Caltex'),
    FuelBrand(id: 'susco', name: 'ซัสโก้', shortName: 'SUSCO'),
    FuelBrand(id: 'irpc', name: 'ไออาร์พีซี', shortName: 'IRPC'),
    FuelBrand(id: 'pure', name: 'เพียว', shortName: 'Pure'),
  ];
}

class FuelPrice {
  final String type;
  final String typeLabel;
  final double price;
  final double change;
  final String category;

  const FuelPrice({
    required this.type,
    required this.typeLabel,
    required this.price,
    required this.change,
    required this.category,
  });

  bool get isUp => change > 0;
  bool get isDown => change < 0;
  bool get isFlat => change == 0;
}

class GasStation {
  final String id;
  final String name;
  final String brand;
  final String brandId;
  final String address;
  final double lat;
  final double lng;
  final double distance;
  final double rating;
  final int reviewCount;
  final String hours;
  final bool isOpen;
  final List<FuelPrice> prices;
  final String? placeId; // Google Place ID — เปิด Maps / Details

  const GasStation({
    required this.id,
    required this.name,
    required this.brand,
    required this.brandId,
    required this.address,
    required this.lat,
    required this.lng,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.hours,
    required this.isOpen,
    required this.prices,
    this.placeId,
  });
}
