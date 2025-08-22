<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Customers\Models\Staff;
use App\Modules\Customers\Models\Client;
use App\Modules\Leads\Models\Lead;
use App\Modules\Tasks\Models\Task;
use App\Modules\Meetings\Models\Meeting;
use App\Modules\Tickets\Models\Ticket;
use App\Modules\Goals\Models\Goal;
use App\Modules\MobileAPI\Resources\DashboardResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class DashboardController extends Controller
{
    /**
     * Get dashboard overview data for mobile app
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            // Get date range (default to current month)
            $startDate = $request->get('start_date', Carbon::now()->startOfMonth());
            $endDate = $request->get('end_date', Carbon::now()->endOfMonth());
            
            $data = [
                'overview' => $this->getOverviewStats($staff, $businessId),
                'recent_activities' => $this->getRecentActivities($staff, $businessId),
                'upcoming_events' => $this->getUpcomingEvents($staff, $businessId),
                'performance_metrics' => $this->getPerformanceMetrics($staff, $businessId, $startDate, $endDate),
                'quick_actions' => $this->getQuickActions(),
            ];

            return response()->json([
                'success' => true,
                'data' => $data
            ]);

        } catch (\Exception $e) {
            Log::info('Failed to load dashboard', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to load dashboard',
                'errors' => ['server' => ['An error occurred while loading dashboard']]
            ], 500);
        }
    }

    /**
     * Get overview statistics
     */
    private function getOverviewStats(Staff $staff, int $businessId): array
    {
        return [
            'total_leads' => Lead::where('business_id', $businessId)->count(),
            'my_leads' => Lead::where('assigned_to', $staff->id())->count(),
            'total_clients' => Client::where('business_id', $businessId)->count(),
            'my_tasks' => Task::whereHas('team', function($query) use ($staff) {
                $query->where('user_id', $staff->id())->where('user_type', Staff::class);
            })->count(),
            'pending_tasks' => Task::whereHas('team', function($query) use ($staff) {
                $query->where('user_id', $staff->id())->where('user_type', Staff::class);
            })->whereIn('status_id', [0, 1])->count(),
            'completed_tasks' => Task::whereHas('team', function($query) use ($staff) {
                $query->where('user_id', $staff->id())->where('user_type', Staff::class);
            })->where('status_id', 2)->count(),
            'open_tickets' => Ticket::where('business_id', $businessId)
                                  ->where('status_id', 0)->count(),
            'my_meetings_today' => Meeting::whereHas('attendees', function($query) use ($staff) {
                $query->where('user_id', $staff->id())->where('user_type', Staff::class);
            })->whereDate('date', Carbon::today())->count(),
        ];
    }

    /**
     * Get recent activities
     */
    private function getRecentActivities(Staff $staff, int $businessId): array
    {
        $activities = [];

        // Recent leads
        $recentLeads = Lead::where('business_id', $businessId)
                          ->latest()
                          ->limit(5)
                          ->get(['lead_id', 'first_name', 'last_name','email', 'created_at']);

        foreach ($recentLeads as $lead) {
            $activities[] = [
                'type' => 'lead_created',
                'title' => 'New Lead Added',
                'description' => "Lead: {$lead->first_name} {$lead->last_name}",
                'timestamp' => $lead->created_at,
                'icon' => 'user-plus',
                'color' => 'success'
            ];
        }

        // Recent tasks
        $recentTasks = Task::whereHas('team', function($query) use ($staff) {
            $query->where('user_id', $staff->id())->where('user_type', Staff::class);
        })->latest()->limit(5)->get(['task_id', 'name', 'created_at', 'status_id']);

        foreach ($recentTasks as $task) {
            $activities[] = [
                'type' => 'task_assigned',
                'title' => 'Task Assigned',
                'description' => "Task: {$task->name}",
                'timestamp' => $task->created_at,
                'icon' => 'check-circle',
                'color' => 'info'
            ];
        }

        // Sort by timestamp descending and limit to 10
        usort($activities, function($a, $b) {
            return $b['timestamp'] <=> $a['timestamp'];
        });

        return array_slice($activities, 0, 10);
    }

    /**
     * Get upcoming events
     */
    private function getUpcomingEvents(Staff $staff, int $businessId): array
    {
        $events = [];

        // Upcoming meetings
        $upcomingMeetings = Meeting::whereHas('attendees', function($query) use ($staff) {
            $query->where('user_id', $staff->id())->where('user_type', Staff::class);
        })->where('start_time', '>=', Carbon::now())
          ->orderBy('start_time')
          ->limit(5)
          ->get(['id', 'title', 'start_time', 'end_time']);

        foreach ($upcomingMeetings as $meeting) {
            $events[] = [
                'id' => $meeting->id,
                'type' => 'meeting',
                'title' => $meeting->title,
                'start_time' => $meeting->start_time,
                'end_time' => $meeting->end_time,
                'icon' => 'calendar',
                'color' => 'primary'
            ];
        }

        // Task deadlines
        $upcomingTasks = Task::whereHas('team', function($query) use ($staff) {
            $query->where('user_id', $staff->id())->where('user_type', Staff::class);
        })->whereNotNull('due_date')
          ->where('due_date', '>=', Carbon::now())
          ->where('status_id', '!=', 3) // Not completed
          ->orderBy('due_date')
          ->limit(5)
          ->get(['task_id', 'name', 'due_date']);

        foreach ($upcomingTasks as $task) {
            $events[] = [
                'id' => $task->task_id,
                'type' => 'task',
                'title' => "Task Due: {$task->name}",
                'start_time' => $task->due_date,
                'end_time' => null,
                'icon' => 'clock',
                'color' => 'warning'
            ];
        }

        // Sort by start_time
        usort($events, function($a, $b) {
            return $a['start_time'] <=> $b['start_time'];
        });

        return array_slice($events, 0, 10);
    }

    /**
     * Get performance metrics
     */
    private function getPerformanceMetrics(Staff $staff, int $businessId, $startDate, $endDate): array
    {
        return [
            'leads_converted' => Lead::where('assigned_to', $staff->id())
                                   ->whereBetween('created_at', [$startDate, $endDate])
                                   ->where('status_id', 3)
                                   ->count(),
            'tasks_completed' => Task::whereHas('team', function($query) use ($staff) {
                $query->where('user_id', $staff->id())->where('user_type', Staff::class);
            })->whereBetween('updated_at', [$startDate, $endDate])
              ->where('status_id', 2)
              ->count(),
            'meetings_attended' => Meeting::whereHas('attendees', function($query) use ($staff) {
                $query->where('user_id', $staff->id())->where('user_type', Staff::class);
            })->whereBetween('date', [$startDate, $endDate])
              ->count(),
            'goals_achieved' => Goal::where('user_id', $staff->id())
                                  ->where('user_type', Staff::class)
                                  ->whereBetween('created_at', [$startDate, $endDate])
                                  ->where('status_id', 3)
                                  ->count(),
        ];
    }

    /**
     * Get quick actions for mobile app
     */
    private function getQuickActions(): array
    {
        return [
            [
                'id' => 'add_lead',
                'title' => 'Add Lead',
                'description' => 'Create a new lead',
                'icon' => 'user-plus',
                'color' => 'success',
                'route' => '/leads/create'
            ],
            [
                'id' => 'add_task',
                'title' => 'Add Task',
                'description' => 'Create a new task',
                'icon' => 'plus-circle',
                'color' => 'info',
                'route' => '/tasks/create'
            ],
            [
                'id' => 'schedule_meeting',
                'title' => 'Schedule Meeting',
                'description' => 'Schedule a new meeting',
                'icon' => 'calendar-plus',
                'color' => 'primary',
                'route' => '/meetings/create'
            ],
            [
                'id' => 'view_clients',
                'title' => 'View Clients',
                'description' => 'Browse all clients',
                'icon' => 'users',
                'color' => 'secondary',
                'route' => '/clients'
            ],
            [
                'id' => 'view_reports',
                'title' => 'View Reports',
                'description' => 'Access reports and analytics',
                'icon' => 'bar-chart',
                'color' => 'warning',
                'route' => '/reports'
            ],
            [
                'id' => 'my_goals',
                'title' => 'My Goals',
                'description' => 'Track your goals',
                'icon' => 'target',
                'color' => 'danger',
                'route' => '/goals'
            ]
        ];
    }

    /**
     * Get dashboard statistics for charts
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $period = $request->get('period', 'month'); // day, week, month, year
            
            $data = [
                'leads_chart' => $this->getLeadsChartData($businessId, $period),
                'tasks_chart' => $this->getTasksChartData($staff, $period),
                'conversion_rates' => $this->getConversionRates($businessId, $period),
            ];

            return response()->json([
                'success' => true,
                'data' => $data
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load statistics',
                'errors' => ['server' => ['An error occurred while loading statistics']]
            ], 500);
        }
    }

    /**
     * Get leads chart data
     */
    private function getLeadsChartData(int $businessId, string $period): array
    {
        $dateFormat = match($period) {
            'day' => '%H:00',
            'week' => '%Y-%m-%d',
            'month' => '%Y-%m-%d',
            'year' => '%Y-%m',
            default => '%Y-%m-%d'
        };

        $startDate = match($period) {
            'day' => Carbon::today(),
            'week' => Carbon::now()->startOfWeek(),
            'month' => Carbon::now()->startOfMonth(),
            'year' => Carbon::now()->startOfYear(),
            default => Carbon::now()->startOfMonth()
        };

        $leads = Lead::where('business_id', $businessId)
                    ->where('created_at', '>=', $startDate)
                    ->selectRaw("DATE_FORMAT(created_at, '{$dateFormat}') as period, COUNT(*) as count")
                    ->groupBy('period')
                    ->orderBy('period')
                    ->get();

        return [
            'labels' => $leads->pluck('period')->toArray(),
            'data' => $leads->pluck('count')->toArray(),
        ];
    }

    /**
     * Get tasks chart data
     */
    private function getTasksChartData(Staff $staff, string $period): array
    {
        $dateFormat = match($period) {
            'day' => '%H:00',
            'week' => '%Y-%m-%d',
            'month' => '%Y-%m-%d',
            'year' => '%Y-%m',
            default => '%Y-%m-%d'
        };

        $startDate = match($period) {
            'day' => Carbon::today(),
            'week' => Carbon::now()->startOfWeek(),
            'month' => Carbon::now()->startOfMonth(),
            'year' => Carbon::now()->startOfYear(),
            default => Carbon::now()->startOfMonth()
        };

        $tasks = Task::whereHas('team', function($query) use ($staff) {
            $query->where('user_id', $staff->id())->where('user_type', Staff::class);
        })->where('created_at', '>=', $startDate)
          ->selectRaw("DATE_FORMAT(created_at, '{$dateFormat}') as period, 
                      COUNT(*) as total,
                      SUM(CASE WHEN status_id = 2 THEN 1 ELSE 0 END) as completed")
          ->groupBy('period')
          ->orderBy('period')
          ->get();

        return [
            'labels' => $tasks->pluck('period')->toArray(),
            'total' => $tasks->pluck('total')->toArray(),
            'completed' => $tasks->pluck('completed')->toArray(),
        ];
    }

    /**
     * Get conversion rates
     */
    private function getConversionRates(int $businessId, string $period): array
    {
        $startDate = match($period) {
            'day' => Carbon::today(),
            'week' => Carbon::now()->startOfWeek(),
            'month' => Carbon::now()->startOfMonth(),
            'year' => Carbon::now()->startOfYear(),
            default => Carbon::now()->startOfMonth()
        };

        $totalLeads = Lead::where('business_id', $businessId)
                         ->where('created_at', '>=', $startDate)
                         ->count();

        $convertedLeads = Lead::where('business_id', $businessId)
                             ->where('created_at', '>=', $startDate)
                             ->where('status_id', 3)
                             ->count();

        $conversionRate = $totalLeads > 0 ? round(($convertedLeads / $totalLeads) * 100, 2) : 0;

        return [
            'total_leads' => $totalLeads,
            'converted_leads' => $convertedLeads,
            'conversion_rate' => $conversionRate,
        ];
    }
}
