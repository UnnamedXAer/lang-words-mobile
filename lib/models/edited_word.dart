import 'package:objectbox/objectbox.dart';

@Entity()
class EditedWord {
  EditedWord({
    required this.id,
    required this.firebaseId,
    required this.firebaseUserId,
    required this.editedAt,
  });

  int id;
  String firebaseId;
  @Index()
  String firebaseUserId;
  DateTime editedAt;
}
