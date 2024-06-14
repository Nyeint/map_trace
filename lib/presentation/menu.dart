import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:map_trace/route/my_route.dart';

import '../route/route_path.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {
                context.pushNamed(RouteName.map_view);
              },
              child: const Text('Map View'),
            ),
            OutlinedButton(
              onPressed: () {
                context.pushNamed(RouteName.graph_view);
              },
              child: const Text('Graph View'),
            ),
          ],
        ),
      )
    );
  }
}
