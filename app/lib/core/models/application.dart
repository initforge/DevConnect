import 'package:equatable/equatable.dart';

class Application extends Equatable {
  final String id;
  final String jobId;
  final String company;
  final String jobTitle;
  final String location;
  final bool remote;
  final String salaryRange;
  final List<String> techStack;
  final String experience;
  final String coverNote;
  final String resumeUrl;
  final String status;
  final DateTime createdAt;

  const Application({
    required this.id,
    required this.jobId,
    required this.company,
    required this.jobTitle,
    required this.location,
    this.remote = false,
    required this.salaryRange,
    this.techStack = const [],
    required this.experience,
    required this.coverNote,
    required this.resumeUrl,
    required this.status,
    required this.createdAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      jobTitle: json['jobTitle']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      remote: json['remote'] == true,
      salaryRange: json['salaryRange']?.toString() ?? '',
      techStack:
          json['techStack'] is List
              ? (json['techStack'] as List).map((e) => e.toString()).toList()
              : [],
      experience: json['experience']?.toString() ?? '',
      coverNote: json['coverNote']?.toString() ?? '',
      resumeUrl: json['resumeUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id];
}
