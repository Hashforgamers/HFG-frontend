enum TournamentStatus {
  draft,
  validationFailed,
  ready,
  published,
  registrationOpen,
  registrationClosed,
  checkInOpen,
  live,
  resultPending,
  disputed,
  completed,
  cancelled,
  unknown,
}

TournamentStatus tournamentStatusFrom(String? raw) {
  switch (_normalized(raw)) {
    case 'draft':
      return TournamentStatus.draft;
    case 'validation_failed':
      return TournamentStatus.validationFailed;
    case 'ready':
      return TournamentStatus.ready;
    case 'published':
      return TournamentStatus.published;
    case 'registration_open':
      return TournamentStatus.registrationOpen;
    case 'registration_closed':
      return TournamentStatus.registrationClosed;
    case 'check_in_open':
      return TournamentStatus.checkInOpen;
    case 'live':
    case 'in_progress':
      return TournamentStatus.live;
    case 'result_pending':
    case 'results_pending':
      return TournamentStatus.resultPending;
    case 'disputed':
      return TournamentStatus.disputed;
    case 'completed':
      return TournamentStatus.completed;
    case 'cancelled':
    case 'canceled':
      return TournamentStatus.cancelled;
    default:
      return TournamentStatus.unknown;
  }
}

enum RegistrationStatus {
  pending,
  paymentPending,
  paymentFailed,
  confirmed,
  waitlisted,
  cancelled,
  rejected,
  refundPending,
  refunded,
  unknown,
}

RegistrationStatus registrationStatusFrom(String? raw) {
  switch (_normalized(raw)) {
    case 'pending':
      return RegistrationStatus.pending;
    case 'pending_payment':
    case 'payment_pending':
      return RegistrationStatus.paymentPending;
    case 'payment_failed':
    case 'failed':
      return RegistrationStatus.paymentFailed;
    case 'confirmed':
      return RegistrationStatus.confirmed;
    case 'waitlisted':
      return RegistrationStatus.waitlisted;
    case 'cancelled':
    case 'canceled':
      return RegistrationStatus.cancelled;
    case 'rejected':
      return RegistrationStatus.rejected;
    case 'refund_pending':
      return RegistrationStatus.refundPending;
    case 'refunded':
      return RegistrationStatus.refunded;
    default:
      return RegistrationStatus.unknown;
  }
}

enum TournamentRole { player, captain, verifiedHost, suspendedHost, admin }

class TournamentCapabilities {
  final Set<TournamentRole> roles;
  final bool ownsTournament;
  final bool isRegistered;
  final bool isParticipant;

  const TournamentCapabilities({
    this.roles = const {TournamentRole.player},
    this.ownsTournament = false,
    this.isRegistered = false,
    this.isParticipant = false,
  });

  bool get isSuspended => roles.contains(TournamentRole.suspendedHost);
  bool get isAdmin => roles.contains(TournamentRole.admin);
  bool get isVerifiedHost => roles.contains(TournamentRole.verifiedHost);
  bool get isCaptain => roles.contains(TournamentRole.captain);

  bool get canCreateTournament => !isSuspended;

  bool canCreateTournamentWithFee({required bool paid}) =>
      !isSuspended && (!paid || isVerifiedHost || isAdmin);

  bool canEditTournament(TournamentStatus status) =>
      !isSuspended &&
      (isAdmin || (ownsTournament && status == TournamentStatus.draft));

  bool canPublishTournament(TournamentStatus status) =>
      !isSuspended &&
      (isAdmin ||
          (ownsTournament &&
              isVerifiedHost &&
              {
                TournamentStatus.draft,
                TournamentStatus.ready,
              }.contains(status)));

  bool canManageParticipants(TournamentStatus status) =>
      !isSuspended &&
      (isAdmin ||
          (ownsTournament &&
              !{
                TournamentStatus.completed,
                TournamentStatus.cancelled,
              }.contains(status)));

  bool canManageMatch(TournamentStatus status) =>
      !isSuspended &&
      (isAdmin ||
          (ownsTournament &&
              {
                TournamentStatus.checkInOpen,
                TournamentStatus.live,
                TournamentStatus.resultPending,
                TournamentStatus.disputed,
              }.contains(status)));

  bool canSubmitResult(TournamentStatus status) =>
      isParticipant &&
      {TournamentStatus.live, TournamentStatus.resultPending}.contains(status);

  bool canRaiseDispute(TournamentStatus status) =>
      isParticipant &&
      {
        TournamentStatus.resultPending,
        TournamentStatus.disputed,
      }.contains(status);

  bool canCompleteTournament(TournamentStatus status) =>
      !isSuspended &&
      (isAdmin || (ownsTournament && status == TournamentStatus.resultPending));

  bool canReviewTournament(TournamentStatus status) =>
      isRegistered && status == TournamentStatus.completed;
}

class TournamentSchedule {
  final DateTime? registrationOpenAt;
  final DateTime? registrationCloseAt;
  final DateTime? rosterLockAt;
  final DateTime? checkInOpenAt;
  final DateTime? checkInCloseAt;
  final DateTime? tournamentStartAt;
  final DateTime? tournamentEndAt;

  const TournamentSchedule({
    this.registrationOpenAt,
    this.registrationCloseAt,
    this.rosterLockAt,
    this.checkInOpenAt,
    this.checkInCloseAt,
    this.tournamentStartAt,
    this.tournamentEndAt,
  });

  Map<String, String> validate() {
    final errors = <String, String>{};
    final open = registrationOpenAt;
    final close = registrationCloseAt;
    final start = tournamentStartAt;
    if (open != null && close != null && !close.isAfter(open)) {
      errors['registrationCloseAt'] = 'Registration must close after it opens.';
    }
    if (close != null && start != null && start.isBefore(close)) {
      errors['tournamentStartAt'] =
          'Tournament must start after registration closes.';
    }
    if (rosterLockAt != null && start != null && rosterLockAt!.isAfter(start)) {
      errors['rosterLockAt'] = 'Roster lock cannot be after tournament start.';
    }
    if (checkInOpenAt != null &&
        checkInCloseAt != null &&
        !checkInCloseAt!.isAfter(checkInOpenAt!)) {
      errors['checkInCloseAt'] = 'Check-in must close after it opens.';
    }
    if (checkInCloseAt != null &&
        start != null &&
        checkInCloseAt!.isAfter(start)) {
      errors['checkInCloseAt'] =
          'Check-in cannot close after tournament start.';
    }
    if (tournamentEndAt != null &&
        start != null &&
        !tournamentEndAt!.isAfter(start)) {
      errors['tournamentEndAt'] =
          'Tournament end must be after tournament start.';
    }
    return errors;
  }
}

String tournamentErrorMessage(String? code, {String? fallback}) {
  const messages = <String, String>{
    'AUTH_REQUIRED': 'Please sign in to continue.',
    'TOKEN_EXPIRED': 'Your session expired. Please sign in again.',
    'FORBIDDEN': 'You do not have permission to do that.',
    'HOST_NOT_VERIFIED': 'Host verification is required.',
    'HOST_SUSPENDED': 'Hosting is unavailable while this account is suspended.',
    'TOURNAMENT_NOT_FOUND': 'This tournament is no longer available.',
    'INVALID_TOURNAMENT_STATE':
        'This action is not available at the current tournament stage.',
    'REGISTRATION_NOT_OPEN': 'Registration has not opened yet.',
    'REGISTRATION_CLOSED': 'Registration is closed.',
    'CAPACITY_REACHED': 'This tournament is full.',
    'ALREADY_REGISTERED': 'You are already registered.',
    'INVALID_INVITE_CODE': 'The invite code is invalid or expired.',
    'PAYMENT_REQUIRED': 'Payment is required to confirm your registration.',
    'PAYMENT_PENDING': 'Your payment is still being confirmed.',
    'PAYMENT_VERIFICATION_FAILED':
        'Payment could not be verified. You have not been charged again.',
    'TEAM_INCOMPLETE': 'Complete the required roster before continuing.',
    'ALREADY_IN_TOURNAMENT_TEAM':
        'You already belong to a team in this tournament.',
    'ROSTER_LOCKED': 'The roster is locked and can no longer be changed.',
    'CHECK_IN_NOT_OPEN': 'Check-in is not open.',
  };
  return messages[code?.trim().toUpperCase()] ??
      fallback ??
      'Something went wrong. Please try again.';
}

String _normalized(String? raw) =>
    (raw ?? '').trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
