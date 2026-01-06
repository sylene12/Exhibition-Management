import 'package:cloud_firestore/cloud_firestore.dart';

/// User roles in the system
enum UserRole { guest, exhibitor, organizer, admin }

/// Application/Booking status
enum ApplicationStatus { pending, approved, rejected, cancelled }

/// Exhibition status
enum ExhibitionStatus { upcoming, ongoing, completed, cancelled }

/// Booth status
enum BoothStatus { available, booked, pending, unavailable }

/// User Model
/// Represents a user in the system with their role and details
class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? companyName;
  final String? phoneNumber;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.companyName,
    this.phoneNumber,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.guest,
      ),
      companyName: data['companyName'],
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'companyName': companyName,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Exhibition Model
/// Represents an exhibition event
class ExhibitionModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String organizerId;
  final String? floorPlanUrl;
  final ExhibitionStatus status;
  final bool isPublished;
  final DateTime createdAt;

  ExhibitionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.organizerId,
    this.floorPlanUrl,
    required this.status,
    required this.isPublished,
    required this.createdAt,
  });

  factory ExhibitionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExhibitionModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      organizerId: data['organizerId'] ?? '',
      floorPlanUrl: data['floorPlanUrl'],
      status: ExhibitionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ExhibitionStatus.upcoming,
      ),
      isPublished: data['isPublished'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'organizerId': organizerId,
      'floorPlanUrl': floorPlanUrl,
      'status': status.name,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ExhibitionStatus get computedStatus {
    // Manual override
    if (status == ExhibitionStatus.cancelled) {
      return ExhibitionStatus.cancelled;
    }

    final now = DateTime.now();

    if (now.isBefore(startDate)) {
      return ExhibitionStatus.upcoming;
    } else if (now.isAfter(endDate)) {
      return ExhibitionStatus.completed;
    } else {
      return ExhibitionStatus.ongoing;
    }
  }

}



/// Booth Model
/// Represents a booth in an exhibition
class BoothModel {
  final String id;
  final String exhibitionId;
  final String boothNumber;
  final String type;
  final double sizeSqm;
  final double price;
  final BoothStatus status;
  final Map<String, bool> amenities; // wifi, power, etc.
  final double? xCoordinate;
  final double? yCoordinate;

  BoothModel({
    required this.id,
    required this.exhibitionId,
    required this.boothNumber,
    required this.type,
    required this.sizeSqm,
    required this.price,
    required this.status,
    required this.amenities,
    this.xCoordinate,
    this.yCoordinate,
  });

  factory BoothModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BoothModel(
      id: doc.id,
      exhibitionId: data['exhibitionId'] ?? '',
      boothNumber: data['boothNumber'] ?? '',
      type: data['type'] ?? '',
      sizeSqm: (data['sizeSqm'] ?? 0).toDouble(),
      price: (data['price'] ?? 0).toDouble(),
      status: BoothStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BoothStatus.available,
      ),
      amenities: Map<String, bool>.from(data['amenities'] ?? {}),
      xCoordinate: data['xCoordinate']?.toDouble(),
      yCoordinate: data['yCoordinate']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'exhibitionId': exhibitionId,
      'boothNumber': boothNumber,
      'type': type,
      'sizeSqm': sizeSqm,
      'price': price,
      'status': status.name,
      'amenities': amenities,
      'xCoordinate': xCoordinate,
      'yCoordinate': yCoordinate,
    };
  }
}

/// Booking/Application Model
/// Represents an exhibitor's booth booking application
class BookingModel {
  final String id;
  final String exhibitorId;
  final String exhibitionId;
  final List<String> boothIds;
  final String companyName;
  final String companyDescription;
  final String exhibitProfile;
  final Map<String, bool> additionalItems; // furniture, promotional spots, etc.
  final ApplicationStatus status;
  final String? rejectionReason;
  final DateTime applicationDate;
  final DateTime? approvalDate;
  final DateTime? preferredExhibitionDate;
  final double totalAmount;


  BookingModel({
    required this.id,
    required this.exhibitorId,
    required this.exhibitionId,
    required this.boothIds,
    required this.companyName,
    required this.companyDescription,
    required this.exhibitProfile,
    required this.additionalItems,
    required this.totalAmount,
    required this.status,
    this.rejectionReason,
    required this.applicationDate,
    this.preferredExhibitionDate,
    this.approvalDate,

  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      exhibitorId: data['exhibitorId'] ?? '',
      exhibitionId: data['exhibitionId'] ?? '',
      boothIds: List<String>.from(data['boothIds'] ?? []),
      companyName: data['companyName'] ?? '',
      companyDescription: data['companyDescription'] ?? '',
      exhibitProfile: data['exhibitProfile'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      additionalItems: Map<String, bool>.from(data['additionalItems'] ?? {}),
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      rejectionReason: data['rejectionReason'],
      preferredExhibitionDate: data['preferredExhibitionDate'] != null
          ? (data['preferredExhibitionDate'] as Timestamp).toDate()
          : null,
      applicationDate: (data['applicationDate'] as Timestamp).toDate(),
      approvalDate: data['approvalDate'] != null
          ? (data['approvalDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'exhibitorId': exhibitorId,
      'exhibitionId': exhibitionId,
      'boothIds': boothIds,
      'companyName': companyName,
      'companyDescription': companyDescription,
      'exhibitProfile': exhibitProfile,
      'additionalItems': additionalItems,
      'status': status.name,
      'totalAmount': totalAmount,
      'rejectionReason': rejectionReason,
      'applicationDate': Timestamp.fromDate(applicationDate),
      'preferredExhibitionDate': preferredExhibitionDate != null
          ? Timestamp.fromDate(preferredExhibitionDate!)
          : null,
      'approvalDate':
          approvalDate != null ? Timestamp.fromDate(approvalDate!) : null,
    };
  }
}