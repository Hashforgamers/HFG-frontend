import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/model/purchase_pass_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'purchase_pass_state.dart';

class PurchasePassCubit extends Cubit<PurchasePassState> {
  PurchasePassCubit() : super(PurchasePassInitial());

  final apiClient = locator<RemoteRepoInterface>();

  Future<void> makePurchasePassPayment({required PurchasePassModel purchasePassModel}) async {
    emit(PurchasePassLoading());
    try {
      await apiClient.makePurchasePassPayment(purchasePassModel: purchasePassModel);
      emit(PurchasePassSuccess(confirmationMessage: "Pass purchased successfully."));
    } catch (e) {
      emit(PurchasePassError(errorMessage: e.toString()));
    }
  }
}
