import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'create_offer_state.dart';

class CreateOfferCubit extends Cubit<CreateOfferState> {
  CreateOfferCubit() : super(CreateOfferInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> createOffer(int discountPercentage, String userId) async {
    emit(CreateOfferLoading());
    try {
      final response = await remoteRepo.createOffer(
        discountPercentage: discountPercentage,
        userId: userId,
      );
      if (response.voucherCode.isNotEmpty) {
        emit(CreateOfferSuccess());
      } else {
        emit(CreateOfferFailure(message: response.message));
      }
    } catch (e) {
      emit(CreateOfferFailure(message: e.toString()));
    }
  }
}
