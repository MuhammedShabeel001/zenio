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

    new_content = re.sub(r'(\w+)\s*=\s*await (prefs|_prefs)\.getString\(', r'\1 = \2.getString(', content)
    new_content = re.sub(r'(\w+)\s*=\s*await (prefs|_prefs)\.getStringList\(', r'\1 = \2.getStringList(', new_content)
    new_content = re.sub(r'(\w+)\s*=\s*await (prefs|_prefs)\.getDouble\(', r'\1 = \2.getDouble(', new_content)
    new_content = re.sub(r'(\w+)\s*=\s*await (prefs|_prefs)\.getBool\(', r'\1 = \2.getBool(', new_content)
    new_content = re.sub(r'(\w+)\s*=\s*await (prefs|_prefs)\.getInt\(', r'\1 = \2.getInt(', new_content)

    if new_content != content:
        with open(file, 'w') as f:
            f.write(new_content)
        print(f"Removed await from {file}")
