import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      final userData = await remoteRepo.getUserFromPreferences();
      if (userData != null) {
        final userId = userData['id']?.toString() ?? '0';
        final response = await remoteRepo.getTransactionHistory(userId: userId);
        emit(TransactionLoaded(transactions: response));
      } else {
        emit(const TransactionError(
          message: 'Unauthorized access. Please login again.',
        ));
      }
    } catch (e) {
      AppLogger.e('Transaction history error: $e');
      emit(TransactionError(message: e.toString()));
    }
  }
}
