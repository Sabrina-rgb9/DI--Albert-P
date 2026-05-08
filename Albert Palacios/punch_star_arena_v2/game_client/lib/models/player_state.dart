class PlayerState {
  PlayerState({
    required this.id,
    required this.name,
    required this.color,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.hp,
    required this.facing,
    required this.isAttacking,
    required this.isAlive,
  });

  final String id;
  final String name;
  final String color;
  final double x;
  final double y;
  final double vx;
  final double vy;
  final int hp;
  final int facing;
  final bool isAttacking;
  final bool isAlive;

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    return PlayerState(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Player',
      color: json['color'] as String? ?? 'red',
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      vx: (json['vx'] as num? ?? 0).toDouble(),
      vy: (json['vy'] as num? ?? 0).toDouble(),
      hp: json['hp'] as int? ?? 100,
      facing: json['facing'] as int? ?? 1,
      isAttacking: json['isAttacking'] as bool? ?? false,
      isAlive: json['isAlive'] as bool? ?? true,
    );
  }
}
