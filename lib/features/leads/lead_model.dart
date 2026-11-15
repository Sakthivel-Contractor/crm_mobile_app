/// A Frappe CRM "CRM Lead" row. Every field except [name] is optional; any
/// missing, null or wrongly typed value becomes null instead of throwing.
class CrmLead {
  const CrmLead({
    required this.name,
    this.firstName,
    this.lastName,
    this.leadName,
    this.mobileNo,
    this.email,
    this.status,
    this.source,
    this.district,
    this.workType,
    this.leadOwner,
    this.modified,
    this.creation,
  });

  /// Document id, e.g. "CRM-LEAD-2024-00012".
  final String name;
  final String? firstName;
  final String? lastName;
  final String? leadName;
  final String? mobileNo;
  final String? email;
  final String? status;
  final String? source;
  final String? district;
  final String? workType;
  final String? leadOwner;
  final DateTime? modified;
  final DateTime? creation;

  factory CrmLead.fromJson(Map<String, dynamic> json) => CrmLead(
    name: _string(json['name']) ?? '',
    firstName: _string(json['first_name']),
    lastName: _string(json['last_name']),
    leadName: _string(json['lead_name']),
    mobileNo: _string(json['mobile_no']),
    email: _string(json['email']),
    status: _string(json['status']),
    source: _string(json['source']),
    district: _string(json['custom_district'] ?? json['district']),
    workType: _string(json['custom_work_type'] ?? json['work_type']),
    leadOwner: _string(json['lead_owner']),
    modified: _dateTime(json['modified']),
    creation: _dateTime(json['creation']),
  );

  /// Best available human name, or null if the lead has none.
  String? get displayName {
    if (leadName != null) return leadName;
    final parts = [firstName, lastName].whereType<String>();
    return parts.isEmpty ? null : parts.join(' ');
  }
}

/// A "CRM Lead Status" row.
class LeadStatus {
  const LeadStatus({required this.name, this.color, this.position, this.type});

  final String name;

  /// Frappe CRM colour name ("blue", "green", ...) or a hex value.
  final String? color;
  final int? position;
  final String? type;

  factory LeadStatus.fromJson(Map<String, dynamic> json) => LeadStatus(
    name: _string(json['name']) ?? '',
    color: _string(json['color']),
    position: _int(json['position']),
    type: _string(json['type']),
  );
}

String? _string(Object? value) {
  if (value == null) return null;
  final text = (value is String ? value : value.toString()).trim();
  return text.isEmpty ? null : text;
}

int? _int(Object? value) => switch (value) {
  int v => v,
  num v => v.toInt(),
  String v => int.tryParse(v),
  _ => null,
};

/// Frappe sends "2024-05-01 12:34:56.123456" in the server's time zone.
DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
