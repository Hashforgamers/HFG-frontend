abstract class RemoteRepoInterface {


  Future<Map<String, dynamic>?> checkUserExistsInAPI(String fid);
  Future<void> saveUserToPreferences(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserFromPreferences();
  Future<void> clearUserFromPreferences();

}
