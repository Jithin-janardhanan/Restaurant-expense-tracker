class Waiter {
  String id;
  String name;
  String nickname;

  Waiter({
    required this.id,
    required this.name,
    required this.nickname,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
    };
  }

  factory Waiter.fromMap(Map<String, dynamic> map) {
    return Waiter(
      id: map['id'],
      name: map['name'],
      nickname: map['nickname'],
    );
  }
}
