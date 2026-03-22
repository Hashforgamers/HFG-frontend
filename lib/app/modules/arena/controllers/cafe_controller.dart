import 'package:get/get.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';

class CybercafesController extends GetxController {
  final RemoteRepoInterface remoteRepo;
  static const Duration _cacheTtl = Duration(minutes: 15);
  static List<dynamic>? _cachedCybercafes;
  static DateTime? _cacheTime;
  Future<void>? _fetchRequest;

  CybercafesController({required this.remoteRepo});

  var cybercafes = [].obs; // Observable list to store cybercafes data
  var isLoading = false.obs; // Observable to manage loading state

  @override
  void onInit() {
    super.onInit();
    fetchCybercafes(); // Fetch cafes on initialization
  }

  Future<void> fetchCybercafes({bool forceRefresh = false}) {
    final cacheIsFresh =
        !forceRefresh &&
        _cachedCybercafes != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheTtl;

    if (cacheIsFresh) {
      cybercafes.assignAll(_cachedCybercafes!);
      return Future.value();
    }

    final inFlight = _fetchRequest;
    if (inFlight != null) return inFlight;

    final request = _loadCybercafes();
    _fetchRequest = request;
    return request.whenComplete(() {
      if (identical(_fetchRequest, request)) {
        _fetchRequest = null;
      }
    });
  }

  Future<void> _loadCybercafes() async {
    isLoading.value = true;
    try {
      final cafes = await remoteRepo.fetchCybercafes();
      cybercafes.assignAll(cafes);
      _cachedCybercafes = List<dynamic>.from(cafes);
      _cacheTime = DateTime.now();
    } catch (e) {
      if (_cachedCybercafes != null) {
        cybercafes.assignAll(_cachedCybercafes!);
      } else {
        Get.snackbar('Error', 'Failed to fetch data: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }
}
