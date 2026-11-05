import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/relative.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'ui_state.dart';

/// F11 Gia đình – chủ: Hương. S09 `1:1993` (tab Gia đình), S09b `26:2` (vừa thêm),
/// N21 `52:48` (vừa xoá + "Hoàn tác").
///
/// Hàng "Gợi ý từ Mai · 2 việc" ở đầu S09 **không** nằm trong state này: View đọc
/// thẳng `suggestionInboxViewModelProvider` (F12 – Sanh, chỉ dùng, không sửa).

/// Chữ quan hệ hiển thị trên thẻ ("Con gái", "Con trai"…).
/// TODO(Hiếu): khi `Relative.relationLabel` được thêm (đề xuất F11 bước 01) đổi thành
/// `r.relationLabel ?? r.relation`. Hiện model chỉ có 4 nhóm Con / Cháu / Bạn bè / Khác.
String relationText(Relative r) => r.relation;

/// Cách gọi người thân trong câu N15 / N21 / N10: quan hệ + tên ("Con gái Mai").
String relativeTitle(Relative r) => '${relationText(r)} ${r.name}';

class FamilyList {
  const FamilyList({
    required this.relatives,
    this.justAdded,
    this.justDeleted,
  });

  final List<Relative> relatives;

  /// S09b: người vừa thêm → banner "Đã thêm …".
  final Relative? justAdded;

  /// N21: người vừa xoá → banner "… đã được xóa" + bản đầy đủ để "Hoàn tác".
  /// Có bản này thì vẫn là `UiData` dù danh sách rỗng (để còn Hoàn tác).
  final Relative? justDeleted;

  FamilyList copyWith({
    List<Relative>? relatives,
    Relative? justAdded,
    Relative? justDeleted,
    bool clearAdded = false,
    bool clearDeleted = false,
  }) =>
      FamilyList(
        relatives: relatives ?? this.relatives,
        justAdded: clearAdded ? null : (justAdded ?? this.justAdded),
        justDeleted: clearDeleted ? null : (justDeleted ?? this.justDeleted),
      );
}

const _loadFailed = 'Chưa tải được người thân. Bác bấm "Thử lại" nhé.';

class FamilyViewModel extends Notifier<UiState<FamilyList>> {
  @override
  UiState<FamilyList> build() {
    Future.microtask(load);
    return const UiLoading();
  }

  /// `FamilyRepository.all()` → Data; rỗng → Empty; lỗi → Error (+ "Thử lại" = [retry]).
  Future<void> load() async {
    if (!ref.mounted) return;
    state = const UiLoading();
    try {
      final list = await ref.read(familyRepositoryProvider).all();
      if (!ref.mounted) return;
      state =
          list.isEmpty ? const UiEmpty() : UiData(FamilyList(relatives: list));
    } catch (e) {
      if (!ref.mounted) return;
      // Lỗi đọc dữ liệu, không phải lỗi lưu → không ghi Crashlytics.
      state = UiError(e is AppException ? e.userMessage : _loadFailed);
    }
  }

  Future<void> retry() => load();

  /// "Gọi điện" trên thẻ S09: mở gọi ngay qua `ContactLauncherService.call`, không
  /// hộp thoại phụ. Trả `null` khi đã mở, ngược lại câu lỗi cho View hiện.
  Future<String?> call(Relative relative) async {
    final failed = 'Chưa gọi được cho ${relative.name}. Bác thử lại sau nhé.';
    try {
      final opened =
          await ref.read(contactLauncherServiceProvider).call(relative.phone);
      return opened ? null : failed;
    } on AppException catch (e) {
      return e.userMessage;
    } catch (e, st) {
      if (ref.mounted) {
        await ref
            .read(crashServiceProvider)
            .recordError(e, st, reason: 'call_relative');
      }
      return failed;
    }
  }

  /// S09b: nạp lại danh sách, người vừa thêm đứng **cuối** + banner "Đã thêm …"
  /// (bước 03 gọi sau khi lưu). Banner không tự tắt; mất khi rời tab / mở màn khác
  /// ([dismissAdded], DT-34).
  Future<void> showAdded(Relative relative) async {
    await load();
    // Nạp lỗi → giữ ErrorView + "Thử lại" (người thân đã lưu, nạp lại sẽ thấy).
    if (!ref.mounted || state is UiError<FamilyList>) return;
    final current = switch (state) {
      UiData(:final data) => data.relatives,
      _ => const <Relative>[],
    };
    final others = current.where((r) => r.id != relative.id);
    state = UiData(FamilyList(
      relatives: [...others, relative],
      justAdded: relative,
    ));
  }

  /// Tắt banner S09b (và viền nổi của thẻ người mới).
  void dismissAdded() {
    if (state case UiData(:final data) when data.justAdded != null) {
      state = UiData(data.copyWith(clearAdded: true));
    }
  }

  /// N21: bật banner "… đã được xóa" + giữ bản để Hoàn tác (bước 04 gọi sau khi xoá).
  void showDeleted(Relative relative) {
    // TODO bước 04: bỏ khỏi danh sách + justDeleted = relative.
  }

  /// "Hoàn tác" ở N21: lưu lại đúng người cũ (cùng `id`, cùng dữ liệu), tắt banner.
  /// Trả `null` khi xong, ngược lại câu lỗi.
  Future<String?> undoDelete() async {
    // TODO bước 04: FamilyRepository.save(justDeleted) → load lại, clearDeleted.
    return null;
  }
}

final familyViewModelProvider =
    NotifierProvider<FamilyViewModel, UiState<FamilyList>>(FamilyViewModel.new);
