enum AsyncStatus { idle, loading, data, error }

class AsyncValue<T> {
  const AsyncValue._({
    required this.status,
    this.data,
    this.error,
    this.stackTrace,
  });

  const AsyncValue.idle() : this._(status: AsyncStatus.idle);

  const AsyncValue.loading() : this._(status: AsyncStatus.loading);

  const AsyncValue.data(T data) : this._(status: AsyncStatus.data, data: data);

  const AsyncValue.error(Object error, [StackTrace? stackTrace])
    : this._(status: AsyncStatus.error, error: error, stackTrace: stackTrace);

  final AsyncStatus status;
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isIdle => status == AsyncStatus.idle;
  bool get isLoading => status == AsyncStatus.loading;
  bool get hasData => status == AsyncStatus.data;
  bool get hasError => status == AsyncStatus.error;
}
