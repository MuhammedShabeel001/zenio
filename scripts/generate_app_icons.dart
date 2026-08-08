import 'dart:io';
import 'package:xml/xml.dart';

void main() async {
  final svgFile = File('assets/images/app_logo.svg');
  if (!svgFile.existsSync()) {
    print('Error: assets/images/app_logo.svg not found.');
    exit(1);
  }

  final svgContent = svgFile.readAsStringSync();
  final document = XmlDocument.parse(svgContent);
  final svg = document.rootElement;

  // Extract ViewBox or Width/Height
  final viewBox = svg.getAttribute('viewBox')?.split(' ') ?? 
                 ['0', '0', svg.getAttribute('width') ?? '108', svg.getAttribute('height') ?? '108'];
  
  final vWidth = double.parse(viewBox[2]);
  final vHeight = double.parse(viewBox[3]);

  print('Processing SVG: ${vWidth}x$vHeight');

  // Extract Paths and Colors
  final paths = svg.findAllElements('path');
  final vectorPaths = <Map<String, String>>[];

  for (final path in paths) {
    final d = path.getAttribute('d') ?? '';
    var fill = path.getAttribute('fill') ?? '#000000';
    if (fill == 'none') continue;
    
    // Normalize color for Android (e.g., black -> #000000)
    if (fill == 'black') fill = '#000000';
    if (fill == 'white') fill = '#FFFFFF';
    
    vectorPaths.add({'d': d, 'fill': fill});
  }

  // --- 1. Generate Android VectorDrawable XML ---
  final androidXml = '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <group
        android:scaleX="0.8"
        android:scaleY="0.8"
        android:translateX="10.8"
        android:translateY="10.8">
${vectorPaths.map((p) => '        <path\n            android:fillColor="${p['fill']}"\n            android:pathData="${p['d']}" />').join('\n')}
    </group>
</vector>''';

  final androidTargets = [
    'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
    'android/app/src/staging/res/drawable/ic_launcher_foreground.xml',
    'android/app/src/development/res/drawable/ic_launcher_foreground.xml',
    'android/app/src/main/res/drawable/ic_launch_image.xml',
  ];

  for (final target in androidTargets) {
    final file = File(target);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    file.writeAsStringSync(androidXml);
    print('Updated $target');
  }

  // Update Android Background Colors & Launch Background
  final bgXml = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#000000</color>
</resources>''';
  final androidBgTargets = [
    'android/app/src/main/res/values/ic_launcher_background.xml',
    'android/app/src/staging/res/values/ic_launcher_background.xml',
    'android/app/src/development/res/values/ic_launcher_background.xml',
  ];
  for (final target in androidBgTargets) {
    final file = File(target);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    file.writeAsStringSync(bgXml);
    print('Updated $target');
  }

  final launchBgXml = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/black" />
    <item android:gravity="center" android:drawable="@drawable/ic_launch_image" />
</layer-list>''';
  final launchBgFile = File('android/app/src/main/res/drawable/launch_background.xml');
  if (launchBgFile.existsSync()) {
    launchBgFile.writeAsStringSync(launchBgXml);
    print('Updated android/app/src/main/res/drawable/launch_background.xml');
  }

  // --- 2. Generate iOS Icons using sips ---
  print('Generating iOS Icons...');
  
  // Create high-res padded PNG first
  final shell = await Process.run('sips', [
    '-s', 'format', 'png',
    '--resampleHeight', '824',
    'assets/images/app_logo.svg',
    '--out', 'app_icon_tmp.png',
  ]);
  
  await Process.run('sips', [
    '-p', '1024', '1024',
    '--padColor', '000000',
    'app_icon_tmp.png',
    '--out', 'app_icon_final.png',
  ]);

  final iosTargets = [
    {'dir': 'ios/Runner/Assets.xcassets/AppIcon-dev.appiconset', 'prefix': 'AppIcon-dev'},
    {'dir': 'ios/Runner/Assets.xcassets/AppIcon-stg.appiconset', 'prefix': 'AppIcon-stg'},
    {'dir': 'ios/Runner/Assets.xcassets/AppIcon.appiconset', 'prefix': 'AppIcon'},
  ];

  for (final target in iosTargets) {
    await generateIosIconSet(target['dir']!, target['prefix']!, 'app_icon_final.png');
    print('Updated ${target['dir']}');
  }

  // Update Launch Image
  await Process.run('sips', [
    '-s', 'format', 'png',
    '--resampleHeight', '360',
    'assets/images/app_logo.svg',
    '--out', 'launch_tmp_360.png',
  ]);
  
  await Process.run('sips', [
    '-p', '450', '450',
    '--padColor', '000000',
    'launch_tmp_360.png',
    '--out', 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
  ]);
  
  await Process.run('sips', ['--resampleHeightWidth', '300', '300', 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png', '--out', 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png']);
  await Process.run('sips', ['--resampleHeightWidth', '150', '150', 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png', '--out', 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@1x.png']);

  // Cleanup
  File('app_icon_tmp.png').deleteSync();
  File('app_icon_final.png').deleteSync();
  File('launch_tmp_360.png').deleteSync();

  print('Done! App icons and launch images updated successfully.');
}

Future<void> generateIosIconSet(String destDir, String prefix, String source) async {
  final dir = Directory(destDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final sizes = {
    '20x20@2x': 40, '20x20@3x': 60,
    '29x29@1x': 29, '29x29@2x': 58, '29x29@3x': 87,
    '40x40@2x': 80, '40x40@3x': 120,
    '60x60@2x': 120, '60x60@3x': 180,
    '76x76@1x': 76, '76x76@2x': 152,
    '83.5x83.5@2x': 167,
    '1024x1024@1x': 1024,
    '20x20@1x': 20, // iPad
    '40x40@1x': 40, // iPad
  };

  for (final entry in sizes.entries) {
    await Process.run('sips', ['-z', entry.value.toString(), entry.value.toString(), source, '--out', '$destDir/$prefix-${entry.key}.png']);
  }

  final contentsJson = '''{
  "images": [
    { "size": "20x20", "idiom": "iphone", "filename": "$prefix-20x20@2x.png", "scale": "2x" },
    { "size": "20x20", "idiom": "iphone", "filename": "$prefix-20x20@3x.png", "scale": "3x" },
    { "size": "29x29", "idiom": "iphone", "filename": "$prefix-29x29@1x.png", "scale": "1x" },
    { "size": "29x29", "idiom": "iphone", "filename": "$prefix-29x29@2x.png", "scale": "2x" },
    { "size": "29x29", "idiom": "iphone", "filename": "$prefix-29x29@3x.png", "scale": "3x" },
    { "size": "40x40", "idiom": "iphone", "filename": "$prefix-40x40@2x.png", "scale": "2x" },
    { "size": "40x40", "idiom": "iphone", "filename": "$prefix-40x40@3x.png", "scale": "3x" },
    { "size": "60x60", "idiom": "iphone", "filename": "$prefix-60x60@2x.png", "scale": "2x" },
    { "size": "60x60", "idiom": "iphone", "filename": "$prefix-60x60@3x.png", "scale": "3x" },
    { "size": "20x20", "idiom": "ipad", "filename": "$prefix-20x20@1x.png", "scale": "1x" },
    { "size": "20x20", "idiom": "ipad", "filename": "$prefix-20x20@2x.png", "scale": "2x" },
    { "size": "29x29", "idiom": "ipad", "filename": "$prefix-29x29@1x.png", "scale": "1x" },
    { "size": "29x29", "idiom": "ipad", "filename": "$prefix-29x29@2x.png", "scale": "2x" },
    { "size": "40x40", "idiom": "ipad", "filename": "$prefix-40x40@1x.png", "scale": "1x" },
    { "size": "40x40", "idiom": "ipad", "filename": "$prefix-40x40@2x.png", "scale": "2x" },
    { "size": "76x76", "idiom": "ipad", "filename": "$prefix-76x76@1x.png", "scale": "1x" },
    { "size": "76x76", "idiom": "ipad", "filename": "$prefix-76x76@2x.png", "scale": "2x" },
    { "size": "83.5x83.5", "idiom": "ipad", "filename": "$prefix-83.5x83.5@2x.png", "scale": "2x" },
    { "size": "1024x1024", "idiom": "ios-marketing", "filename": "$prefix-1024x1024@1x.png", "scale": "1x" }
  ],
  "info": { "version": 1, "author": "xcode" }
}''';

  File('$destDir/Contents.json').writeAsStringSync(contentsJson);
}
