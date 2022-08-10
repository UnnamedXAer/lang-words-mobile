import 'package:objectbox/objectbox.dart';

@Entity()
class ToggledIsKnownWord {
  ToggledIsKnownWord({
    required this.id,
    required this.firebaseId,
    required this.firebaseUserId,
    required this.toggledAt,
    required this.isKnown,
  });

  int id;
  @Index()
  String firebaseId;
  @Index()
  String firebaseUserId;
  DateTime toggledAt;
  bool isKnown;
}
