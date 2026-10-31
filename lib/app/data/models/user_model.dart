class User {
  late  String? name;
  late  String? photoUrl;
  late  Contact? contact;
  late String? dob;
  late String? gameUserName;
  late String? gender;
  late String? referralCode;
  late int? referralRewards;
  late int? referralCount;

  User({
    this.name,
    this.photoUrl,
    this.contact,
    this.dob,
    this.gameUserName,
    this.gender,
    this.referralCode,
    this.referralRewards,
    this.referralCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String? firstNonEmpty(List<dynamic> values) {
      for (final value in values) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return null;
    }

    return User(
      name: json['name'] as String?,
      photoUrl: firstNonEmpty([
        json['photoUrl'],
        json['photo_url'],
        json['avatar'],
        json['avatarUrl'],
        json['avatar_url'],
        json['profileImage'],
        json['profile_image'],
        json['imageUrl'],
        json['image_url'],
      ]),
      contact: json['contact'] != null ? Contact.fromJson(json['contact']) : null,
      dob: json['dob'] as String?,
      gameUserName: json['gameUserName'] as String?,
      gender: json['gender'] as String?,
      referralCode: json['referralCode'] as String?,
      referralRewards: json['referralRewards'] as int?,
      referralCount: json['referralCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'contact': contact?.toJson(),
      'dob': dob,
      'gameUserName': gameUserName,
      'gender': gender,
      'referralCode': referralCode,
      'referralRewards': referralRewards,
      'referralCount': referralCount,
    };
  }
}



class Contact {
  late ElectronicAddress? electronicAddress;
  late PhysicalAddress? physicalAddress;

  Contact({
    this.electronicAddress,
    this.physicalAddress,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      electronicAddress: json['electronicAddress'] != null
          ? ElectronicAddress.fromJson(json['electronicAddress'])
          : null,
      physicalAddress: json['physicalAddress'] != null
          ? PhysicalAddress.fromJson(json['physicalAddress'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'electronicAddress': electronicAddress?.toJson(),
      'physicalAddress': physicalAddress?.toJson(),
    };
  }
}

class ElectronicAddress {
  late String? emailId;
  late String? mobileNo;

  ElectronicAddress({
    this.emailId,
    this.mobileNo,
  });

  factory ElectronicAddress.fromJson(Map<String, dynamic> json) {
    return ElectronicAddress(
      emailId: json['emailId'] as String?,
      mobileNo: json['mobileNo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emailId': emailId,
      'mobileNo': mobileNo,
    };
  }
}



class PhysicalAddress {
  late String? country;
  late String? addressLine1;
  late String? addressLine2;
  late String? state;

  PhysicalAddress({
    this.country,
    this.addressLine1,
    this.addressLine2,
    this.state,
  });

  factory PhysicalAddress.fromJson(Map<String, dynamic> json) {
    return PhysicalAddress(
      country: json['Country'] as String?,
      addressLine1: json['addressLine1'] as String?,
      addressLine2: json['addressLine2'] as String?,
      state: json['state'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Country': country,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'state': state,
    };
  }
}
