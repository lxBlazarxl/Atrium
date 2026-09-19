import 'generated/generated.dart';

/// Says what went wrong, in words a user can act on.
///
/// [searching] marks a failed search. Ombi answers 500 when it cannot reach
/// TheMovieDB, which on some networks happens often, so the message points
/// there rather than at Atrium.
String describeOmbiFailure(Object error, {bool searching = false}) {
  final int? status = error is OmbiException ? error.statusCode : null;
  if (error is! OmbiException || status == null) {
    return 'Ombi could not be reached.';
  }
  if (status == 401 || status == 403) {
    return 'Ombi refused the API key. It is under Settings, Ombi.';
  }
  if (status >= 200 && status < 300) {
    return error.message;
  }
  if (searching && status >= 500) {
    return 'Ombi could not search right now. It could not reach its movie '
        'database. Try again.';
  }
  return 'Ombi answered HTTP $status.';
}
