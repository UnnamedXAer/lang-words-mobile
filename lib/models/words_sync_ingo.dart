import 'package:objectbox/objectbox.dart';

@Entity()
class WordsSyncInfo {
  WordsSyncInfo({
    required this.id,
    required this.firebaseUserId,
    required this.lastSyncAt,
  });

  int id;
  @Unique(onConflict: ConflictStrategy.replace)
  String firebaseUserId;
  DateTime lastSyncAt;
}
