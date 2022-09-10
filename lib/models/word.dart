import 'package:objectbox/objectbox.dart';

@Entity()
class Word {
  Word({
    required this.id,
    required this.firebaseId,
    required this.firebaseUserId,
    required this.acknowledgesCnt,
    required this.createAt,
    required this.known,
    required this.lastAcknowledgeAt,
    required this.translations,
    required this.word,
  });

  int id;
  @Index()
  String firebaseId;
  @Index()
  String firebaseUserId;
  String word;
  List<String> translations;
  DateTime createAt;
  DateTime? lastAcknowledgeAt;
  int acknowledgesCnt;
  bool known;

  Word.fromFirebase(
      this.firebaseId, String uid, Map<dynamic, dynamic> json)
      // TODO: is zero ok? should I expect it always filled?
      // "0" may be ok, when we try to modify it it will be "upserted" into objectbox.
      : id = json['id'] ?? 0, 
        firebaseUserId = uid,
        acknowledgesCnt = json['acknowledgesCnt'],
        createAt = DateTime.fromMillisecondsSinceEpoch(json['createAt']),
        known = json['known'],
        lastAcknowledgeAt = json['lastAcknowledgeAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json['lastAcknowledgeAt']),
        translations = List.castFrom<dynamic, String>(json['translations']),
        word = json['word'];

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'acknowledgesCnt': acknowledgesCnt,
      'createAt': createAt.millisecondsSinceEpoch,
      'known': known,
      'lastAcknowledgeAt': lastAcknowledgeAt?.millisecondsSinceEpoch,
      'translations': translations,
      'word': word,
    };
    return data;
  }

  Word copyWith({
    int? id,
    String? firebaseId,
    String? firebaseUserId,
    String? word,
    List<String>? translations,
    DateTime? createAt,
    DateTime? lastAcknowledgeAt,
    int? acknowledgesCnt,
    bool? known,
  }) {
    return Word(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      firebaseUserId: firebaseUserId ?? this.firebaseUserId,
      acknowledgesCnt: acknowledgesCnt ?? this.acknowledgesCnt,
      createAt: createAt ?? this.createAt,
      known: known ?? this.known,
      lastAcknowledgeAt: lastAcknowledgeAt ?? this.lastAcknowledgeAt,
      translations: translations ?? this.translations,
      word: word ?? this.word,
    );
  }
}
