import 'package:app/shared/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hancod_theme/hancod_theme.dart';

class HomeScreenWeb extends ConsumerStatefulWidget {
  const HomeScreenWeb({super.key});

  @override
  ConsumerState<HomeScreenWeb> createState() => _HomeScreenWebState();
}

class _HomeScreenWebState extends ConsumerState<HomeScreenWeb> {
  final _inputDecoration = const InputDecoration(border: OutlineInputBorder());
  final _formKey = GlobalKey<FormBuilderState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.helloHancod)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppTextForm<String>(
                  name: 'text',
                  label: context.l10n.textForm,
                  decoration: _inputDecoration,
                ),
                const SizedBox(height: 8),
                AppPhoneNumberForm(
                  name: 'phone',
                  label: context.l10n.phoneNo,
                  decoration: _inputDecoration,
                ),
                const SizedBox(height: 8),
                AppTypeAheadForm<int>(
                  name: 'age',
                  label: context.l10n.age,
                  decoration: _inputDecoration,
                  suggestionsCallback: (search) =>
                      List.generate(100, (index) => index)
                          .where((element) => '$element'.contains(search))
                          .toList(),
                  itemBuilder: (context, suggestion) => ListTile(
                    title: Text('$suggestion'),
                  ),
                  selectionToTextTransformer: (suggestion) => '$suggestion',
                ),
                const SizedBox(height: 8),
                AppDateTimeForm(
                  name: 'date',
                  label: context.l10n.date,
                  decoration: _inputDecoration,
                ),
                const SizedBox(height: 18),
                AppButton(
                  onPress: () {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {}
                  },
                  label: Text(context.l10n.primary),
                ),
                const SizedBox(height: 8),
                AppButton(
                  style: ButtonStyles.secondary,
                  onPress: () {},
                  label: Text(context.l10n.secondary),
                ),
                const SizedBox(height: 8),
                AppButton(
                  style: ButtonStyles.cancel,
                  onPress: () {},
                  label: Text(context.l10n.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
