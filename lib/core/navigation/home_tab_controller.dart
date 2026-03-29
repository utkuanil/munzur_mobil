import 'package:flutter/foundation.dart';

class HomeTabController {
  HomeTabController._();

  static final ValueNotifier<int> selectedTab = ValueNotifier<int>(0);

  static void goTo(int index) {
    selectedTab.value = index;
  }
}