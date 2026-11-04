import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autopartslink/core/constants/app_constants.dart';
import 'package:autopartslink/models/rating.dart';
import 'package:autopartslink/screens/common/welcome_screen.dart';

void main() {
  testWidgets('Welcome screen shows app name and auth buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Create an Account'), findsOneWidget);
  });

  test('Rating.fromMap parses score and optional review', () {
    final rating = Rating.fromMap('order1', {
      'customerId': 'c1',
      'customerName': 'Ama',
      'supplierId': 's1',
      'score': 4,
      'review': {'title': 'Fast', 'body': 'Delivered on time'},
    });

    expect(rating.orderId, 'order1');
    expect(rating.score, 4);
    expect(rating.review?.title, 'Fast');

    final noReview = Rating.fromMap('order2', {'score': 5});
    expect(noReview.review, isNull);
  });
}
