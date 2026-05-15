> ✅ Done 2026-05-15

# State 01 — State class template + Riverpod scaffold

## Vị trí
- file/module chính (tạo mới):
  - `app/lib/core/state/async_state.dart` (sealed class hoặc base class State 4 trường)
  - `app/lib/core/state/list_state.dart` (extend AsyncState cho list paginate)
- file liên quan (đã có):
  - `app/lib/core/riverpod/providers.dart` (đã có `ThemeModeNotifier`, `LocaleNotifier` — pattern hỗn hợp StateNotifier + Riverpod codegen, sẽ standardize)
- file có thể bị ảnh hưởng:
  - tất cả Notifier mới sẽ dùng template

## Vấn đề
- Clean-code §2.1 yêu cầu state class có 4 trường: `data`, `isLoading`, `error`, `lastSyncAt`.
- Hiện có 0 Notifier domain. Cần template chuẩn trước khi migrate feed/chat/profile.
- Pattern Riverpod hỗn hợp: `ThemeModeNotifier` dùng `@riverpod` codegen, `LocaleNotifier` dùng `StateNotifier` cũ. Cần standardize.
- non-goals:
  - KHÔNG migrate feature nào trong plan này (chỉ tạo template).
  - KHÔNG sinh code generator file (`*.g.dart`) nếu chưa có generator setup.

## Hướng giải quyết
- Bước 1 — Quyết định pattern duy nhất:
  - Option A: `@riverpod` codegen (modern, Riverpod 3.x recommended). Cần `riverpod_generator` + `build_runner` chạy `dart run build_runner watch`.
  - Option B: `Notifier` + `NotifierProvider` (Riverpod 2.x manual). Đơn giản, không cần codegen.
  - **Đề xuất**: Option A vì project đã có `providers.g.dart` indication (codegen đang setup). Verify pubspec.yaml có `riverpod_generator`.
- Bước 2 — Template `AsyncState<T>`:
  ```
  class AsyncState<T> {
    final T? data;
    final bool isLoading;
    final Object? error;
    final DateTime? lastSyncAt;
    
    const AsyncState({this.data, this.isLoading = false, this.error, this.lastSyncAt});
    
    AsyncState<T> copyWith({...});
    
    bool get hasData => data != null;
    bool get hasError => error != null;
  }
  ```
- Bước 3 — Template `ListState<T>` (extend cho paginate):
  ```
  class ListState<T> extends AsyncState<List<T>> {
    final String? cursor;
    final bool hasMore;
    final bool isLoadingMore;
    
    // ...
  }
  ```
- Bước 4 — Document trong `clean-code.md` §2.1:
  - "Mọi async screen dùng template AsyncState<T> hoặc ListState<T> trong core/state/"
- Bước 5 — Reference Notifier ví dụ (không implement, chỉ doc snippet):
  - File `core/state/_template_notifier.md` mô tả pattern fetch / refresh / loadMore
- Alternative đã loại:
  - Riverpod 2.x StateNotifier + freezed → loại do project chưa có freezed dep, codegen quá nặng cho midterm.
  - flutter_bloc → loại, project đang Riverpod, không migrate framework.

## Cách check & verify
- Commands:
  - `cd app && flutter analyze`
  - `dart run build_runner build --delete-conflicting-outputs` (nếu Option A)
  - `flutter test --no-pub`
- Manual:
  - Tạo 1 sample Notifier dummy dùng template → verify build
- Downstream check:
  - `core/riverpod/providers.dart` — verify pattern hiện không vỡ
  - `pubspec.yaml` — verify có `riverpod_generator` nếu Option A
- Tiêu chí pass:
  - `core/state/async_state.dart` + `list_state.dart` exist
  - flutter analyze 0 error
  - Sample Notifier sử dụng template build OK
  - Doc bổ sung trong clean-code.md §2.1
- Tiêu chí fail / red flag:
  - Generator không tìm thấy → verify pubspec dev_dependencies có đủ riverpod_generator + build_runner
  - Template quá rigid (không phù hợp form/auth screen 1-shot) → cho phép feature tự dùng FutureProvider thay AsyncState (clean-code §2.1 trade-off note)
