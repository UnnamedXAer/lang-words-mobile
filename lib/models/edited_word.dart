import 'package:objectbox/objectbox.dart';

@Entity()
class EditedWord {
  EditedWord({
    required this.id,
    required this.firebaseId,
    required this.firebaseUserId,
    required this.editedAt,
  });

  @Id(assignable: true)
  int id;
  @Unique(onConflict: ConflictStrategy.replace)
  String firebaseId;
  @Index()
  String firebaseUserId;
  DateTime editedAt;
}
