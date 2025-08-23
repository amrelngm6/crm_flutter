import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:medians_ai_crm/features/notifications/notifications_page.dart';
import 'package:medians_ai_crm/features/proposals/presentation/pages/proposals_page.dart';
import 'package:medians_ai_crm/features/proposals/presentation/pages/proposal_edit_page.dart';
import '../models/chat.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page_styled.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/leads/presentation/pages/leads_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/deals/presentation/pages/deals_page.dart';
import '../../features/estimates/presentation/pages/estimates_page.dart';
import '../../features/estimates/presentation/pages/estimate_requests_page.dart';
import '../../features/meetings/presentation/pages/meetings_page.dart';
import '../../features/tickets/pages/tickets_page.dart';
import '../../features/tickets/pages/ticket_details_page.dart';
import '../../features/tickets/pages/create_ticket_page.dart';
import '../../features/todos/presentation/pages/todos_page.dart';
import '../../features/todos/presentation/pages/create_todo_page.dart';
import '../../features/chat/pages/chat_page.dart';
import '../../features/chat/pages/chat_room_page.dart';
import '../../features/email/presentation/pages/email_main_page.dart';
import '../../features/email/presentation/pages/email_messages_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Authentication
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // Main App Routes
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPageStyled(),
      ),

      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) => const CustomersPage(),
      ),

      GoRoute(
        path: '/leads',
        name: 'leads',
        builder: (context, state) => const LeadsPage(),
      ),

      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => const TasksPage(),
      ),

      GoRoute(
        path: '/deals',
        name: 'deals',
        builder: (context, state) => const DealsPage(),
      ),

      GoRoute(
        path: '/estimates',
        name: 'estimates',
        builder: (context, state) => const EstimatesPage(),
      ),

      GoRoute(
        path: '/estimate-requests',
        name: 'estimate-requests',
        builder: (context, state) => const EstimateRequestsPage(),
      ),

      GoRoute(
        path: '/proposals',
        name: 'proposals',
        builder: (context, state) => const ProposalsPage(),
      ),

      GoRoute(
        path: '/proposals/create',
        name: 'create-proposal',
        builder: (context, state) => const ProposalEditPage(),
      ),

      GoRoute(
        path: '/meetings',
        name: 'meetings',
        builder: (context, state) => const MeetingsPage(),
      ),

      // Todos Routes
      GoRoute(
        path: '/todos',
        name: 'todos',
        builder: (context, state) => const TodosPage(),
      ),

      GoRoute(
        path: '/todos/create',
        name: 'create-todo',
        builder: (context, state) => const CreateTodoPage(),
      ),

      // Chat Routes
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatPage(),
      ),

      // Notifications Routes
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      GoRoute(
        path: '/chat/:roomId',
        name: 'chat-room',
        builder: (context, state) {
          final roomIdParam = state.pathParameters['roomId'];
          if (roomIdParam == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid room ID')),
            );
          }

          final roomId = int.tryParse(roomIdParam);
          if (roomId == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid room ID')),
            );
          }

          // Get room from provider or pass room data
          // For now, create a basic room object
          return ChatRoomPage(
            room: ChatRoom(
              id: roomId,
              name: 'Chat Room',
              businessId: 1,
              participantsCount: 0,
              unreadCount: 0,
              hasVideoMeeting: false,
              participants: [],
              createdBy: 1,
              isModerator: false,
            ),
          );
        },
      ),

      // Tickets Routes
      GoRoute(
        path: '/tickets',
        name: 'tickets',
        builder: (context, state) => const TicketsPage(),
      ),

      GoRoute(
        path: '/tickets/create',
        name: 'create-ticket',
        builder: (context, state) => const CreateTicketPage(),
      ),

      GoRoute(
        path: '/tickets/:id',
        name: 'ticket-details',
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          if (idParam == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid ticket ID')),
            );
          }

          final ticketId = int.tryParse(idParam);
          if (ticketId == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid ticket ID')),
            );
          }

          return TicketDetailsPage(ticketId: ticketId);
        },
      ),

      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // Email Routes
      GoRoute(
        path: '/email',
        name: 'email',
        builder: (context, state) => const EmailMainPage(),
      ),

      GoRoute(
        path: '/email/messages/:accountId',
        name: 'email-messages',
        builder: (context, state) {
          final accountIdParam = state.pathParameters['accountId'];
          if (accountIdParam == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid account ID')),
            );
          }

          final accountId = int.tryParse(accountIdParam);
          if (accountId == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid account ID')),
            );
          }

          return EmailMessagesPage(accountId: accountId);
        },
      ),

      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}
