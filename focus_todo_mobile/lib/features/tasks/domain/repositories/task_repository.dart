import '../../data/models/task_data_state.dart';

abstract class TaskRepository {
  const TaskRepository();

  Future<TaskDataState?> loadState();

  Future<bool> hasPersistedState();

  Future<void> saveState(TaskDataState state);
}
