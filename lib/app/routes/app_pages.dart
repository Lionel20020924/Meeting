import 'package:get/get.dart';

import '../modules/login/login_binding.dart';
import '../modules/login/login_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/meetings/meetings_binding.dart';
import '../modules/meetings/meetings_view.dart';
import '../modules/record/record_binding.dart';
import '../modules/record/record_view.dart';
import '../modules/meeting_detail/meeting_detail_binding.dart';
import '../modules/meeting_detail/meeting_detail_view.dart';
import '../modules/summary/summary_binding.dart';
import '../modules/summary/summary_view.dart';
import '../modules/profile/profile_binding.dart';
import '../modules/profile/profile_view.dart';
import '../modules/post_recording/post_recording_binding.dart';
import '../modules/post_recording/post_recording_view.dart';
import '../middleware/auth_middleware.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.MEETINGS,
      page: () => const MeetingsView(),
      binding: MeetingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.RECORD,
      page: () => const RecordView(),
      binding: RecordBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.MEETING_DETAIL,
      page: () => const MeetingDetailView(),
      binding: MeetingDetailBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.SUMMARY,
      page: () => const SummaryView(),
      binding: SummaryBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.POST_RECORDING,
      page: () => const PostRecordingView(),
      binding: PostRecordingBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}