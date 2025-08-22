import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/todos_provider.dart';
import '../../../../core/models/todo.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_filter_bottom_sheet.dart';
import '../widgets/todo_statistics_card.dart';
import 'create_todo_page.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TodosProvider>();
      provider.initialize();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TodosProvider>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B4D3E), // Dashboard green
              Color(0xFF2D5A47),
              Color(0xFF52D681),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllTodosTab(),
                      _buildPendingTodosTab(),
                      _buildCompletedTodosTab(),
                      _buildStatisticsTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateTodo(),
        backgroundColor: const Color(0xFF52D681),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              'Todo list'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<TodosProvider>(
            builder: (context, provider, child) {
              return GestureDetector(
                onTap: provider.isLoading ? null : () => _showFilterSheet(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: provider.hasActiveFilters
                        ? const Color(0xFF52D681)
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: provider.hasActiveFilters
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.8),
                        size: 24,
                      ),
                      if (provider.hasActiveFilters)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF1B4D3E),
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Completed'),
          Tab(text: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildAllTodosTab() {
    return Consumer<TodosProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.todos.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52D681)),
            ),
          );
        }

        if (provider.error != null) {
          return _buildErrorWidget(provider.error!);
        }

        if (provider.todos.isEmpty) {
          return _buildEmptyWidget(
              'No todos found', 'Create your first todo item');
        }

        return RefreshIndicator(
          onRefresh: provider.refreshTodos,
          color: const Color(0xFF52D681),
          child: _buildDraggableTodoList(provider.todos, provider),
        );
      },
    );
  }

  Widget _buildPendingTodosTab() {
    return Consumer<TodosProvider>(
      builder: (context, provider, child) {
        final pendingTodos = provider.pendingTodos;

        if (provider.isLoading && provider.todos.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52D681)),
            ),
          );
        }

        if (pendingTodos.isEmpty) {
          return _buildEmptyWidget('No pending todos', 'All caught up!');
        }

        return RefreshIndicator(
          onRefresh: provider.refreshTodos,
          color: const Color(0xFF52D681),
          child: _buildDraggableTodoList(pendingTodos, provider),
        );
      },
    );
  }

  Widget _buildCompletedTodosTab() {
    return Consumer<TodosProvider>(
      builder: (context, provider, child) {
        final completedTodos = provider.completedTodos;

        if (provider.isLoading && provider.todos.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52D681)),
            ),
          );
        }

        if (completedTodos.isEmpty) {
          return _buildEmptyWidget(
              'No completed todos', 'Complete some tasks to see them here');
        }

        return RefreshIndicator(
          onRefresh: provider.refreshTodos,
          color: const Color(0xFF52D681),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: completedTodos.length + (provider.hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == completedTodos.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF52D681)),
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TodoCard(
                  todo: completedTodos[index],
                  onToggleComplete: (todoId) =>
                      provider.toggleTodoCompletion(todoId),
                  onEdit: (todo) => _navigateToEditTodo(todo),
                  onDelete: (todoId) => _deleteTodo(todoId, provider),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<TodosProvider>(
      builder: (context, provider, child) {
        if (provider.statistics == null) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52D681)),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.loadStatistics,
          color: const Color(0xFF52D681),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: TodoStatisticsCard(
              statistics: provider.statistics!,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableTodoList(List<Todo> todos, TodosProvider provider) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: todos.length + (provider.hasMoreData ? 1 : 0),
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }

        final updatedTodos = List<Todo>.from(todos);
        final item = updatedTodos.removeAt(oldIndex);
        updatedTodos.insert(newIndex, item);

        provider.reorderTodos(updatedTodos);
      },
      itemBuilder: (context, index) {
        if (index == todos.length) {
          return Container(
            key: const ValueKey('loading'),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52D681)),
                ),
              ),
            ),
          );
        }

        final todo = todos[index];
        return Container(
          key: ValueKey(todo.id),
          margin: const EdgeInsets.only(bottom: 12),
          child: TodoCard(
            todo: todo,
            onToggleComplete: (todoId) => provider.toggleTodoCompletion(todoId),
            onEdit: (todo) => _navigateToEditTodo(todo),
            onDelete: (todoId) => _deleteTodo(todoId, provider),
            showDragHandle: true,
          ),
        );
      },
    );
  }

  Widget _buildEmptyWidget(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF52D681).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Color(0xFF52D681),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<TodosProvider>().refreshTodos(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF52D681),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TodoFilterBottomSheet(),
    );
  }

  void _navigateToCreateTodo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateTodoPage(),
      ),
    );
  }

  void _navigateToEditTodo(Todo todo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTodoPage(todo: todo),
      ),
    );
  }

  Future<void> _deleteTodo(int todoId, TodosProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: const Text('Are you sure you want to delete this todo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.deleteTodo(todoId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todo deleted successfully'),
            backgroundColor: Color(0xFF52D681),
          ),
        );
      }
    }
  }
}
