import 'dto.dart';

class Comment implements DTO {
  Comment({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.author,
    required this.commentText,
    required this.creationTimestamp,
  });

  /// generate Comment object from a json document
  factory Comment.fromJson(dynamic json) {
    return Comment(
        id: json["_id"] as String,
        userId: json["userId"] as String,
        eventId: json["eventId"] as String,
        author: json["author"] as String,
        commentText: json["commentText"] as String,
        creationTimestamp: json["creationTimestamp"] as int);
  }

  String id;
  String userId;
  String eventId;
  String author;
  String commentText;
  int creationTimestamp;

  /// sort after creationTimestamp ascending
  int compareTo(Comment commentB) {
    if (creationTimestamp < commentB.creationTimestamp) {
      return -1;
    } else if (creationTimestamp > commentB.creationTimestamp) {
      return 1;
    } else {
      return author.compareTo(commentB.author);
    }
  }
}
