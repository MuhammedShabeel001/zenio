import 'package:app/features/home/home.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'i_task_repository.g.dart';

@RestApi()
abstract class TaskRepository {
  factory TaskRepository(
    Dio dio, {
    String? baseUrl,
    ParseErrorLogger? errorLogger,
  }) = _TaskRepository;

  @GET('https://httpbin.org/status/204')
  Future<HttpResponse<void>> responseWith204();

  @GET('/tasks')
  Future<List<Task>> getTasks();

  @GET('/tasks/{id}')
  Future<Task> getTask(@Path('id') String id);

  @PATCH('/tasks/{id}')
  Future<Task> updateTaskPart(
    @Path() String id,
    @Body() Map<String, dynamic> map,
  );

  @PUT('/tasks/{id}')
  Future<Task> updateTask(@Path() String id, @Body() Task task);
}
