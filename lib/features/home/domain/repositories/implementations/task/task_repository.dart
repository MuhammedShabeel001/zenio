import 'package:app/features/home/home.dart';
import 'package:app/shared/shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_repository.g.dart';

@Riverpod(keepAlive: true)
TaskRepository taskRepositoryRepo(Ref ref) =>
    TaskRepository(ref.read(dioProvider));
