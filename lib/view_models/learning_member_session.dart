import 'package:flutter/foundation.dart';

// 학습용 메모리 상태입니다. memberId는 인증 수단이 아닙니다.
class LearningMemberSession extends ChangeNotifier {
  int? _memberId;
  int? get memberId => _memberId;
  void setMemberId(int id) {
    if (id <= 0) throw ArgumentError('유효한 회원 ID가 필요합니다.');
    _memberId = id;
    notifyListeners();
  }

  void clear() {
    _memberId = null;
    notifyListeners();
  }
}
