/// Model representing a Site Visit in Frappe ("Site Visit" DocType).
class SiteVisit {
  const SiteVisit({
    required this.name,
    this.lead,
    this.leadName,
    this.mobileNo,
    this.village,
    this.district,
    this.visitDate,
    this.visitedBy,
    this.status = 'Planned',
    this.diameterFt,
    this.expectedDepthFt,
    this.rockFromFt,
    this.soilType,
    this.latitude,
    this.longitude,
    this.mapLink,
    this.notes,
  });

  final String name;
  final String? lead;
  final String? leadName;
  final String? mobileNo;
  final String? village;
  final String? district;
  final DateTime? visitDate;
  final String? visitedBy;
  final String status;
  final int? diameterFt;
  final int? expectedDepthFt;
  final int? rockFromFt;
  final String? soilType;
  final double? latitude;
  final double? longitude;
  final String? mapLink;
  final String? notes;

  factory SiteVisit.fromJson(Map<String, dynamic> json) => SiteVisit(
    name: _string(json['name']) ?? '',
    lead: _string(json['lead']),
    leadName: _string(json['lead_name']),
    mobileNo: _string(json['mobile_no']),
    village: _string(json['village']),
    district: _string(json['district']),
    visitDate: _dateTime(json['visit_date']),
    visitedBy: _string(json['visited_by']),
    status: _string(json['status']) ?? 'Planned',
    diameterFt: _int(json['diameter_ft']),
    expectedDepthFt: _int(json['expected_depth_ft']),
    rockFromFt: _int(json['rock_from_ft']),
    soilType: _string(json['soil_type']),
    latitude: _double(json['latitude']),
    longitude: _double(json['longitude']),
    mapLink: _string(json['map_link']),
    notes: _string(json['notes']),
  );

  Map<String, dynamic> toJson() => {
    if (lead != null) 'lead': lead,
    if (leadName != null) 'lead_name': leadName,
    if (mobileNo != null) 'mobile_no': mobileNo,
    if (village != null) 'village': village,
    if (district != null) 'district': district,
    if (visitDate != null) 'visit_date': visitDate!.toIso8601String(),
    if (visitedBy != null) 'visited_by': visitedBy,
    'status': status,
    if (diameterFt != null) 'diameter_ft': diameterFt,
    if (expectedDepthFt != null) 'expected_depth_ft': expectedDepthFt,
    if (rockFromFt != null) 'rock_from_ft': rockFromFt,
    if (soilType != null) 'soil_type': soilType,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (mapLink != null) 'map_link': mapLink,
    if (notes != null) 'notes': notes,
  };

  String get displayTitle =>
      (leadName != null && leadName!.isNotEmpty) ? leadName! : name;

  String? get locationText {
    final parts = [village, district].where((s) => s != null && s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String? _string(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _int(Object? v) => switch (v) {
    int i => i,
    num n => n.toInt(),
    String s => int.tryParse(s),
    _ => null,
  };

  static double? _double(Object? v) => switch (v) {
    double d => d,
    num n => n.toDouble(),
    String s => double.tryParse(s),
    _ => null,
  };

  static DateTime? _dateTime(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
}
