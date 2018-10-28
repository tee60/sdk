// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/package.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:package_config/packages.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/context/mock_sdk.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DependencyFinderTest);
    defineReflectiveTests(PackageDescriptionTest);
    defineReflectiveTests(PackageManagerTest);
  });
}

/**
 * The name of the pubspec.yaml file.
 */
const String pubspecName = 'pubspec.yaml';

@reflectiveTest
class DependencyFinderTest extends ResolverTestCase {
  void test_transitiveDependenciesFor_circularDependencies() {
    String packageA = convertPath('/pub-cache/a-1.0');
    String packageB = convertPath('/pub-cache/b-1.0');
    String packageC = convertPath('/pub-cache/c-1.0');
    newFile('$packageA/$pubspecName', content: '''
dependencies:
  b: any
''');
    newFile('$packageB/$pubspecName', content: '''
dependencies:
  c: any
''');
    newFile('$packageC/$pubspecName', content: '''
dependencies:
  a: any
''');
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'a': <Folder>[getFolder(packageA)],
      'b': <Folder>[getFolder(packageB)],
      'c': <Folder>[getFolder(packageC)],
    };

    DependencyFinder finder = new DependencyFinder(resourceProvider);
    List<String> result =
        finder.transitiveDependenciesFor(packageMap, packageA);
    expect(result, unorderedEquals([packageB, packageC]));
  }

  void test_transitiveDependenciesFor_missingPubspec() {
    String packagePath = convertPath('/pub-cache/a-1.0');
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'a': <Folder>[getFolder(packagePath)]
    };

    DependencyFinder finder = new DependencyFinder(resourceProvider);
    expect(() => finder.transitiveDependenciesFor(packageMap, packagePath),
        throwsA(new TypeMatcher<AnalysisException>()));
  }

  void test_transitiveDependenciesFor_noDependencies() {
    String packagePath = convertPath('/pub-cache/a-1.0');
    newFile('$packagePath/$pubspecName');
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'a': <Folder>[getFolder(packagePath)]
    };

    DependencyFinder finder = new DependencyFinder(resourceProvider);
    List<String> result =
        finder.transitiveDependenciesFor(packageMap, packagePath);
    expect(result, hasLength(0));
  }

  void test_transitiveDependenciesFor_overlappingDependencies() {
    String packageA = convertPath('/pub-cache/a-1.0');
    String packageB = convertPath('/pub-cache/b-1.0');
    String packageC = convertPath('/pub-cache/c-1.0');
    String packageD = convertPath('/pub-cache/d-1.0');
    newFile('$packageA/$pubspecName', content: '''
dependencies:
  b: any
  c: any
''');
    newFile('$packageB/$pubspecName', content: '''
dependencies:
  d: any
''');
    newFile('$packageC/$pubspecName', content: '''
dependencies:
  d: any
''');
    newFile('$packageD/$pubspecName');
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'a': <Folder>[getFolder(packageA)],
      'b': <Folder>[getFolder(packageB)],
      'c': <Folder>[getFolder(packageC)],
      'd': <Folder>[getFolder(packageD)],
    };

    DependencyFinder finder = new DependencyFinder(resourceProvider);
    List<String> result =
        finder.transitiveDependenciesFor(packageMap, packageA);
    expect(result, unorderedEquals([packageB, packageC, packageD]));
  }

  void test_transitiveDependenciesFor_simpleDependencies() {
    String packageA = convertPath('/pub-cache/a-1.0');
    String packageB = convertPath('/pub-cache/b-1.0');
    String packageC = convertPath('/pub-cache/c-1.0');
    newFile('$packageA/$pubspecName', content: '''
dependencies:
  b: any
  c: any
''');
    newFile('$packageB/$pubspecName');
    newFile('$packageC/$pubspecName');
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'a': <Folder>[getFolder(packageA)],
      'b': <Folder>[getFolder(packageB)],
      'c': <Folder>[getFolder(packageC)],
    };

    DependencyFinder finder = new DependencyFinder(resourceProvider);
    List<String> result =
        finder.transitiveDependenciesFor(packageMap, packageA);
    expect(result, unorderedEquals([packageB, packageC]));
  }
}

@reflectiveTest
class PackageDescriptionTest extends ResolverTestCase {
  void test_equal_false_differentOptions() {
    String packageId = 'path1;path2';
    DartSdk sdk = new MockSdk(resourceProvider: resourceProvider);
    AnalysisOptionsImpl options1 = new AnalysisOptionsImpl();
    AnalysisOptionsImpl options2 = new AnalysisOptionsImpl();
    options2.enableLazyAssignmentOperators =
        !options1.enableLazyAssignmentOperators;
    PackageDescription first = new PackageDescription(packageId, sdk, options1);
    PackageDescription second =
        new PackageDescription(packageId, sdk, options2);
    expect(first == second, isFalse);
  }

  void test_equal_false_differentPaths() {
    String packageId1 = 'path1;path2';
    String packageId2 = 'path1;path3';
    DartSdk sdk = new MockSdk(resourceProvider: resourceProvider);
    AnalysisOptions options = new AnalysisOptionsImpl();
    PackageDescription first = new PackageDescription(packageId1, sdk, options);
    PackageDescription second =
        new PackageDescription(packageId2, sdk, options);
    expect(first == second, isFalse);
  }

  void test_equal_false_differentSDKs() {
    String packageId = 'path1;path2';
    DartSdk sdk1 = new MockSdk(resourceProvider: resourceProvider);
    DartSdk sdk2 = new MockSdk(resourceProvider: resourceProvider);
    AnalysisOptions options = new AnalysisOptionsImpl();
    PackageDescription first = new PackageDescription(packageId, sdk1, options);
    PackageDescription second =
        new PackageDescription(packageId, sdk2, options);
    expect(first == second, isFalse);
  }

  void test_equal_true() {
    String packageId = 'path1;path2';
    DartSdk sdk = new MockSdk(resourceProvider: resourceProvider);
    AnalysisOptions options = new AnalysisOptionsImpl();
    PackageDescription first = new PackageDescription(packageId, sdk, options);
    PackageDescription second = new PackageDescription(packageId, sdk, options);
    expect(first == second, isTrue);
  }
}

@reflectiveTest
class PackageManagerTest extends ResolverTestCase {
  void test_getContext() {
    String packageA = convertPath('/pub-cache/a-1.0');
    String packageB1 = convertPath('/pub-cache/b-1.0');
    String packageB2 = convertPath('/pub-cache/b-2.0');
    String packageC = convertPath('/pub-cache/c-1.0');
    newFile('$packageA/$pubspecName', content: '''
dependencies:
  b: any
  c: any
''');
    newFile('$packageB1/$pubspecName');
    newFile('$packageB2/$pubspecName');
    newFile('$packageC/$pubspecName');

    var pathContext = resourceProvider.pathContext;
    Packages packages1 = new _MockPackages(<String, Uri>{
      'a': pathContext.toUri(packageA),
      'b': pathContext.toUri(packageB1),
      'c': pathContext.toUri(packageC),
    });
    var sdk = new MockSdk(resourceProvider: resourceProvider);
    DartUriResolver resolver = new DartUriResolver(sdk);
    AnalysisOptions options = new AnalysisOptionsImpl();
    //
    // Verify that we can compute a context for a package.
    //
    PackageManager manager = new PackageManager(resourceProvider);
    AnalysisContext context1 =
        manager.getContext(packageA, packages1, resolver, options);
    expect(context1, isNotNull);
    //
    // Verify that if we have the same package map we get the same context.
    //
    AnalysisContext context2 =
        manager.getContext(packageA, packages1, resolver, options);
    expect(context2, same(context1));
    //
    // Verify that if we have a different package map we get a different context.
    //
    Packages packages3 = new _MockPackages(<String, Uri>{
      'a': pathContext.toUri(packageA),
      'b': pathContext.toUri(packageB2),
      'c': pathContext.toUri(packageC),
    });
    AnalysisContext context3 =
        manager.getContext(packageA, packages3, resolver, options);
    expect(context3, isNot(same(context1)));
  }
}

/**
 * An implementation of [Packages] used for testing.
 */
class _MockPackages implements Packages {
  final Map<String, Uri> map;

  _MockPackages(this.map);

  @override
  Iterable<String> get packages => map.keys;

  @override
  Map<String, Uri> asMap() => map;

  @override
  Uri resolve(Uri packageUri, {Uri notFound(Uri packageUri)}) {
    fail('Unexpected invocation of resolve');
  }
}
