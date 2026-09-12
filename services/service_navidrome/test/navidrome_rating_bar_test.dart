import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_navidrome/src/widgets/navidrome_rating_bar.dart';

void main() {
  testWidgets('NavidromeRatingBar renders 5 stars and reflects filled state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NavidromeRatingBar(rating: 3),
        ),
      ),
    );

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
  });

  testWidgets('NavidromeRatingBar tap sets rating',
      (WidgetTester tester) async {
    int? selectedRating;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavidromeRatingBar(
            rating: 2,
            onRatingChanged: (val) => selectedRating = val,
          ),
        ),
      ),
    );

    // Tap 4th star
    final starIcons = find.byType(InkResponse);
    expect(starIcons, findsNWidgets(5));
    await tester.tap(starIcons.at(3));
    await tester.pumpAndSettle();

    expect(selectedRating, 4);
  });

  testWidgets('NavidromeRatingBar tapping active star resets rating to 0',
      (WidgetTester tester) async {
    int? selectedRating;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavidromeRatingBar(
            rating: 3,
            onRatingChanged: (val) => selectedRating = val,
          ),
        ),
      ),
    );

    // Tap 3rd star (which matches current rating of 3)
    final starIcons = find.byType(InkResponse);
    await tester.tap(starIcons.at(2));
    await tester.pumpAndSettle();

    expect(selectedRating, 0);
  });

  test('navidromeRatingLabel returns expected descriptors', () {
    expect(navidromeRatingLabel(0), 'Not Rated');
    expect(navidromeRatingLabel(1), '1 Star • Poor');
    expect(navidromeRatingLabel(3), '3 Stars • Good');
    expect(navidromeRatingLabel(5), '5 Stars • Masterpiece');
  });

  testWidgets('showNavidromeRatingModal displays modal with large stars and descriptor',
      (WidgetTester tester) async {
    int? updatedRating;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  showNavidromeRatingModal(
                    context: context,
                    title: 'Rate Album',
                    subtitle: 'Discovery',
                    initialRating: 4,
                    onRatingChanged: (int val) async {
                      updatedRating = val;
                    },
                  );
                },
                child: const Text('Open Modal'),
              );
            },
          ),
        ),
      ),
    );

    // Open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    expect(find.text('Rate Album'), findsOneWidget);
    expect(find.text('Discovery'), findsOneWidget);
    expect(find.text('4 Stars • Great'), findsOneWidget);
    expect(find.text('Remove Rating'), findsOneWidget);

    // Tap Remove Rating
    await tester.tap(find.text('Remove Rating'));
    await tester.pumpAndSettle();

    expect(updatedRating, 0);
  });
}
