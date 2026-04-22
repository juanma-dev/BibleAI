import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/books/screens/books_screen.dart';
import '../../features/chapters/screens/chapters_screen.dart';
import '../../features/reader/screens/reader_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/books',
      name: 'books',
      builder: (context, state) => const BooksScreen(),
    ),
    GoRoute(
      path: '/chapters/:bookId',
      name: 'chapters',
      builder: (context, state) {
        final bookId = int.parse(state.pathParameters['bookId']!);
        return ChaptersScreen(bookId: bookId);
      },
    ),
    GoRoute(
      path: '/reader/:bookId/:chapter',
      name: 'reader',
      builder: (context, state) {
        final bookId = int.parse(state.pathParameters['bookId']!);
        final chapter = int.parse(state.pathParameters['chapter']!);
        final highlightVerse = state.extra as int?;
        return ReaderScreen(
          bookId: bookId,
          initialChapter: chapter,
          highlightVerse: highlightVerse,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
