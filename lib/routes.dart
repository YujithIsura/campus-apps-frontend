// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:developer';
import 'dart:html';

import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery/auth.dart';
import 'package:gallery/data/campus_apps_portal.dart';
import 'package:gallery/deferred_widget.dart';
import 'package:gallery/main.dart';
import 'package:gallery/pages/demo.dart';
import 'package:gallery/pages/home.dart';
import 'package:gallery/routing/parsed_route.dart';
import 'package:gallery/routing/parser.dart';
import 'package:gallery/routing/route_state.dart';
import 'package:gallery/studies/crane/app.dart' deferred as crane;
import 'package:gallery/studies/crane/routes.dart' as crane_routes;
import 'package:gallery/studies/fortnightly/app.dart' deferred as fortnightly;
import 'package:gallery/studies/fortnightly/routes.dart' as fortnightly_routes;
import 'package:gallery/studies/rally/app.dart' deferred as rally;
import 'package:gallery/studies/rally/routes.dart' as rally_routes;
import 'package:gallery/studies/reply/app.dart' as reply;
import 'package:gallery/studies/reply/routes.dart' as reply_routes;
import 'package:gallery/studies/shrine/app.dart' deferred as shrine;
import 'package:gallery/studies/shrine/routes.dart' as shrine_routes;
import 'package:gallery/studies/starter/app.dart' as starter_app;
import 'package:gallery/studies/starter/routes.dart' as starter_app_routes;
import 'package:path_to_regexp/path_to_regexp.dart';

typedef PathWidgetBuilder = Widget Function(BuildContext, String?);

class Path {
  const Path(this.pattern, this.builder, {this.openInSecondScreen = false});

  /// A RegEx string for route matching.
  final String pattern;

  /// The builder for the associated pattern route. The first argument is the
  /// [BuildContext] and the second argument a RegEx match if that is included
  /// in the pattern.
  ///
  /// ```dart
  /// Path(
  ///   'r'^/demo/([\w-]+)$',
  ///   (context, matches) => Page(argument: match),
  /// )
  /// ```
  final PathWidgetBuilder builder;

  /// If the route should open on the second screen on foldables.
  final bool openInSecondScreen;
}

class RouteConfiguration {
  /// List of [Path] to for route matching. When a named route is pushed with
  /// [Navigator.pushNamed], the route name is matched with the [Path.pattern]
  /// in the list below. As soon as there is a match, the associated builder
  /// will be returned. This means that the paths higher up in the list will
  /// take priority.
  static List<Path> paths = [
    Path(
      r'^' + DemoPage.baseRoute + r'/([\w-]+)$',
      (context, match) => DemoPage(slug: match),
      openInSecondScreen: false,
    ),
    Path(
      r'^' + rally_routes.homeRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(rally.loadLibrary,
            () => rally.RallyApp()), // ignore: prefer_const_constructors
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + shrine_routes.homeRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(shrine.loadLibrary,
            () => shrine.ShrineApp()), // ignore: prefer_const_constructors
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + crane_routes.defaultRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(crane.loadLibrary,
            () => crane.CraneApp(), // ignore: prefer_const_constructors
            placeholder: const DeferredLoadingPlaceholder(name: 'Crane')),
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + fortnightly_routes.defaultRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(
            fortnightly.loadLibrary,
            // ignore: prefer_const_constructors
            () => fortnightly.FortnightlyApp()),
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + reply_routes.homeRoute,
      // ignore: prefer_const_constructors
      (context, match) =>
          const StudyWrapper(study: reply.ReplyApp(), hasBottomNavBar: true),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + starter_app_routes.defaultRoute,
      (context, match) => const StudyWrapper(
        study: starter_app.StarterApp(),
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^/',
      (context, match) => const RootPage(),
      openInSecondScreen: false,
    ),
  ];

  /// The route generator callback used when the app is navigated to a named
  /// route. Set it on the [MaterialApp.onGenerateRoute] or
  /// [WidgetsApp.onGenerateRoute] to make use of the [paths] for route
  /// matching.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    log("settings signed in $settings");
    for (final path in paths) {
      final regExpPattern = RegExp(path.pattern);
      if (regExpPattern.hasMatch(settings.name!)) {
        final firstMatch = regExpPattern.firstMatch(settings.name!)!;
        final match = (firstMatch.groupCount == 1) ? firstMatch.group(1) : null;
        var test = '';
        test = settings.name!;
        var guarded_route = _guard(settings);

        log("settings signed in firstMatch $test");
        log("settings signed in match $settings");
        log("settings signed in guarded_route $guarded_route");

        if (kIsWeb) {
          return NoAnimationMaterialPageRoute<void>(
            builder: (context) => path.builder(context, match),
            settings: guarded_route,
          );
        }
        if (path.openInSecondScreen) {
          return TwoPanePageRoute<void>(
            builder: (context) => path.builder(context, match),
            settings: guarded_route,
          );
        } else {
          return MaterialPageRoute<void>(
            builder: (context) => path.builder(context, match),
            settings: guarded_route,
          );
        }
      }
    }

    // If no match was found, we let [WidgetsApp.onUnknownRoute] handle it.
    return null;
  }

  static RouteSettings _guard(RouteSettings from) {
    // final _auth = CampusAppsPortalAuth();
    // final signedIn = await _auth.getSignedIn();
    bool signedIn = campusAppsPortalInstance.getSignedIn();
    // String? jwt_sub = admissionSystemInstance.getJWTSub();
    // const String signInRoute = '/signin';
    // final signInRoute = '/signin';
    final baseRoute = '/demo';
    // const String baseRoute = DemoPage.baseRoute;
    // final signInRoute = RouteSettings('/signin', arguments: {});
    // create a new route settings object to pass with two arguments
    // final signInRoute = RouteSettings('/signin', arguments: {'from': from});
    // write a name argument to the route settings object
    // signInRoute.name = '/signin';
    // write a arguments argument to the route settings object
    // signInRoute.arguments = {'from': from};
    // write new route settings object to the route settings object with named arguments
    // log from the route settings object
    log("from ${from.toString()}");
    final signInRoute = RouteSettings(name: '/signin', arguments: null);
    //log signInRoute
    log("signInRoute ${signInRoute.toString()}");

    // Go to /apply if the user is not signed in
    log("_guard signed in 222$from");
    // log("_guard JWT sub ${jwt_sub}");
    log("_guard from ${from.toString()}\n");
    if (!signedIn && from.toString() != signInRoute.toString()) {
      // Go to /signin if the user is not signed in
      log("_guard signed in 333$from");
      return signInRoute;
    }
    // Go to /application if the user is signed in and tries to go to /signin.
    else if (signedIn && from.toString() == signInRoute.toString()) {
      log("_guard signed in 444$from");
      return signInRoute;
    }
    return from;

    // for (final path in paths) {
    //   final regExpPattern = RegExp(path.pattern);
    //   if (regExpPattern.hasMatch(from)) {
    //     final firstMatch = regExpPattern.firstMatch(settings.name!)!;
    //     final match = (firstMatch.groupCount == 1) ? firstMatch.group(1) : null;
    //     var test = '';
    //     test = settings.name!;
    //     var guarded_route = _guard(settings);

    //     log("settings signed in firstMatch $test");
    //     log("settings signed in match $settings");
    //     log("settings signed in guarded_route $guarded_route");

    //     if (kIsWeb) {
    //       return NoAnimationMaterialPageRoute<void>(
    //         builder: (context) => path.builder(context, match),
    //         settings: guarded_route,
    //       );
    //     }
    //     if (path.openInSecondScreen) {
    //       return TwoPanePageRoute<void>(
    //         builder: (context) => path.builder(context, match),
    //         settings: guarded_route,
    //       );
    //     } else {
    //       return MaterialPageRoute<void>(
    //         builder: (context) => path.builder(context, match),
    //         settings: guarded_route,
    //       );
    //     }
    //   }
    // }
  }
}

class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class TwoPanePageRoute<T> extends OverlayRoute<T> {
  TwoPanePageRoute({
    required this.builder,
    super.settings,
  });

  final WidgetBuilder builder;

  @override
  Iterable<OverlayEntry> createOverlayEntries() sync* {
    yield OverlayEntry(builder: (context) {
      final hinge = MediaQuery.of(context).hinge?.bounds;
      if (hinge == null) {
        return builder.call(context);
      } else {
        return Positioned(
            top: 0,
            left: hinge.right,
            right: 0,
            bottom: 0,
            child: builder.call(context));
      }
    });
  }
}
