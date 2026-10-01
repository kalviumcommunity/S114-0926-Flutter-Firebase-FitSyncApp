import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;
import 'package:app/models/user.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Flow', () {
    testWidgets('Register new member', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to register
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Fill registration form
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Member');
      await tester.enterText(find.byType(TextFormField).at(1), 'test_member_${DateTime.now().millisecondsSinceEpoch}@test.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      
      // Select Member role
      await tester.tap(find.byType(DropdownButtonFormField<UserRole>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Member').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should navigate to member dashboard
      expect(find.text('My Workouts'), findsOneWidget);
    });

    testWidgets('Login with existing account', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should navigate to appropriate dashboard based on role
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Password reset flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'test@test.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('Email Sent!'), findsOneWidget);
    });
  });

  group('Member Workout Flow', () {
    testWidgets('View assigned workout plan', (WidgetTester tester) async {
      // This would require a logged-in member with assigned plans
      // Skipped for now - requires test data setup
    });

    testWidgets('Log workout completion', (WidgetTester tester) async {
      // Would test the log workout flow with sets/reps tracking
      // Skipped for now - requires test data setup
    });
  });

  group('Trainer Workout Builder', () {
    testWidgets('Create workout plan', (WidgetTester tester) async {
      // Would test trainer creating a workout plan with exercises
      // Skipped for now - requires trainer login and test data
    });

    testWidgets('Assign plan to member', (WidgetTester tester) async {
      // Would test assigning plan to member
      // Skipped for now - requires test data setup
    });
  });

  group('Admin Features', () {
    testWidgets('Create branch', (WidgetTester tester) async {
      // Would test admin creating a branch
      // Skipped for now - requires admin login
    });

    testWidgets('Transfer member between trainers', (WidgetTester tester) async {
      // Would test member transfer flow
      // Skipped for now - requires admin login and test data
    });
  });
}