/// Trạng thái chuẩn của mọi màn tải dữ liệu (đề Lab 3 › mục 5).
/// Màn dùng `switch (state)` để vẽ Loading / Empty / Error (có Thử lại) / Data.
sealed class UiState<T> {
  const UiState();
}

final class UiLoading<T> extends UiState<T> {
  const UiLoading();
}

final class UiEmpty<T> extends UiState<T> {
  const UiEmpty();
}

final class UiError<T> extends UiState<T> {
  const UiError(this.message);
  final String message;
}

final class UiData<T> extends UiState<T> {
  const UiData(this.data);
  final T data;
}
