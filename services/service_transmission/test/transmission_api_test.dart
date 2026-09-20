import 'package:flutter_test/flutter_test.dart';
import 'package:service_transmission/service_transmission.dart';

import 'support/fake_transmission.dart';
import 'support/transmission_fixtures.dart';

void main() {
  late FakeTransmission fake;
  late TransmissionApi api;

  setUp(() {
    fake = FakeTransmission();
    api = TransmissionApi(fakeTransmissionDio(fake));
  });

  test('the first call is refused, retried with the session id, then kept',
      () async {
    fake.on('session-stats', statsJson());

    await api.getSessionStats();
    await api.getSessionStats();

    expect(fake.rejections, 1);
    expect(fake.to('session-stats'), hasLength(2));
  });

  test('a result other than success is an error with its text', () async {
    fake.fail('torrent-verify', 'No such torrent');

    await expectLater(
      api.verify(<String>['aaaa']),
      throwsA(
        predicate<Object>(
          (Object e) => e.toString().contains('No such torrent'),
        ),
      ),
    );
  });
}
