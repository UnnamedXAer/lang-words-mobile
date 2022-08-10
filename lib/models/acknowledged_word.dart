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

  int id;
  String firebaseId;
  String firebaseUserId;
  int count;
  DateTime lastAcknowledgedAt;
}
