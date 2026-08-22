import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/repositories/model/transaction_history_model.dart';
import 'package:hash/core/utils/app_logger.dart';

part 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit() : super(TransactionInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> getTransactionHistory() async {
    emit(TransactionLoading());
    try {
      final liveUserId = Get.isRegistered<UserController>()
          ? Get.find<UserController>().userId.trim()
          : '';
      final userData = await remoteRepo.getUserFromPreferences();
      final userId = liveUserId.isNotEmpty
          ? liveUserId
          : userData?['id']?.toString().trim() ?? '';
      if (userId.isNotEmpty && userId != '0') {
        final response = await remoteRepo.getTransactionHistory(userId: userId);
        emit(TransactionLoaded(transactions: response));
      } else {
        emit(
          const TransactionError(
            message: 'Unauthorized access. Please login again.',
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Transaction history error: $e');
      emit(TransactionError(message: e.toString()));
    }
  }
}
