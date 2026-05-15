import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/core/models/models.dart';

void main() {
  group('JobRepository - Data Models', () {
    test('Job stores all data correctly', () {
      final job = Job(
        id: 'j1',
        company: 'TechCorp',
        title: 'Senior Developer',
        location: 'Ho Chi Minh City',
        remote: true,
        salaryRange: '\$2,000 - \$3,000',
        techStack: const ['Flutter', 'Dart', 'Firebase'],
        experience: '3-5 years',
        matchPercent: 85,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(job.id, 'j1');
      expect(job.company, 'TechCorp');
      expect(job.title, 'Senior Developer');
      expect(job.location, 'Ho Chi Minh City');
      expect(job.remote, true);
      expect(job.salaryRange, '\$2,000 - \$3,000');
      expect(job.techStack, ['Flutter', 'Dart', 'Firebase']);
      expect(job.experience, '3-5 years');
      expect(job.matchPercent, 85);
    });

    test('Job handles remote false', () {
      final job = Job(
        id: 'j1',
        company: 'Local Corp',
        title: 'Developer',
        location: 'Hanoi',
        remote: false,
        salaryRange: '\$1,000 - \$2,000',
        experience: '1-3 years',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(job.remote, false);
    });

    test('Job handles empty tech stack', () {
      final job = Job(
        id: 'j1',
        company: 'Test Corp',
        title: 'Developer',
        location: 'Remote',
        salaryRange: '\$1,000',
        techStack: const [],
        experience: 'Any',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(job.techStack, isEmpty);
    });

    test('Job handles zero match percent', () {
      final job = Job(
        id: 'j1',
        company: 'Test Corp',
        title: 'Developer',
        location: 'Remote',
        salaryRange: '\$1,000',
        experience: 'Any',
        matchPercent: 0,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(job.matchPercent, 0);
    });

    test('Job handles intern position', () {
      final job = Job(
        id: 'j1',
        company: 'Startup',
        title: 'Intern Developer',
        location: 'Remote',
        salaryRange: '\$500 - \$800',
        experience: 'Internship',
        matchPercent: 45,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(job.experience, 'Internship');
      expect(job.matchPercent, 45);
    });
  });
}
