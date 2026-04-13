import 'canonical_task_mapper.dart';
import 'fake_sync_transport.dart';
import 'supabase_sync_transport.dart';
import 'sync_transport.dart';

enum SyncTransportMode { fake, supabase }

class SyncTransportRegistry {
  final FakeSyncTransport _fakeTransport = FakeSyncTransport();
  final SupabaseSyncTransport _supabaseTransport = SupabaseSyncTransport();
  SyncTransportMode _mode = SyncTransportMode.fake;

  SyncTransportMode getMode() => _mode;

  void setMode(SyncTransportMode mode) {
    _mode = mode;
  }

  SyncTransport getTransport() {
    return _mode == SyncTransportMode.supabase
        ? _supabaseTransport
        : _fakeTransport;
  }

  List<CanonicalTask> getRemoteSnapshot() {
    return _mode == SyncTransportMode.fake
        ? _fakeTransport.snapshot()
        : const <CanonicalTask>[];
  }
}
