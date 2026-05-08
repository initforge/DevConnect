import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/core/models/models.dart';

void main() {
  group('ProjectRepository - Data Models', () {
    test('Project stores all data correctly', () {
      final owner = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2024, 1, 1),
      );
      final project = Project(
        id: 'proj1',
        owner: owner,
        title: 'Test Project',
        description: 'A test project description',
        techStack: ['Flutter', 'Dart', 'Firebase'],
        status: 'LOOKING_FOR_MEMBERS',
        memberCount: 2,
        maxMembers: 5,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(project.id, 'proj1');
      expect(project.owner, owner);
      expect(project.title, 'Test Project');
      expect(project.description, 'A test project description');
      expect(project.techStack, ['Flutter', 'Dart', 'Firebase']);
      expect(project.status, 'LOOKING_FOR_MEMBERS');
      expect(project.memberCount, 2);
      expect(project.maxMembers, 5);
    });

    test('Project handles default values', () {
      final owner = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2024, 1, 1),
      );
      final project = Project(
        id: 'proj1',
        owner: owner,
        title: 'Minimal Project',
        description: 'Description',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(project.techStack, isEmpty);
      expect(project.status, 'LOOKING_FOR_MEMBERS');
      expect(project.memberCount, 1);
      expect(project.maxMembers, 5);
    });

    test('Project handles empty tech stack', () {
      final owner = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2024, 1, 1),
      );
      final project = Project(
        id: 'proj1',
        owner: owner,
        title: 'Test',
        description: 'Test',
        techStack: [],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(project.techStack, isEmpty);
    });

    test('Project handles all status values', () {
      final owner = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2024, 1, 1),
      );

      final statuses = ['LOOKING_FOR_MEMBERS', 'ACTIVE', 'COMPLETED', 'ON_HOLD'];
      for (final status in statuses) {
        final project = Project(
          id: 'proj1',
          owner: owner,
          title: 'Test',
          description: 'Test',
          status: status,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(project.status, status);
      }
    });
  });
}
