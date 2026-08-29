import os
import glob
import re

files = glob.glob('lib/**/*.dart', recursive=True)
for file in files:
    if file.endswith('.g.dart') or file.endswith('.freezed.dart'):
        continue

    with open(file, 'r') as f:
        content = f.read()
    
    changed = False

    # Fix pattern: final prefs = ref.watch(sqlitePrefsProvider);
    # To:
    # final prefsAsync = ref.watch(sqlitePrefsProvider);
    # final prefs = prefsAsync.valueOrNull;

    # The issue is that some files used 'prefs', some used 'sharedPreferences'
    
    new_content = re.sub(
        r"final (\w+) = ref\.watch\(sqlitePrefsProvider\);",
        r"final \1Async = ref.watch(sqlitePrefsProvider);\n  final \1 = \1Async.valueOrNull;",
        content
    )

    # In locale_provider.dart:
    # ref.watch(sharedPrefsProvider).value?.getString('locale')
    # wait, earlier refactor.py didn't touch locale_provider's watch because it was inline.
    
    # We should just do a global replace of sharedPrefsProvider -> sqlitePrefsProvider
    # in locale_provider as well.
    
    if new_content != content:
        with open(file, 'w') as f:
            f.write(new_content)
        print(f"Fixed provider in {file}")
