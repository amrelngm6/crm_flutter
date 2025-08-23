import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/device_settings_service.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/dashboard_provider.dart';
import 'core/providers/leads_provider.dart';
import 'core/providers/clients_provider.dart';
import 'core/providers/tasks_provider.dart';
import 'core/providers/deals_provider.dart';
import 'core/providers/estimates_provider.dart';
import 'core/providers/meetings_provider.dart';
import 'core/providers/proposals_provider.dart';
import 'core/providers/tickets_provider.dart';
import 'core/providers/todos_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/email_provider.dart';
import 'core/providers/estimate_requests_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  // Initialize services
  await StorageService().initialize();
  await DeviceSettingsService.init();
  ApiService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        path: 'assets/translations',
        fallbackLocale: Locale(DeviceSettingsService.selectedLanguage
            .toLowerCase()
            .substring(0, 2)),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeProvider()),
            ChangeNotifierProvider(create: (context) => UserProvider()),
            ChangeNotifierProvider(create: (context) => DashboardProvider()),
            ChangeNotifierProvider(create: (context) => LeadsProvider()),
            ChangeNotifierProvider(create: (context) => ClientsProvider()),
            ChangeNotifierProvider(create: (context) => TasksProvider()),
            ChangeNotifierProvider(create: (context) => DealsProvider()),
            ChangeNotifierProvider(create: (context) => EstimatesProvider()),
            ChangeNotifierProvider(create: (context) => MeetingsProvider()),
            ChangeNotifierProvider(create: (context) => ProposalsProvider()),
            ChangeNotifierProvider(create: (context) => TicketsProvider()),
            ChangeNotifierProvider(create: (context) => TodosProvider()),
            ChangeNotifierProvider(create: (context) => ChatProvider()),
            ChangeNotifierProvider(create: (context) => NotificationProvider()),
            ChangeNotifierProvider(create: (context) => EmailProvider()),
            ChangeNotifierProvider(create: (context) => EstimateRequestsProvider()),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              context.setLocale(const Locale('ar'));
              final localeCode = DeviceSettingsService.selectedLanguage
                  .toLowerCase()
                  .substring(0, 2);
              return MaterialApp.router(
                title: AppConstants.appName,
                debugShowCheckedModeBanner: false,

                // Theme Configuration
                theme: themeProvider.lightTheme,
                darkTheme: themeProvider.darkTheme,
                themeMode: themeProvider.themeMode,

                locale: Locale(localeCode),

                // localizationsDelegates: const [
                //   GlobalMaterialLocalizations.delegate,
                //   GlobalWidgetsLocalizations.delegate,
                //   GlobalCupertinoLocalizations.delegate,
                // ],

                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,

                // Routing
                routerConfig: AppRouter.router,
              );
            },
          ),
        ));
  }
}
