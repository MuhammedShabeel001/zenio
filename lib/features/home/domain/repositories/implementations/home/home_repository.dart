import 'package:app/features/home/home.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_repository.g.dart';

@Riverpod(keepAlive: true)
IHomeRepository homeRepo(Ref ref) => HomeRepository();

class HomeRepository implements IHomeRepository {
  HomeRepository();
}
