import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserNotifier extends StateNotifier<String?> {
  UserNotifier() : super(Hive.box('settings').get('userName') as String?);

  void setName(String name) {
    Hive.box('settings').put('userName', name);
    state = name;
  }

  void clearName() {
    Hive.box('settings').delete('userName');
    state = null;
  }
}

final userNameProvider = StateNotifierProvider<UserNotifier, String?>((ref) {
  return UserNotifier();
});

final greetingProvider = Provider<String>((ref) {
  final name = ref.watch(userNameProvider);
  final hour = DateTime.now().hour;

  String greeting;
  String emoji;

  if (hour < 6) {
    greeting = 'Good Night';
    emoji = '\u{1F319}';
  } else if (hour < 12) {
    greeting = 'Good Morning';
    emoji = '\u{2600}\u{FE0F}';
  } else if (hour < 17) {
    greeting = 'Good Afternoon';
    emoji = '\u{1F324}\u{FE0F}';
  } else if (hour < 21) {
    greeting = 'Good Evening';
    emoji = '\u{1F305}';
  } else {
    greeting = 'Good Night';
    emoji = '\u{1F319}';
  }

  if (name != null && name.isNotEmpty) {
    return '$emoji $greeting, $name!';
  }
  return '$emoji $greeting!';
});
