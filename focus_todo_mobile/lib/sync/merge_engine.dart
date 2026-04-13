import '../shared/models/task.dart';

int _compareUpdatedAt(Task left, Task right) {
  return DateTime.parse(
    left.updatedAt,
  ).compareTo(DateTime.parse(right.updatedAt));
}

int _compareDeletedPreference(Task left, Task right) {
  final leftDeleted = left.deletedAt != null;
  final rightDeleted = right.deletedAt != null;

  if (leftDeleted == rightDeleted) {
    return 0;
  }

  return leftDeleted ? 1 : -1;
}

int _compareDeviceId(Task left, Task right) {
  return left.updatedByDeviceId.toLowerCase().compareTo(
    right.updatedByDeviceId.toLowerCase(),
  );
}

Task mergeTask(Task localTask, Task remoteTask) {
  final updatedAtCompare = _compareUpdatedAt(localTask, remoteTask);
  if (updatedAtCompare > 0) {
    return localTask.copyWith();
  }
  if (updatedAtCompare < 0) {
    return remoteTask.copyWith();
  }

  final deletedCompare = _compareDeletedPreference(localTask, remoteTask);
  if (deletedCompare > 0) {
    return localTask.copyWith();
  }
  if (deletedCompare < 0) {
    return remoteTask.copyWith();
  }

  final deviceCompare = _compareDeviceId(localTask, remoteTask);
  if (deviceCompare > 0) {
    return localTask.copyWith();
  }
  if (deviceCompare < 0) {
    return remoteTask.copyWith();
  }

  return remoteTask.copyWith();
}
