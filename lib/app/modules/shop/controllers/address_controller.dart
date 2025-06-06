import 'package:get/get.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

class AddressController extends GetxController {
  var addresses = [].obs;
  var activeAddress = {}.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  final _remoteRepo = locator<RemoteRepoInterface>();

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
    fetchActiveAddress();
  }

  Future<void> fetchAddresses() async {
    try {
      isLoading.value = true;
      final addressList = await _remoteRepo.fetchAddresses();
      addresses.value = addressList;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchActiveAddress() async {
    try {
      final address = await _remoteRepo.fetchActiveAddress();
      activeAddress.value = address;
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> addAddress(Map<String, dynamic> address) async {
    try {
      await _remoteRepo.addAddress(address);
      await fetchAddresses();
      await fetchActiveAddress();
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }
}

class Address {
  String? addressLine1;
  String? addressLine2;
  String? pincode;
  String? state;
  String? country;
  String? addressType;
  bool? isActive;

  Address({this.addressLine1, this.addressLine2, this.pincode, this.state, this.country, this.addressType, this.isActive});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      pincode: json['pincode'],
      state: json['State'],
      country: json['Country'],
      addressType: json['address_type'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'pincode': pincode,
      'State': state,
      'Country': country,
      'address_type': addressType,
      'is_active': isActive,
    };
  }
}