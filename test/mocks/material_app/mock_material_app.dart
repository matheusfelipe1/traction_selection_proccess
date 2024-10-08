import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:traction_selection_process/app/routes/route_pages.dart';
import 'package:traction_selection_process/app/core/constants/app_constants.dart';

class MockMaterialApp {
  static Widget getWidget({
    required String initialRoute,
  }) {
    return GetMaterialApp(
      getPages: RoutePages.pages,
      title: AppConstants.appName,
      initialRoute: initialRoute,
      theme: ThemeData(useMaterial3: true),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          viewPadding: EdgeInsets.zero,
          textScaler: const TextScaler.linear(1.0),
        ),
        child: Material(child: child),
      ),
    );
  }
}
