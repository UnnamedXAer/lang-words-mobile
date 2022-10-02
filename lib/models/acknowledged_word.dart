import 'package:objectbox/objectbox.dart';

@Entity()
class AcknowledgeWord {
  AcknowledgeWord({
    required this.id,
    required this.firebaseId,
    required this.firebaseUserId,
    required this.count,
    required this.lastAcknowledgedAt,
  });

  @Id(assignable: true)
  int id;
  @Unique(onConflict: ConflictStrategy.replace)
  String firebaseId;
  String firebaseUserId;
  int count;
  DateTime lastAcknowledgedAt;
}
