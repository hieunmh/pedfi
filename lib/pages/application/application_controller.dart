import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pedfi/database/database_service.dart';
import 'package:pedfi/model/category_model.dart';
import 'package:pedfi/model/transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationController extends GetxController {
  final supabase = Supabase.instance.client;

  final DatabaseService databaseService = DatabaseService.instance;

  var currentMonth = DateFormat('MM-y').format(DateTime.now()).obs;

  final state = 0.obs;

  var userEmail = ''.obs;
  var userId = ''.obs;
  var joinDate = ''.obs;
  var isLoggedin = false.obs;
  var allCategory = <Category>[].obs;

  var incomeCategory = <Category>[].obs;
  var expenseCategory = <Category>[].obs;

  var allTransaction = <Transaction>[].obs;
  var filterTransaction = <Transaction>[].obs;

  var incomeTransaction = <Transaction>[].obs;
  var expenseTransaction = <Transaction>[].obs;

  var isOnline = false.obs;

  late final PageController pageController;

  final bottomNavBar = const [
    BottomNavigationBarItem(
      label: 'Home',
      icon: Icon(FontAwesomeIcons.list, size: 18)
    ),
    BottomNavigationBarItem(
      label: 'Report',
      icon: Icon(FontAwesomeIcons.chartSimple, size: 18)
    ),
    BottomNavigationBarItem(
      label: 'Calendar',
      icon: Icon(FontAwesomeIcons.calendar, size: 18)
    ),
    BottomNavigationBarItem(
      label: 'Profile',
      icon: Icon(FontAwesomeIcons.userAstronaut, size: 18)
    )

  ];

  @override
  void onInit() {
    super.onInit();
    getProfile();
    getAllCategory();
    pageController = PageController(initialPage: state.value);

  }


  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> getAllCategory() async {
    var x = 1;
    
    if (x > 0) {
      var res = await databaseService.getAllCategory();
      allCategory.value = res;

      incomeCategory.value = allCategory.where((item) => item.type == 'income').toList();
      expenseCategory.value = allCategory.where((item) => item.type == 'expense').toList();

    } else {
      final res = await supabase.from('Categories').select('*');
      allCategory.value = categoryFromJson(res);
      incomeCategory.value = allCategory.where((item) => item.type == 'income').toList();
      expenseCategory.value = allCategory.where((item) => item.type == 'expense').toList();
    }

  }

  Future<void> getProfile() async {
    var email = supabase.auth.currentUser?.email.toString();
    var createdAt = supabase.auth.currentUser?.createdAt.toString();
    var id = supabase.auth.currentUser?.id.toString();

    if (email == null || createdAt == null || id == null) {
      return;
    } else {
      userEmail.value = email;
      userId.value = id;
      joinDate.value = createdAt;
      isLoggedin.value = true;
    }
  }

  void handlePageChange(int index) {
    state.value = index;
  }

  void handleNavBarTap(int index) {
    pageController.jumpToPage(index);
  }
}
