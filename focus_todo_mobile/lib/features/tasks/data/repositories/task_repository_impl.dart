import '../../domain/repositories/task_repository.dart';
import '../models/task_data_state.dart';
import '../local/task_local_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._localDataSource);

  final TaskLocalDataSource _localDataSource;

  @override
  Future<TaskDataState?> loadState() {
    return _localDataSource.loadState();
  }

  @override
  Future<bool> hasPersistedState() {
    return _localDataSource.hasPersistedState();
  }

  @override
  Future<void> saveState(TaskDataState state) {
    return _localDataSource.saveState(state);
  }
}
