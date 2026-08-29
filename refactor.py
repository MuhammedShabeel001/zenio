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

    if 'SharedPreferences' in content or 'sharedPrefsProvider' in content:
        # Replace imports
        content = re.sub(r"import 'package:shared_preferences/shared_preferences\.dart';\n?", "", content)
        content = re.sub(r"import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider\.dart';\n?", "", content)
        
        if "import 'package:zenio/shared/providers/providers.dart';" not in content:
            # add it after the first import
            content = content.replace("import '", "import 'package:zenio/shared/providers/providers.dart';\nimport '", 1)

        # Replace class name
        content = content.replace('SharedPreferences', 'SqlitePrefs')

        # Replace provider watch pattern
        # Old:
        # final prefsAsync = ref.watch(sharedPrefsProvider);
        # final prefs = prefsAsync.valueOrNull;
        # New:
        # final prefs = ref.watch(sqlitePrefsProvider);
        content = re.sub(r"final \w+Async = ref\.watch\(sharedPrefsProvider\);\s*final (\w+) = \w+Async\.valueOrNull;", r"final \1 = ref.watch(sqlitePrefsProvider);", content)
        
        # Another pattern:
        # final sharedPreferences = ref.watch(sharedPrefsProvider).valueOrNull;
        content = re.sub(r"ref\.watch\(sharedPrefsProvider\)\.valueOrNull", r"ref.watch(sqlitePrefsProvider)", content)

        changed = True

    if changed:
        with open(file, 'w') as f:
            f.write(content)
        print(f"Refactored {file}")
