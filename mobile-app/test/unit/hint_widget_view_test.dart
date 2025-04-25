import 'package:flutter/material.dart';
import 'package:freecodecamp/enums/ext_type.dart';
import 'package:freecodecamp/models/learn/challenge_model.dart';
import 'package:freecodecamp/models/learn/curriculum_model.dart';
import 'package:freecodecamp/ui/views/learn/widgets/dynamic_panel/panels/hint/hint_widget_view.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

class MockChallenge extends Mock implements Challenge {}

class MockBlock extends Mock implements Block {}

class MockBuildContext extends Mock implements BuildContext {}

class FakeAndroidDeviceInfo extends Fake implements AndroidDeviceInfo {
  @override
  String get model => 'Pixel 5';

  @override
  AndroidBuildVersion get version => FakeAndroidBuildVersion();
}

class FakeAndroidBuildVersion extends Fake implements AndroidBuildVersion {
  @override
  String get release => '11';

  @override
  int get sdkInt => 30;
}

void main() {
  group('genForumLink', () {
    late MockSharedPreferences mockPrefs;
    late MockDeviceInfoPlugin mockDeviceInfoPlugin;
    late MockChallenge mockChallenge;
    late MockBlock mockBlock;
    late MockBuildContext mockContext;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockDeviceInfoPlugin = MockDeviceInfoPlugin();
      mockChallenge = MockChallenge();
      mockBlock = MockBlock();
      mockContext = MockBuildContext();

      // Mock SharedPreferences to return predefined values
      when(mockPrefs.getString(any)).thenReturn('Some file content');

      // Mock getDeviceInfo to return a fake device info
      when(mockDeviceInfoPlugin.androidInfo).thenAnswer(
        (_) async => FakeAndroidDeviceInfo(),
      );

      // Mocking other methods or properties
      when(mockChallenge.helpCategory).thenReturn('helpCategory');
      when(mockChallenge.title).thenReturn('Test Challenge');
      when(mockChallenge.superBlock).thenReturn('superBlock');
      when(mockChallenge.block).thenReturn('block');
      when(mockChallenge.dashedName).thenReturn('test-challenge');
      when(mockChallenge.files).thenReturn([
        ChallengeFile(
            name: 'file1',
            ext: parseExt('js'),
            contents: 'File 1 contents',
            editableRegionBoundaries: [2, 4],
            history: ['File history'],
            fileKey: 'fileKey'),
      ]);

      // Mocking Block
      when(mockBlock.name).thenReturn('Block Title');
    });

    test('generates correct forum link', () async {
      final result = await genForumLink(mockChallenge, mockBlock, mockContext,
          editorText: 'Editor code');

      final expectedUrl = Uri.encodeFull(
        'https://your-forum-url.com/new-topic?category=helpCategory&title=Block Title - Test Challenge&body=**Tell us what\'s happening:**\nDescribe your issue in detail here.\n\n**Your code so far**```dart\n/* file: file1.dart */\nSome file content\n```\n\n**Your mobile information:**\n```txt\nPixel 5 - Android 11 - Android SDK 30\n```\n\n**Challenge:** Block Title - Test Challenge\n\n**Link to the challenge:**\nhttps://www.freecodecamp.org/learn/superBlock/block/test-challenge',
      );

      expect(result, expectedUrl);
    });

    test('generates alternative forum link if URL exceeds 8000 characters',
        () async {
      // Simulate a long URL scenario
      final longEditorText =
          'A' * 10000; // Long code that would generate a long URL
      final result = await genForumLink(mockChallenge, mockBlock, mockContext,
          editorText: longEditorText);

      expect(result, contains('altStudentCode'));
    });

    test('handles null editor text gracefully', () async {
      final result = await genForumLink(mockChallenge, mockBlock, mockContext);

      final expectedUrl = Uri.encodeFull(
        'https://your-forum-url.com/new-topic?category=helpCategory&title=Block Title - Test Challenge&body=**Tell us what\'s happening:**\nDescribe your issue in detail here.\n\n**Your code so far**```dart\n/* file: file1.dart */\nSome file content\n```\n\n**Your mobile information:**\n```txt\nPixel 5 - Android 11 - Android SDK 30\n```\n\n**Challenge:** Block Title - Test Challenge\n\n**Link to the challenge:**\nhttps://www.freecodecamp.org/learn/superBlock/block/test-challenge',
      );

      expect(result, expectedUrl);
    });

    test('generates correct URL for multiple files in challenge', () async {
      // Mock a challenge with multiple files
      when(mockChallenge.files).thenReturn([
        ChallengeFile(
            name: 'file1',
            ext: parseExt('js'),
            contents: 'File 2 contents',
            editableRegionBoundaries: [2, 4],
            history: ['File 1 history'],
            fileKey: 'file1Key'),
        ChallengeFile(
            name: 'file2',
            ext: parseExt('js'),
            contents: 'File 2 contents',
            editableRegionBoundaries: [2, 4],
            history: ['File 2 history'],
            fileKey: 'file2Key'),
      ]);

      final result = await genForumLink(mockChallenge, mockBlock, mockContext,
          editorText: 'Editor code');

      final expectedUrl = Uri.encodeFull(
        'https://your-forum-url.com/new-topic?category=helpCategory&title=Block Title - Test Challenge&body=**Tell us what\'s happening:**\nDescribe your issue in detail here.\n\n**Your code so far**```dart\n/* file: file1.dart */\nSome file content\n```\n\n```dart\n/* file: file2.dart */\nSome file content\n```\n\n**Your mobile information:**\n```txt\nPixel 5 - Android 11 - Android SDK 30\n```\n\n**Challenge:** Block Title - Test Challenge\n\n**Link to the challenge:**\nhttps://www.freecodecamp.org/learn/superBlock/block/test-challenge',
      );

      expect(result, expectedUrl);
    });
  });
}
