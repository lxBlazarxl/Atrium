/// What a request or a search result is about.
enum OmbiMediaKind { movie, tv, music }

/// Where a request stands, as a row shows it.
enum OmbiRequestStatus { pending, processing, available, denied }

/// The filters the requests screen offers, one per v2 list route.
enum OmbiRequestFilter { pending, processing, available, denied, all }

/// Which seasons a TV request asks for.
enum OmbiTvSeasons { all, first, latest }

/// One request as the screens use it, whatever kind it is.
class OmbiRequest {
  const OmbiRequest({
    required this.id,
    required this.kind,
    required this.title,
    required this.status,
    this.year,
    this.posterUrl,
    this.requestedBy,
    this.requestedAt,
    this.deniedReason,
  });

  /// What approve, deny and delete act on. For TV this is the child
  /// request's id, one per requester, not the show's.
  final int id;
  final OmbiMediaKind kind;
  final String title;
  final OmbiRequestStatus status;
  final int? year;
  final String? posterUrl;
  final String? requestedBy;
  final DateTime? requestedAt;
  final String? deniedReason;
}

/// A page of requests and how many there are in all.
class OmbiRequestPage {
  const OmbiRequestPage({required this.items, required this.total});

  final List<OmbiRequest> items;
  final int total;
}

/// Request totals across every kind, from `api/v1/Request/count`.
class OmbiCounts {
  const OmbiCounts({
    this.pending = 0,
    this.approved = 0,
    this.available = 0,
    this.denied = 0,
  });

  final int pending;
  final int approved;
  final int available;
  final int denied;

  int get total => pending + approved + available + denied;
}

/// A movie or a show that search found.
class OmbiSearchHit {
  const OmbiSearchHit({
    required this.tmdbId,
    required this.kind,
    required this.title,
    this.posterUrl,
    this.overview,
  });

  final int tmdbId;
  final OmbiMediaKind kind;
  final String title;
  final String? posterUrl;
  final String? overview;
}

/// Where a title stands in Ombi, read from its detail page.
class OmbiTitleState {
  const OmbiTitleState({
    this.requested = false,
    this.approved = false,
    this.available = false,
    this.partlyAvailable = false,
    this.denied = false,
    this.deniedReason,
  });

  final bool requested;
  final bool approved;
  final bool available;

  /// Some seasons of a show are there. It can still take a request.
  final bool partlyAvailable;
  final bool denied;
  final String? deniedReason;

  bool get canRequest => !available && !requested;
}
