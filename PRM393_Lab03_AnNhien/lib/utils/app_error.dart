/// Lỗi đã được dịch sang câu cho người dùng. Service bắt exception của SDK
/// (Firebase, mạng…) rồi ném [AppException]; ViewModel chỉ đọc [userMessage].
class AppException implements Exception {
  const AppException(this.userMessage, {this.cause, this.stackTrace});

  final String userMessage;
  final Object? cause;
  final StackTrace? stackTrace;

  static const network = AppException('Chưa có mạng. Bác thử lại sau nhé.');
  static const cancelled = AppException('Bác chưa đăng nhập. Bấm lại khi sẵn sàng.');
  static const unknown = AppException('Có lỗi xảy ra. Bác bấm "Thử lại" nhé.');

  @override
  String toString() => 'AppException($userMessage, cause: $cause)';
}
