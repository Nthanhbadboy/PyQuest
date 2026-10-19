/// Controller của bảng giảng, **thuộc phiên bài học** (rev 4 §D2).
///
/// Không phải app-global, không nằm trong subtree của chat sheet, và không có quyền ghi vào
/// lesson: board chỉ nhận plan đã validate, tự giữ beat hiện tại, và **không** có bất kỳ
/// callback nào để chạm score/quota/energy/reward/`lessonCompleted`. Nếu một ngày cần phát
/// tín hiệu "đã học xong", đó là việc của `PQC-011` (wire vào lesson) với contract riêng.
library;

import 'package:flutter/foundation.dart';

import 'board_models.dart';

/// Lớp của trẻ. Nét và ghi chú chỉ đổi qua API của **chính** lớp này; `BoardOp` không có
/// đường nào gọi tới nó (rev 4 §D5: "model chỉ được sửa layer Tutor").
class LearnerLayer extends ChangeNotifier {
  final List<String> _strokes = <String>[];
  String _note = '';

  List<String> get strokes => List<String>.unmodifiable(_strokes);
  String get note => _note;
  bool get isEmpty => _strokes.isEmpty && _note.isEmpty;

  void addStroke(String id) {
    if (_strokes.contains(id)) return;
    _strokes.add(id);
    notifyListeners();
  }

  void undoStroke() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    notifyListeners();
  }

  void setNote(String value) {
    if (_note == value) return;
    _note = value;
    notifyListeners();
  }

  /// Chỉ dành cho nút "Xóa nét của con" trong UI của trẻ — không có đường nào từ plan.
  void clearOwned() {
    if (_strokes.isEmpty && _note.isEmpty) return;
    _strokes.clear();
    _note = '';
    notifyListeners();
  }
}

class BoardController extends ChangeNotifier {
  BoardController({
    required this.sessionId,
    required String locale,
    required this.lessonId,
    required this.stepId,
    this.reduceMotion = false,
  }) : _locale = locale;

  final String sessionId;
  final String lessonId;
  final String stepId;

  String _locale;
  bool reduceMotion;

  int _contextRevision = 0;
  int _turnId = 0;
  bool _disposed = false;
  bool _awaitingLearner = false;

  TeachingPlan? _plan;
  int _beatIndex = 0;
  List<BoardIssue> _lastIssues = const <BoardIssue>[];
  BoardApplyOutcome? _lastOutcome;
  BoardFallbackReason? _fallbackReason;

  final LearnerLayer learner = LearnerLayer();

  String get locale => _locale;
  int get contextRevision => _contextRevision;
  int get turnId => _turnId;
  TeachingPlan? get plan => _plan;
  int get beatIndex => _beatIndex;
  int get beatCount => _plan?.beats.length ?? 0;
  List<BoardIssue> get lastIssues => _lastIssues;
  BoardApplyOutcome? get lastOutcome => _lastOutcome;

  /// Mã lý do fallback: hiện khi plan bị từ chối, để trẻ không thấy bảng trắng và reviewer
  /// biết đây là authored fallback chứ không phải "AI đã giảng". View mới là chỗ dịch ra câu
  /// theo locale **hiện hành** (rev 7 §R7-C).
  BoardFallbackReason? get fallbackReason => _fallbackReason;

  bool get isWaitingForLearner => _awaitingLearner;
  bool get hasPlan => _plan != null;

  BoardBeat? get currentBeat {
    final TeachingPlan? p = _plan;
    if (p == null || p.beats.isEmpty) return null;
    if (_beatIndex < 0 || _beatIndex >= p.beats.length) return null;
    return p.beats[_beatIndex];
  }

  BoardBeatCopy? get currentCopy => currentBeat?.copyFor(_locale);

  /// Token hiện hành của phiên — host dùng nó khi gửi request, và board dùng nó để chặn
  /// reply muộn. `sessionId` ở đây là identity của **phiên lesson**, không phải toàn app.
  BoardPlanToken get currentToken => BoardPlanToken(
        sessionId: sessionId,
        contextRevision: _contextRevision,
        turnId: _turnId,
        locale: _locale,
      );

  /// Đổi code / chạy thử / mở-đóng panel: mọi reply mang revision cũ thành vô hiệu.
  void bumpContext() {
    if (_disposed) return;
    _contextRevision++;
    notifyListeners();
  }

  /// Stop/barge-in: turn cũ mất hiệu lực, và **không** có beat mới nào được bắt đầu.
  /// Rev 7 §R7-D: `waitForLearner` là thuộc tính của **beat**, không phải của lượt phát —
  /// ngắt audio hoặc hu reply không phải "con đã làm xong", nên wait vẫn còn. Trẻ vẫn phải
  /// bấm nút của mình để đi tiếp; biến stop thành skip là bỏ qua đúng beat chờ.
  void cancelTurn() {
    if (_disposed) return;
    _turnId++;
    notifyListeners();
  }

  /// Nối với chuỗi audio hiện có: `stopStreaming()`/`release()` là chỗ host gọi vào đây khi
  /// trẻ ngắt. Board **không** giả đồng bộ bằng timer (rev 4 §D10: caption-only).
  void notePlaybackCanceled() => cancelTurn();

  /// Áp một plan **đã validate** (host gọi `validatePlan` trước). Bất kỳ lý do gì cũng
  /// **không** để lại trạng thái nửa vời: plan cũ vẫn nguyên, kèm nhãn fallback.
  BoardApplyOutcome applyPlan(BoardPlanToken token, BoardValidation validation) {
    // Đã dispose thì **không** notify: ChangeNotifier sau dispose sẽ nổ assert, và một
    // widget đã gỡ khỏi cây không còn ai nghe.
    if (_disposed) return BoardApplyOutcome.disposed;
    if (!_tokenMatches(token)) {
      _fallbackReason = BoardFallbackReason.staleReply;
      return _finish(BoardApplyOutcome.tokenRejected);
    }
    if (!validation.accepted) {
      _lastIssues = validation.issues;
      _fallbackReason = BoardFallbackReason.rejectedPlan;
      return _finish(BoardApplyOutcome.rejectedPlan);
    }
    final TeachingPlan? incoming = validation.plan;
    if (incoming == null) {
      // `accepted` mà không có plan là bug ở tầng validate, không phải dữ liệu trẻ:
      // reject atomic chứ không deref `!`.
      _fallbackReason = BoardFallbackReason.rejectedPlan;
      return _finish(BoardApplyOutcome.rejectedPlan);
    }
    // Rev 7 §R7-D: token đúng mà plan của bài/bước khác vẫn phải bị chặn ở đây. Host có
    // quyền validate với `expectedLessonId` của nó, nhưng board là biên cuối trước pixel —
    // tự đối chiếu owner để một reply lạc không ghi chữ bài 3 lên bảng bài 1.
    if (incoming.lessonId != lessonId || incoming.stepId != stepId) {
      _fallbackReason = BoardFallbackReason.foreignLesson;
      return _finish(BoardApplyOutcome.foreignLesson);
    }
    _plan = incoming;
    _beatIndex = 0;
    _awaitingLearner = incoming.beats.isNotEmpty && incoming.beats.first.waitForLearner;
    _lastIssues = const <BoardIssue>[];
    _fallbackReason = null;
    return _finish(BoardApplyOutcome.applied);
  }

  /// Còn beat phía trước không. View dùng nó để bật/tắt nút — một nút bấm không có phản hồi
  /// là lỗi UI (rev 7 §R7-D).
  bool get canAdvance {
    final TeachingPlan? p = _plan;
    return p != null && p.beats.isNotEmpty && _beatIndex + 1 < p.beats.length;
  }

  /// Nút "Tiếp" có việc để làm hay không: hoặc còn beat, hoặc đang chờ con xác nhận.
  bool get canGoNext => !_disposed && (canAdvance || _awaitingLearner);
  bool get canGoPrevious => !_disposed && _beatIndex > 0;

  /// **Ý định của trẻ** (rev 4 §D3 + rev 7 §R7-D): beat đang chờ thì cái bấm này là
  /// `learnerActed`, rồi mới tiến nếu còn beat. Tách khỏi [next] — đường advance nội bộ
  /// (AI/auto) vẫn bị wait chặn, nên board không bao giờ tự nhảy qua phần trẻ chưa làm.
  bool learnerAdvance() {
    if (_disposed) return false;
    if (!canGoNext) return false;
    if (_awaitingLearner) _awaitingLearner = false;
    if (!canAdvance) {
      notifyListeners();
      return false;
    }
    _beatIndex++;
    final TeachingPlan? p = _plan;
    _awaitingLearner = p != null && p.beats[_beatIndex].waitForLearner;
    notifyListeners();
    return true;
  }

  bool next() {
    if (_disposed) return false;
    if (_awaitingLearner) return false; // rev 4 §D3: không tự nhảy beat
    final TeachingPlan? p = _plan;
    if (p == null || _beatIndex + 1 >= p.beats.length) return false;
    _beatIndex++;
    _awaitingLearner = p.beats[_beatIndex].waitForLearner;
    notifyListeners();
    return true;
  }

  bool previous() {
    if (_disposed) return false;
    if (_beatIndex == 0) return false;
    _beatIndex--;
    final TeachingPlan? p = _plan;
    _awaitingLearner = p != null && p.beats[_beatIndex].waitForLearner;
    notifyListeners();
    return true;
  }

  /// Replay là **điều khiển thật**, không phải timer, và không được phát lại phần thưởng.
  void replay() {
    if (_disposed) return;
    _beatIndex = 0;
    final TeachingPlan? p = _plan;
    _awaitingLearner = p != null && p.beats.isNotEmpty && p.beats.first.waitForLearner;
    notifyListeners();
  }

  /// Trẻ đã thao tác (sửa code, chọn, vẽ) -> beat chờ được phép đi tiếp.
  void learnerActed() {
    if (_disposed) return;
    if (!_awaitingLearner) return;
    _awaitingLearner = false;
    notifyListeners();
  }

  /// Đổi locale: **giữ** plan/beat/ink/code của trẻ và cả trạng thái chờ, chỉ thay copy đang
  /// hiển thị (rev 4 §D5, rev 7 §R7-D). Đồng thời bump revision: mọi reply đang bay của locale
  /// cũ bị chặn ở `_tokenMatches`.
  void setLocale(String next) {
    if (_disposed) return;
    if (_locale == next) return;
    _locale = next;
    _contextRevision++;
    _turnId++;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    learner.dispose();
    super.dispose();
  }

  bool _tokenMatches(BoardPlanToken token) =>
      token.sessionId == sessionId &&
      token.contextRevision == _contextRevision &&
      token.turnId == _turnId &&
      token.locale == _locale;

  BoardApplyOutcome _finish(BoardApplyOutcome outcome) {
    _lastOutcome = outcome;
    notifyListeners();
    return outcome;
  }

}
