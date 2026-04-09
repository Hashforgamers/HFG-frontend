part of 'get_vendor_passes_cubit.dart';

abstract class GetVendorPassesState extends Equatable {}

class GetVendorPassesInitial extends GetVendorPassesState {
  @override
  List<Object?> get props => [];
}

class GetVendorPassesLoading extends GetVendorPassesState {
  @override
  List<Object?> get props => [];
}

class GetVendorPassesLoaded extends GetVendorPassesState {
  final VendorPassesResponse vendorPasses;
  GetVendorPassesLoaded({required this.vendorPasses});
  @override
  List<Object?> get props => [vendorPasses];
}

class GetVendorPassesError extends GetVendorPassesState {
  final String message;
  GetVendorPassesError({required this.message});
  @override
  List<Object?> get props => [message];
}
