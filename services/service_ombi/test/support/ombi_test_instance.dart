import 'package:core_models/core_models.dart';

/// The instance the tests drive. Nothing under test reads its kind, which
/// stays Seerr until Ombi is registered as a kind of its own.
const Instance ombiTestInstance = Instance(
  id: 'test-ombi',
  name: 'Test Ombi',
  kind: ServiceKind.seerr,
  localUrl: 'http://ombi.test',
  externalUrl: '',
  urlMode: UrlMode.auto,
  auth: InstanceAuth.apiKey(apiKey: 'k'),
);
