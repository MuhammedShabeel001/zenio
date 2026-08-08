import 'dart:convert' as convert;

import 'package:app/shared/shared.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ip_config_provider.g.dart';

@Riverpod(keepAlive: true)
Future<IPModel> ipConfig(Ref ref) async {
  try {
    final url = Uri.parse('https://ipinfo.io/?token=098daa645a100b');
    final response =
        await http.get(url, headers: {'Referer': 'https://example.com'});

    return IPModel.fromJson(
      convert.jsonDecode(response.body) as Map<String, dynamic>,
    );
  } catch (e) {
    return const IPModel();
  }
}
