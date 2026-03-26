import 'package:equatable/equatable.dart';

class MonsterModel extends Equatable {
  final String id;
  final String name;
  final int atk;
  final String type;
  final String emoji;
  final String? special;
  final bool flying;
  final String effect;
  final List<String> tags;

  const MonsterModel({
    required this.id,
    required this.name,
    required this.atk,
    required this.type,
    required this.emoji,
    this.special,
    required this.flying,
    required this.effect,
    this.tags = const [],
  });

  MonsterModel copyWith({
    String? id,
    String? name,
    int? atk,
    String? type,
    String? emoji,
    String? special,
    bool? flying,
    String? effect,
    List<String>? tags,
  }) {
    return MonsterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      atk: atk ?? this.atk,
      type: type ?? this.type,
      emoji: emoji ?? this.emoji,
      special: special ?? this.special,
      flying: flying ?? this.flying,
      effect: effect ?? this.effect,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, atk, type, emoji, special, flying, effect, tags];
}
