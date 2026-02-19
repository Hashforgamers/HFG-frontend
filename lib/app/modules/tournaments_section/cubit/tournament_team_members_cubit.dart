import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'tournament_team_members_state.dart';

class TournamentTeamMembersCubit extends Cubit<TournamentTeamMembersState> {
  TournamentTeamMembersCubit() : super(TournamentTeamMembersInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> fetchTeamMembers({
    required String eventId,
    required String teamId,
  }) async {
    emit(TournamentTeamMembersLoading());
    try {
      final members = await remoteRepo.fetchEventTeamMembers(
        eventId: eventId,
        teamId: teamId,
      );
      emit(TournamentTeamMembersLoaded(teamId: teamId, members: members));
    } catch (e) {
      emit(TournamentTeamMembersError(message: _cleanError(e)));
    }
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }
}
