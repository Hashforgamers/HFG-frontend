import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/game_pass/model/vendor_passes_response.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'get_vendor_passes_state.dart';

class GetVendorPassesCubit extends Cubit<GetVendorPassesState> {
  GetVendorPassesCubit() : super(GetVendorPassesInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> getVendorPasses({required String vendorId}) async {
    emit(GetVendorPassesLoading());
    try {
      final response = await remoteRepo.getAllAvailablePasses(
        vendorId: vendorId,
      );
      emit(GetVendorPassesLoaded(vendorPasses: response));
    } catch (e) {
      emit(GetVendorPassesError(message: 'Failed to load vendor passes: $e'));
    }
  }
}
