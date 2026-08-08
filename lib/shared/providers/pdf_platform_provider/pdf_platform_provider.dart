import 'package:app/shared/shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pdf_platform_provider.g.dart';

@Riverpod(keepAlive: true)
IPdfPlatform pdf(Ref ref) => IPdfPlatform();
