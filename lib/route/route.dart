import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:map_trace/presentation/google_map_view.dart';
import 'package:map_trace/presentation/graph_view.dart';
import 'package:map_trace/presentation/map_view.dart';
import 'package:map_trace/presentation/menu.dart';
import 'package:map_trace/route/my_route.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MenuScreen();
      },
    ),
    GoRoute(
      path: RoutePath.map_view,
      name: RouteName.map_view,
      builder: (BuildContext context, GoRouterState state) {
        return const MapView();
      },
    ),
    GoRoute(
      path: RoutePath.graph_view,
      name: RouteName.graph_view,
      builder: (BuildContext context, GoRouterState state) {
        return const GraphView();
      },
    ),
    GoRoute(
      path: RoutePath.google_map_view,
      name: RouteName.google_map_view,
      builder: (BuildContext context, GoRouterState state) {
        return const GoogleMapView();
      },
    ),
  ],
);