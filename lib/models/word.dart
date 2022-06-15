class Word {
  Word({
    required this.id,
    required this.acknowledgesCnt,
    required this.createAt,
    required this.known,
    required this.lastAcknowledgeAt,
    required this.translations,
    required this.word,
  });
  final String id;
  final String word;
  final List<String> translations;
  final DateTime createAt;
  final DateTime? lastAcknowledgeAt;
  final int acknowledgesCnt;
  final bool known;

  Word.fromFirebase(String id, Map<String, dynamic> json)
      : this.id = id,
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
      'createAt': createAt.millisecond,
      'known': known,
      'lastAcknowledgeAt': lastAcknowledgeAt?.millisecond,
      'translations': translations,
      'word': word,
    };
    return data;
  }
}
