class Place {
  final String name;
  final String street;
  final String housenumber;
  final String city;
  final String state;
  final String country;
  final String type;
  final double lat;
  final double lng;

  const Place({
    required this.name,
    required this.street,
    required this.housenumber,
    required this.city,
    required this.state,
    required this.country,
    required this.type,
    required this.lat,
    required this.lng,
  });

  bool get hasState => state.isNotEmpty;

  bool get hasCountry => country.isNotEmpty;

  bool get hasCity => city.isNotEmpty;

  bool get hasStreet => street.isNotEmpty;

  bool get hasHousenumber => housenumber.isNotEmpty;

  bool get isStreet => type == "street";

  bool get isCity => type == "city";

  bool get isState => type == "state";

  bool get isCountry => type == "country";

  factory Place.fromJson(Map<String, dynamic> map) {
    final props = map['properties'];
    final geo = map['geometry'];
    return Place(
      name: props['name'] ?? '',
      street: props['street'] ?? '',
      housenumber: props['housenumber'] ?? '',
      city: props['city'] ?? '',
      state: props['state'] ?? '',
      country: props['country'] ?? '',
      type: props['type'] ?? '',
      lat: geo['coordinates'][1] ?? 0.0,
      lng: geo['coordinates'][0] ?? 0.0,
    );
  }

  String get address {
    if (name == 'Select Location') {
      return name;
    }
    if (name.isNotEmpty && level2Address.isNotEmpty) {
      return '$name, $level2Address';
    }
    if (name.isEmpty && level2Address.isNotEmpty) {
      return level2Address;
    }
    return coordinates;
  }

  String get level2Address {
    if (isStreet) return state.isNotEmpty ? '$city, $state' : city;
    if (isCountry || isState || !hasState) return country;
    if (!isCity && hasStreet && hasCity) return '$street $housenumber, $city';
    return '$state, $country';
  }

  String get coordinates {
    return 'Lat: ' +
        lat.toStringAsPrecision(5) +
        ' - Long: ' +
        lng.toStringAsPrecision(5);
  }

  @override
  String toString() => 'Place(name: $name, state: $state, country: $country)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Place &&
        o.name == name &&
        o.state == state &&
        o.country == country;
  }

  @override
  int get hashCode => name.hashCode ^ state.hashCode ^ country.hashCode;

  static Place getDummyPlace() {
    return const Place(
        name: 'Select Location',
        state: '',
        country: '',
        lat: 0,
        lng: 0,
        street: '',
        city: '',
        type: '',
        housenumber: '');
  }
}
