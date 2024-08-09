class User {
  Contact contact;
  String dob;
  String gameUserName;
  String gender;
  String name;

  User({
    required this.contact,
    required this.dob,
    required this.gameUserName,
    required this.gender,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      contact: Contact.fromJson(json['contact']),
      dob: json['dob'],
      gameUserName: json['gameUserName'],
      gender: json['gender'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact': contact.toJson(),
      'dob': dob,
      'gameUserName': gameUserName,
      'gender': gender,
      'name': name,
    };
  }
}

class Contact {
  ElectronicAddress electronicAddress;
  PhysicalAddress physicalAddress;

  Contact({
    required this.electronicAddress,
    required this.physicalAddress,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      electronicAddress: ElectronicAddress.fromJson(json['electronicAddress']),
      physicalAddress: PhysicalAddress.fromJson(json['physicalAddress']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'electronicAddress': electronicAddress.toJson(),
      'physicalAddress': physicalAddress.toJson(),
    };
  }
}

class ElectronicAddress {
  String emailId;
  String mobileNo;

  ElectronicAddress({
    required this.emailId,
    required this.mobileNo,
  });

  factory ElectronicAddress.fromJson(Map<String, dynamic> json) {
    return ElectronicAddress(
      emailId: json['emailId'],
      mobileNo: json['mobileNo'] ?? '',
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
  String country;
  String addressLine1;
  String addressLine2;
  String state;

  PhysicalAddress({
    required this.country,
    required this.addressLine1,
    required this.addressLine2,
    required this.state,
  });

  factory PhysicalAddress.fromJson(Map<String, dynamic> json) {
    return PhysicalAddress(
      country: json['Country'],
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      state: json['state'],
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
