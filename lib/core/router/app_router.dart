import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_screen.dart';
import '../../features/agenda/presentation/agenda_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/set_password_screen.dart';
import '../../features/donations/presentation/donations_screen.dart';
import '../../features/feedback/presentation/feedback_screen.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/islamic/presentation/islamic_library_screen.dart';
import '../../features/members/presentation/edit_profile_screen.dart';
import '../../features/members/presentation/members_screen.dart';
import '../../features/messages/presentation/chat_screen.dart';
import '../../features/messages/presentation/messages_screen.dart';
import '../../features/mosque/presentation/mosque_screen.dart';
import '../../features/notifications/presentation/notification_settings_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/quran/presentation/juz_reader_screen.dart';
import '../../features/quran/presentation/mushaf_reader_screen.dart';
import '../../features/quran/presentation/quran_hub_screen.dart';
import '../../features/quran/presentation/surah_reader_screen.dart';
import '../../features/hadith/presentation/hadith_hub_screen.dart';
import '../../features/islamic/presentation/quiz_list_screen.dart';
import '../../features/islamic/presentation/quiz_play_screen.dart';
import '../../features/islamic/presentation/tracking_screen.dart';
import '../../features/social/presentation/feed_screen.dart';
import '../../features/social/presentation/create_post_screen.dart';
import '../../features/social/presentation/post_detail_screen.dart';
import '../../features/social/data/models/post_model.dart';
import '../../features/quran/presentation/recitation_test_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../shared/widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/members',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MembersScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SetPasswordScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notifications/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/messages/chat/:groupId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final groupName = state.extra as String? ?? 'Discussion';
          return ChatScreen(groupId: groupId, groupName: groupName);
        },
      ),
      GoRoute(
        path: '/donations',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DonationsScreen(),
      ),
      GoRoute(
        path: '/finance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FinanceScreen(),
      ),
      GoRoute(
        path: '/feedback',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/islamic',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const IslamicLibraryScreen(),
      ),
      GoRoute(
        path: '/quran',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuranHubScreen(),
      ),
      GoRoute(
        path: '/hadith',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HadithHubScreen(),
      ),
      GoRoute(
        path: '/islamic/quiz',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuizListScreen(),
      ),
      GoRoute(
        path: '/islamic/quiz/play',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuizPlayScreen(),
      ),
      GoRoute(
        path: '/islamic/tracking',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TrackingScreen(),
      ),
      GoRoute(
        path: '/messages',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/social/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/social/post/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final post = state.extra as PostModel;
          return PostDetailScreen(post: post);
        },
      ),
      GoRoute(
        path: '/quran/surah/:number',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final number = int.parse(state.pathParameters['number']!);
          final initialAyah = state.extra as int? ?? 1;
          return SurahReaderScreen(
            surahNumber: number,
            initialAyah: initialAyah,
          );
        },
      ),
      GoRoute(
        path: '/quran/juz/:number',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final number = int.parse(state.pathParameters['number']!);
          return JuzReaderScreen(juzNumber: number);
        },
      ),
      GoRoute(
        path: '/quran/mushaf',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final page = state.extra as int? ?? 1;
          return MushafReaderScreen(initialPage: page);
        },
      ),
      GoRoute(
        path: '/quran/test/:surah',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final surah = int.parse(state.pathParameters['surah']!);
          return RecitationTestScreen(surahNumber: surah);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/agenda',
                builder: (context, state) => const AgendaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mosque',
                builder: (context, state) => const MosqueScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
