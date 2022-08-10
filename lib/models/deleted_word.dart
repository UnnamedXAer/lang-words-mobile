import 'package:objectbox/objectbox.dart';

@Entity()
class DeletedWord {
  DeletedWord({
    required this.id,
    required this.firebaseId,
    required this.firebaseUserId,
  });

  int id;
  String firebaseId;
  @Index()
  String firebaseUserId;
}
