/// Payloads shaped the way Ombi v4.53 sends them.
///
/// Field names come from Ombi's OpenAPI spec and the payloads checked against
/// a live server; the live run swaps in captured bodies with personal details
/// removed. Nothing here is a real user.
library;

const Map<String, dynamic> aliceJson = <String, dynamic>{
  'id': 'user-1',
  'userName': 'alice',
  'alias': null,
  'userAlias': 'alice',
};

Map<String, dynamic> movieRequestJson({
  int id = 11,
  bool approved = false,
  bool available = false,
  bool denied = false,
  String? deniedReason,
  String requestedDate = '2026-09-18T10:15:00',
}) =>
    <String, dynamic>{
      'id': id,
      'title': 'Arrival',
      'theMovieDbId': 329865,
      'posterPath': '/x2FJsf1ElAgr63Y3PNPtJrcmpoe.jpg',
      'releaseDate': '2016-11-10T00:00:00',
      'requestedDate': requestedDate,
      'approved': approved,
      'available': available,
      'denied': denied,
      'deniedReason': deniedReason,
      'requestedByAlias': null,
      'requestedUser': aliceJson,
      'canApprove': true,
    };

Map<String, dynamic> childRequestJson({
  int id = 21,
  bool approved = false,
  String requestedDate = '2026-09-17T08:00:00',
}) =>
    <String, dynamic>{
      'id': id,
      'title': null,
      'approved': approved,
      'available': false,
      'denied': false,
      'deniedReason': null,
      'requestedDate': requestedDate,
      'requestedByAlias': null,
      'requestedUser': aliceJson,
      'releaseYear': '2022-02-18T00:00:00',
      'parentRequest': <String, dynamic>{
        'id': 3,
        'title': 'Severance',
        'posterPath': '/pPHpeI2X1qEd1CS1SeyrdhZ4qnT.jpg',
        'releaseDate': '2022-02-18T00:00:00',
      },
      'seasonRequests': <Object>[],
    };

Map<String, dynamic> albumRequestJson({int id = 31}) => <String, dynamic>{
      'id': id,
      'title': 'Blue Train',
      'artistName': 'John Coltrane',
      'cover': 'https://coverartarchive.org/release/abc/front-250.jpg',
      'releaseDate': '1957-01-01T00:00:00',
      'requestedDate': '2026-09-16T12:00:00',
      'approved': true,
      'available': false,
      'denied': false,
      'deniedReason': null,
      'requestedByAlias': null,
      'requestedUser': aliceJson,
    };

/// A v2 list response.
Map<String, dynamic> pageJson(List<Map<String, dynamic>> items, {int? total}) =>
    <String, dynamic>{'collection': items, 'total': total ?? items.length};

const Map<String, dynamic> countsJson = <String, dynamic>{
  'pending': 2,
  'approved': 1,
  'available': 4,
  'denied': 1,
};

const List<Map<String, dynamic>> searchJson = <Map<String, dynamic>>[
  <String, dynamic>{
    'id': '329865',
    'mediaType': 'movie',
    'title': 'Arrival',
    'poster': '/x2FJsf1ElAgr63Y3PNPtJrcmpoe.jpg',
    'overview': 'A linguist is recruited to talk to visitors.',
  },
  <String, dynamic>{
    'id': '95396',
    'mediaType': 'tv',
    'title': 'Severance',
    'poster': '/pPHpeI2X1qEd1CS1SeyrdhZ4qnT.jpg',
    'overview': 'Mark leads a team of office workers.',
  },
  <String, dynamic>{
    'id': '9273',
    'mediaType': 'person',
    'title': 'Amy Adams',
    'poster': null,
    'overview': null,
  },
];

Map<String, dynamic> movieDetailJson({
  bool requested = false,
  bool approved = false,
  bool available = false,
  bool denied = false,
  String? deniedReason,
}) =>
    <String, dynamic>{
      'id': 329865,
      'theMovieDbId': '329865',
      'title': 'Arrival',
      'requested': requested,
      'approved': approved,
      'available': available,
      'denied': denied,
      'deniedReason': deniedReason,
    };

Map<String, dynamic> tvDetailJson({
  bool requested = false,
  bool partlyAvailable = false,
  bool fullyAvailable = false,
}) =>
    <String, dynamic>{
      'id': 95396,
      'theMovieDbId': '95396',
      'title': 'Severance',
      'requested': requested,
      'approved': false,
      'available': false,
      'partlyAvailable': partlyAvailable,
      'fullyAvailable': fullyAvailable,
      'denied': false,
      'deniedReason': null,
    };

/// A `RequestEngineResult` that worked.
Map<String, dynamic> engineOk({int requestId = 11}) => <String, dynamic>{
      'result': true,
      'message': null,
      'isError': false,
      'errorMessage': null,
      'requestId': requestId,
    };

/// A `RequestEngineResult` Ombi sends with HTTP 200 when it said no.
Map<String, dynamic> engineError(String message) => <String, dynamic>{
      'result': false,
      'message': null,
      'isError': true,
      'errorMessage': message,
      'requestId': 0,
    };
