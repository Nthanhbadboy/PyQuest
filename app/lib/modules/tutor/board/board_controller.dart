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
  String? _fallbackNotice;

  final LearnerLayer learner = LearnerLayer();

  String get locale => _locale;
  int get contextRevision => _contextRevision;
  int get turnId => _turnId;
  TeachingPlan? get plan => _plan;
  int get beatIndex => _beatIndex;
  int get beatCount => _plan?.beats.length ?? 0;
  List<BoardIssue> get lastIssues => _lastIssues;
  BoardApplyOutcome? get lastOutcome => _lastOutcome;

  /// Nhãn fallback **có nguồn gốc rõ**: hiện khi plan bị reject, để trẻ không thấy bảng trắng
  /// và reviewer biết đây là authored fallback chứ không phải "AI đã giảng".
  String? get fallbackNotice => _fallbackNotice;

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
  void cancelTurn() {
    if (_disposed) return;
    _turnId++;
    _awaitingLearner = false;
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
      _fallbackNotice = _notice('stale');
      return _finish(BoardApplyOutcome.tokenRejected);
    }
    if (!validation.accepted) {
      _lastIssues = validation.issues;
      _fallbackNotice = _notice('invalid');
      return _finish(BoardApplyOutcome.rejectedPlan);
    }
    final TeachingPlan incoming = validation.plan!;
    _plan = incoming;
    _beatIndex = 0;
    _awaitingLearner = incoming.beats.isNotEmpty && incoming.beats.first.waitForLearner;
    _lastIssues = const <BoardIssue>[];
    _fallbackNotice = null;
    return _finish(BoardApplyOutcome.applied);
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

  /// Đổi locale: **giữ** plan/beat/ink/code của trẻ, chỉ thay copy đang hiển thị (rev 4 §D5).
  /// Đồng thời bump revision: mọi reply đang bay của locale cũ bị chặn ở `_tokenMatches`.
  void setLocale(String next) {
    if (_disposed) return;
    if (_locale == next) return;
    _locale = next;
    _contextRevision++;
    _turnId++;
    _awaitingLearner = false;
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

  String _notice(String kind) {
    final bool vi = _locale.startsWith('vi');
    switch (kind) {
      case 'stale':
        return vi
            ? 'Trợ giảng đang soạn cho bước khác, nên bảng giữ nguyên bước này.'
            : 'The tutor was answering an older step, so the board stayed on this step.';
      default:
        return vi
            ? 'Bảng tác giả không hợp lệ nên thầy dùng bước cũ. Đây là nội dung soạn sẵn, không phải AI.'
            : 'The authored board was rejected, so the previous step stays. This is authored content, not AI.';
    }
  }
}
