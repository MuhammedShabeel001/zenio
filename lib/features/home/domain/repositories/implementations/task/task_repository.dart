import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/home.dart';
import 'package:zenio/shared/shared.dart';

part 'task_repository.g.dart';

@Riverpod(keepAlive: true)
TaskRepository taskRepositoryRepo(Ref ref) =>
    TaskRepository(ref.read(dioProvider));
