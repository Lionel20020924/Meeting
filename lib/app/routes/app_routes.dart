part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  
  static const HOME = _Paths.HOME;
  static const LOGIN = _Paths.LOGIN;
  static const MEETINGS = _Paths.MEETINGS;
  static const RECORD = _Paths.RECORD;
  static const MEETING_DETAIL = _Paths.MEETING_DETAIL;
  static const SUMMARY = _Paths.SUMMARY;
  static const PROFILE = _Paths.PROFILE;
  static const POST_RECORDING = _Paths.POST_RECORDING;
}

abstract class _Paths {
  _Paths._();
  
  static const HOME = '/home';
  static const LOGIN = '/login';
  static const MEETINGS = '/meetings';
  static const RECORD = '/record';
  static const MEETING_DETAIL = '/meeting-detail';
  static const SUMMARY = '/summary';
  static const PROFILE = '/profile';
  static const POST_RECORDING = '/post-recording';
}