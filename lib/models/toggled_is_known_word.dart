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

  @Id(assignable: true)
  int id;
  @Unique(onConflict: ConflictStrategy.replace)
  String firebaseId;
  @Index()
  String firebaseUserId;
  DateTime toggledAt;
  bool isKnown;
}
