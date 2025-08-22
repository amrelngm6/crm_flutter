import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/meetings_provider.dart';
import '../../../../core/models/meeting.dart';
import 'meeting_show_page.dart';
import '../widgets/meeting_statistics_card.dart';

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  List<Meeting> filteredMeetings = [];
  bool showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        final meetingsProvider =
            Provider.of<MeetingsProvider>(context, listen: false);
        meetingsProvider.loadMeetings();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final meetingsProvider =
          Provider.of<MeetingsProvider>(context, listen: false);
      meetingsProvider.loadMeetings(refresh: true);
      meetingsProvider.loadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
              Color(0xFF1B4D3E), // Dark teal
              Color(0xFF2D6A4F), // Medium teal
              Color(0xFF40916C), // Lighter teal
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchAndFilters(),
              _buildTabBar(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMeetingsList('all'),
                            _buildMeetingsList('today'),
                            _buildMeetingsList('upcoming'),
                            _buildMeetingsList('past'),
                            _buildStatisticsView()
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meetings'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Assigned meetings'.tr(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
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
          Consumer<MeetingsProvider>(
            builder: (context, provider, child) {
              return GestureDetector(
                onTap: provider.isLoading
                    ? null
                    : () {
                        provider.loadMeetings(refresh: true);
                        provider.loadStatistics();
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: provider.isLoading
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh,
                          color: Colors.white, size: 24),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return !showSearch
        ? Container()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search meetings...'.tr(),
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.white.withValues(alpha: 0.7)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (value) {
                        Provider.of<MeetingsProvider>(context, listen: false)
                            .searchMeetings(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _showFilterDialog,
                    icon: Icon(Icons.filter_list,
                        color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 12, left: 25, right: 25),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          )),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: const BoxDecoration(
            border: Border(
          bottom: BorderSide(
            color: Colors.white, // Green shade for meetings
            width: 2,
          ),
        )),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
        tabs: [
          Tab(text: 'All Meetings'.tr()),
          Tab(text: 'Today Meetings'.tr()),
          Tab(text: 'Upcoming Meetings'.tr()),
          Tab(text: 'Past Meetings'.tr()),
          Tab(text: 'Statistics'.tr()),
        ],
      ),
    );
  }

  Widget _buildMeetingsList(String type) {
    return Consumer<MeetingsProvider>(
      builder: (context, provider, child) {
        switch (type) {
          case 'all':
            filteredMeetings = provider.meetings;
            break;
          case 'today':
            filteredMeetings = provider.meetings
                .where((m) => m.startDate == DateTime.now())
                .toList();
            break;
          case 'upcoming':
            filteredMeetings = provider.meetings
                .where((m) => m.startDate.isAfter(DateTime.now()))
                .toList();
            break;
          case 'past':
            filteredMeetings = provider.meetings
                .where((m) => m.startDate.isBefore(DateTime.now()))
                .toList();
            break;
        }

        if (provider.isLoading && filteredMeetings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && filteredMeetings.isEmpty) {
          return _buildErrorView(provider.error!);
        }

        if (filteredMeetings.isEmpty) {
          return _buildEmptyView();
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadMeetings(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: filteredMeetings.length + (provider.hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == filteredMeetings.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final meeting = filteredMeetings[index];
              return _buildMeetingCard(meeting);
            },
          ),
        );
      },
    );
  }

  Widget _buildStatisticsView() {
    return Consumer<MeetingsProvider>(
      builder: (context, provider, child) {
        if (provider.statistics == null) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
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
                  'Failed to load statistics'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadStatistics(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadStatistics(),
          color: const Color(0xFF2E7D32),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: MeetingStatisticsCard(statistics: provider.statistics!),
          ),
        );
      },
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToMeetingDetails(meeting),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meeting.title,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (meeting.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            meeting.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(meeting.status.color)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          meeting.status.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(meeting.status.color),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meeting.formattedTimeRange,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    meeting.formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (meeting.durationMinutes != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      meeting.formattedDuration,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (meeting.hasLocation) ...[
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        meeting.location!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else if (meeting.hasUrl) ...[
                    Icon(Icons.videocam, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Video Meeting'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (meeting.attendeesCount > 0) ...[
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${meeting.attendeesCount} ${'attendees'.tr()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              if (meeting.clientName != 'No Client') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.business, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      meeting.clientName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (meeting.clientCompany.isNotEmpty) ...[
                      Text(
                        ' - ${meeting.clientCompany}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (meeting.timeUntilMeeting != null && meeting.isUpcoming) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 12, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        meeting.timeUntilMeeting!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load meetings'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Provider.of<MeetingsProvider>(context, listen: false)
                    .loadMeetings(refresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: Text('Try Again'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView([String? message]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message ?? 'No meetings found'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule your first meeting to get started'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String colorString) {
    switch (colorString.toLowerCase()) {
      case '#28a745':
      case 'green':
        return Colors.green;
      case '#007bff':
      case 'blue':
        return Colors.blue;
      case '#dc3545':
      case 'red':
        return Colors.red;
      case '#ffc107':
      case 'yellow':
        return Colors.orange;
      case '#17a2b8':
      case 'cyan':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  void _navigateToMeetingDetails(Meeting meeting) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MeetingShowPage(meeting: meeting),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<MeetingsProvider>(
        builder: (context, provider, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Meetings'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Quick Filters'.tr()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text('My Meetings'.tr()),
                      selected: provider.myMeetingsOnly,
                      onSelected: (selected) {
                        provider.toggleMyMeetingsOnly();
                      },
                    ),
                    FilterChip(
                      label: Text('Today Only'.tr()),
                      selected: provider.todayOnly,
                      onSelected: (selected) {
                        provider.toggleTodayOnly();
                      },
                    ),
                    FilterChip(
                      label: Text('Upcoming Only'.tr()),
                      selected: provider.upcomingOnly,
                      onSelected: (selected) {
                        provider.toggleUpcomingOnly();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: Text('Clear Filters'.tr()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Apply'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
