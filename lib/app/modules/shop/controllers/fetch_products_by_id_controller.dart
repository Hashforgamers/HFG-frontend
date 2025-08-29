import 'package:get/get.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import '../products_model.dart';

class GetProductByIdController extends GetxController {
  var product = Rxn<Product>();
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  final _remoteRepo = locator<RemoteRepoInterface>();

  Future<void> fetchProductById(String productId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final responseData = await _remoteRepo.fetchProductById(productId);
      product.value = Product.fromJson(responseData);
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
