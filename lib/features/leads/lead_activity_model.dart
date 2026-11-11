import 'dart:convert';

import 'package:intl/intl.dart';

/// An "FCRM Note" attached to a lead.
class CrmNote {
  const CrmNote({
    required this.name,
    this.title,
    this.content,
    this.owner,
    this.creation,
  });

  final String name;
  final String? title;

  /// Plain text (HTML from Frappe's text editor is stripped).
  final String? content;
  final String? owner;
  final DateTime? creation;

  factory CrmNote.fromJson(Map<String, dynamic> json) => CrmNote(
    name: _string(json['name']) ?? '',
    title: _string(json['title']),
    content: _string(htmlToPlainText(_string(json['content']))),
    owner: _string(json['owner']),
    creation: _dateTime(json['creation']),
  );
}

/// A "CRM Task" attached to a lead.
class CrmTask {
  const CrmTask({
    required this.name,
    this.title,
    this.status,
    this.dueDate,
    this.priority,
    this.description,
    this.referenceDocname,
  });

  /// Title used for tasks this app creates; also how it finds them again.
  static const String followUpTitle = 'Follow-up call';

  final String name;
  final String? title;
  final String? status;
  final DateTime? dueDate;
  final String? priority;

  /// Plain text (HTML stripped).
  final String? description;

  /// The lead this task belongs to.
  final String? referenceDocname;

  bool get isOpen => status != 'Done' && status != 'Canceled';
  bool get isFollowUp => title == followUpTitle;

  bool isOverdue(DateTime now) => dueDate != null && dueDate!.isBefore(now);

  factory CrmTask.fromJson(Map<String, dynamic> json) => CrmTask(
    name: _string(json['name']) ?? '',
    title: _string(json['title']),
    status: _string(json['status']),
    dueDate: _dateTime(json['due_date']),
    priority: _string(json['priority']),
    description: _string(htmlToPlainText(_string(json['description']))),
    referenceDocname: _string(json['reference_docname']),
  );
}

/// Result of a phone call, stored on the server in English so every CRM
/// user sees the same value.
enum CallOutcome {
  talked('Talked'),
  noAnswer('No answer'),
  busy('Busy'),
  wrongNumber('Wrong number');

  const CallOutcome(this.serverLabel);

  final String serverLabel;

  /// Note title saved for this outcome, e.g. "Call: Talked".
  String get noteTitle => '$notePrefix$serverLabel';

  static const String notePrefix = 'Call: ';

  /// Recognises a title written by [noteTitle].
  static CallOutcome? fromNoteTitle(String? title) {
    if (title == null || !title.startsWith(notePrefix)) return null;
    final label = title.substring(notePrefix.length);
    for (final outcome in values) {
      if (outcome.serverLabel == label) return outcome;
    }
    return null;
  }
}

/// Frappe datetime string, interpreted in device time.
final DateFormat frappeDateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

/// Wraps plain text as a paragraph for Frappe's text editor fields.
String plainTextToHtml(String text) {
  if (text.trim().isEmpty) return '';
  final escaped = const HtmlEscape().convert(text.trim());
  return '<p>${escaped.replaceAll('\n', '<br>')}</p>';
}

/// Minimal HTML → text for note content: keeps line breaks, drops tags,
/// decodes the common entities.
String? htmlToPlainText(String? html) {
  if (html == null) return null;
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li|h\d)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

String? _string(Object? value) {
  if (value == null) return null;
  final text = (value is String ? value : value.toString()).trim();
  return text.isEmpty ? null : text;
}

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
