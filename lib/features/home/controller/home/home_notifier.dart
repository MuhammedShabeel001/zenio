import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/home.dart';

part 'home_notifier.freezed.dart';
part 'home_notifier.g.dart';
part 'home_state.dart';

@Riverpod()
class HomeNotifier extends _$HomeNotifier {
  late TaskRepository taskRepository;

  @override
  HomeState build() {
    taskRepository = ref.watch(taskRepositoryRepoProvider);
    return HomeState.initial();
  }

  Future<void> getTasks() async {
    final tasks = await taskRepository.getTasks();
    state = state.copyWith(tasks: tasks);
  }
}
