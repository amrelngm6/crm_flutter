import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:medians_ai_crm/core/models/ticket.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/tickets_provider.dart';
import '../widgets/ticket_card.dart';
import '../widgets/ticket_filter_bottom_sheet.dart';
import '../widgets/ticket_statistics_card.dart';
import 'ticket_details_page.dart';
import 'create_ticket_page.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  List<Ticket> filteredTickets = [];
  bool showSearch = false;
  bool showStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        final ticketsProvider =
            Provider.of<TicketsProvider>(context, listen: false);
        ticketsProvider.loadNextPage();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ticketsProvider =
          Provider.of<TicketsProvider>(context, listen: false);
      ticketsProvider.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<TicketsProvider>().loadTickets(refresh: true);
  }

  void _onSearch(String query) {
    context.read<TicketsProvider>().searchTickets(query);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TicketFilterBottomSheet(),
    );
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
              Color(0xFF2E4057), // Support theme: Blue-gray
              Color(0xFF3F5373),
              Color(0xFF52658F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              showSearch ? _buildSearchAndFilter() : Container(),
              !showStats ? _buildTabBar() : Container(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child:
                      !showStats ? _buildTabBarView() : _buildStatisticsView(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketPage()),
          );
        },
        backgroundColor: const Color(0xFF52658F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: showStats
          ? IconButton(
              onPressed: () {
                setState(() {
                  showStats = false;
                });
              },
              icon: Icon(Icons.close),
              color: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support Tickets'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Consumer<TicketsProvider>(
                        builder: (context, provider, child) {
                          return Text(
                            '${provider.totalTickets} ${'Assigned Tickets'.tr()}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      showSearch = !showSearch;
                    });
                  },
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      showStats = !showStats;
                    });
                  },
                  icon: const Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search tickets...'.tr(),
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.filter_list,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          )),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsetsGeometry.all(5),
        labelColor: const Color(0xFF2E4057),
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'My Tickets'.tr()),
          Tab(text: 'Open'.tr()),
          Tab(text: 'Closed'.tr()),
          Tab(text: 'Overdue'.tr()),
          Tab(text: 'Due Soon'.tr()),
          Tab(text: 'Cancelled'.tr()),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTicketsList('all'), // My Tickets
        _buildTicketsList('open'), // Open
        _buildTicketsList('closed'), // Closed
        _buildTicketsList('overdue'), // Overdue
        _buildTicketsList('due_soon'), // Due Soon
        _buildTicketsList('cancelled'), // Cancelled
      ],
    );
  }

  Widget _buildTicketsList(String type) {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        switch (type) {
          case 'open':
            filteredTickets =
                provider.tickets.where((t) => t.status.id == 0).toList();
            break;
          case 'closed':
            filteredTickets =
                provider.tickets.where((t) => t.status.id == 3).toList();
            break;
          case 'overdue':
            filteredTickets =
                provider.tickets.where((t) => t.isOverdue).toList();
            break;
          case 'due_soon':
            filteredTickets = provider.tickets
                .where((t) => t.daysUntilDue != null && t.daysUntilDue! < 3)
                .toList();
            break;
          case 'cancelled':
            filteredTickets =
                provider.tickets.where((t) => t.status.id == 6).toList();
            break;
          default:
            filteredTickets = provider.tickets;
        }

        if (provider.isLoading && filteredTickets.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52658F)),
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadTickets(refresh: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF52658F),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        if (filteredTickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.support_agent_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tickets found'.tr(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Assigned Support Tickets'.tr(),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF52658F),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: filteredTickets.length + (provider.hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= filteredTickets.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF52658F)),
                    ),
                  ),
                );
              }

              final ticket = filteredTickets[index];
              return TicketCard(
                ticket: ticket,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TicketDetailsPage(ticketId: ticket.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatisticsView() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadStatistics();
          },
          color: const Color(0xFF52658F),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: provider.statistics.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TicketStatisticsCard(statistics: provider.statistics),
          ),
        );
      },
    );
  }
}
