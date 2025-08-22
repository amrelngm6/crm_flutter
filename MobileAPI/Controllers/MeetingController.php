<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Meetings\Models\Meeting;
use App\Modules\Meetings\Models\MeetingAttendee;
use App\Modules\Customers\Models\Staff;
use App\Modules\Customers\Models\Client;
use App\Modules\Meetings\Services\MeetingService;
use App\Modules\MobileAPI\Requests\MeetingRequest;
use App\Modules\MobileAPI\Resources\MeetingResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class MeetingController extends Controller
{
    protected $meetingService;

    public function __construct(MeetingService $meetingService)
    {
        $this->meetingService = $meetingService;
    }

    /**
     * Get paginated meetings list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Meeting::where('business_id', $businessId)
                           ->with(['attendees', 'client']);

            // Filter by assigned meetings 
            $query->whereHas('attendees', function($q) use ($staff) {
                $q->where('user_id', $staff->id)->where('user_type', Staff::class);
            });

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('title', 'like', "%{$search}%")
                      ->orWhere('description', 'like', "%{$search}%")
                      ->orWhere('location', 'like', "%{$search}%");
                });
            }

            // Filter by date range
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('date', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('date', '<=', $endDate);
            }

            // Filter by today's meetings
            if ($request->get('today_only') == 'true') {
                $query->whereDate('date', today());
            }

            // Filter by upcoming meetings
            if ($request->get('upcoming_only') == 'true') {
                $query->where('date', '>=', today())->where('start_time', '>=', date('H:i'));
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'date');
            $sortOrder = $request->get('sort_order', 'asc');
            $query->orderBy($sortBy, $sortOrder);

            $meetings = $query->paginate($request->get('per_page', 20));

            
            $priorities = $this->meetingService->loadPriorities();
    
            return response()->json([
                'success' => true,
                'data' => [
                    'meetings' => MeetingResource::collection($meetings->items()),
                    'priorities' => $priorities->map(function($priority) {
                        return [
                            'id' => $priority->priority_id,
                            'name' => $priority->name,
                            'color' => $priority->color ?? '#6c757d',
                            'level' => $priority->level ?? 1,
                        ];
                    }),
                    'pagination' => [
                        'current_page' => $meetings->currentPage(),
                        'last_page' => $meetings->lastPage(),
                        'per_page' => $meetings->perPage(),
                        'total' => $meetings->total(),
                        'from' => $meetings->firstItem(),
                        'to' => $meetings->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to fetch meetings: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch meetings',
                'errors' => ['server' => ['An error occurred while fetching meetings']]
            ], 500);
        }
    }

    /**
     * Get single meeting details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $meeting = Meeting::where('business_id', $businessId)
                             ->with(['attendees', 'client', 'comments'])
                             ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new MeetingResource($meeting)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Meeting not found',
                'errors' => ['meeting' => ['Meeting not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch meeting',
                'errors' => ['server' => ['An error occurred while fetching meeting']]
            ], 500);
        }
    }

    /**
     * Create new meeting
     */
    public function store(MeetingRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['created_by'] = $staff->id;

            $meeting = Meeting::create($data);

            // Assign attendees to meeting
            if (isset($data['attendees']) && is_array($data['attendees'])) {
                foreach ($data['attendees'] as $attendeeId) {
                    MeetingAttendee::create([
                        'meeting_id' => $meeting->id,
                        'user_type' => Staff::class,
                        'user_id' => $attendeeId,
                        'attendance_status' => 'pending',
                        'business_id' => $businessId,
                        'created_by' => $staff->id,
                    ]);
                }
            } else {
                // Assign to creator by default
                MeetingAttendee::create([
                    'meeting_id' => $meeting->id,
                    'user_type' => Staff::class,
                    'user_id' => $staff->id,
                    'attendance_status' => 'pending',
                    'business_id' => $businessId,
                    'created_by' => $staff->id,
                ]);
            }

            $meeting->load(['attendees', 'client']);

            return response()->json([
                'success' => true,
                'message' => 'Meeting created successfully',
                'data' => new MeetingResource($meeting)
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create meeting',
                'errors' => ['server' => ['An error occurred while creating meeting']]
            ], 500);
        }
    }

    /**
     * Update meeting
     */
    public function update(MeetingRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $meeting = Meeting::where('business_id', $businessId)->findOrFail($id);
            
            $data = $request->validated();
            $meeting->update($data);

            // Update attendees if provided
            if (isset($data['attendees']) && is_array($data['attendees'])) {
                // Remove existing attendees
                MeetingAttendee::where('meeting_id', $meeting->id)->delete();

                // Add new attendees
                foreach ($data['attendees'] as $attendeeId) {
                    MeetingAttendee::create([
                        'meeting_id' => $meeting->id,
                        'user_type' => Staff::class,
                        'user_id' => $attendeeId,
                        'attendance_status' => 'pending',
                        'business_id' => $businessId,
                        'created_by' => $staff->id,
                    ]);
                }
            }

            $meeting->load(['attendees', 'client']);

            return response()->json([
                'success' => true,
                'message' => 'Meeting updated successfully',
                'data' => new MeetingResource($meeting)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Meeting not found',
                'errors' => ['meeting' => ['Meeting not found']]
            ], 404);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update meeting',
                'errors' => ['server' => ['An error occurred while updating meeting']]
            ], 500);
        }
    }

    /**
     * Delete meeting
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $meeting = Meeting::where('business_id', $businessId)->findOrFail($id);
            $meeting->delete();

            return response()->json([
                'success' => true,
                'message' => 'Meeting deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Meeting not found',
                'errors' => ['meeting' => ['Meeting not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete meeting',
                'errors' => ['server' => ['An error occurred while deleting meeting']]
            ], 500);
        }
    }

    /**
     * Get calendar events for a specific date
     */
    public function getCalendarEvents(Request $request, string $date): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $targetDate = Carbon::parse($date);
            
            $meetings = Meeting::where('business_id', $businessId)
                              ->whereHas('attendees', function($q) use ($staff) {
                                  $q->where('user_id', $staff->id)->where('user_type', Staff::class);
                              })
                              ->whereDate('date', $targetDate)
                              ->with(['attendees', 'client'])
                              ->orderBy('date')
                              ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'date' => $targetDate->format('Y-m-d'),
                    'meetings' => MeetingResource::collection($meetings),
                    'total' => $meetings->count()
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch calendar events',
                'errors' => ['server' => ['An error occurred while fetching calendar events']]
            ], 500);
        }
    }

    /**
     * Get meeting statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Basic statistics
            $totalMeetings = Meeting::where('business_id', $businessId)->count();
            $upcomingMeetings = Meeting::where('business_id', $businessId)
                                     ->where('date', '>=', today())
                                     ->count();
            $myMeetings = Meeting::where('business_id', $businessId)
                                ->whereHas('attendees', function($q) use ($staff) {
                                    $q->where('user_id', $staff->id)->where('user_type', Staff::class);
                                })
                                ->count();
            $todayMeetings = Meeting::where('business_id', $businessId)
                                   ->whereDate('date', today())
                                   ->count();
            $completedMeetings = Meeting::where('business_id', $businessId)
                                       ->whereHas('status', function($q) {
                                           $q->where('name', 'Completed');
                                       })
                                       ->count();
            $overdueMeetings = Meeting::where('business_id', $businessId)
                                     ->where('date', '<', today())
                                     ->whereDoesntHave('status', function($q) {
                                         $q->where('name', 'Completed');
                                     })
                                     ->count();

            // Status breakdown
            $statusBreakdown = Meeting::where('meetings.business_id', $businessId)
                                    ->leftJoin('status_list', 'meetings.status_id', '=', 'status_list.status_id')
                                    ->selectRaw('
                                        COALESCE(status_list.name, "No Status") as status_name, 
                                        COALESCE(status_list.color, "#6c757d") as color, 
                                        COUNT(*) as count
                                    ')
                                    ->groupBy('meetings.status_id', 'status_list.name', 'status_list.color')
                                    ->get();

            // Priority breakdown
            $priorityBreakdown = Meeting::where('meetings.business_id', $businessId)
                                       ->leftJoin('priorities', 'meetings.priority_id', '=', 'priorities.priority_id')
                                       ->selectRaw('
                                           COALESCE(priorities.name, "No Priority") as priority_name, 
                                           COALESCE(priorities.color, "#6c757d") as color, 
                                           COUNT(*) as count
                                       ')
                                       ->groupBy('meetings.priority_id', 'priorities.name', 'priorities.color')
                                       ->get();

            // Meeting type breakdown (online vs offline)
            $typeBreakdown = Meeting::where('business_id', $businessId)
                                   ->selectRaw('
                                       CASE 
                                           WHEN is_online = 1 THEN "Online" 
                                           ELSE "In-Person" 
                                       END as meeting_type,
                                       COUNT(*) as count
                                   ')
                                   ->groupBy('is_online')
                                   ->get();

            // Attendance statistics
            $attendanceStats = Meeting::where('meetings.business_id', $businessId)
                                     ->join('meeting_attendees', 'meetings.id', '=', 'meeting_attendees.meeting_id')
                                     ->selectRaw('
                                         meeting_attendees.attendance_status, 
                                         COUNT(*) as count
                                     ')
                                     ->groupBy('meeting_attendees.attendance_status')
                                     ->get();

            // Monthly trends (last 12 months)
            $monthlyData = Meeting::where('business_id', $businessId)
                                 ->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as month, COUNT(*) as count')
                                 ->where('created_at', '>=', now()->subMonths(12))
                                 ->groupBy('month')
                                 ->orderBy('month')
                                 ->get();

            // Weekly schedule overview (current week)
            $weeklySchedule = Meeting::where('business_id', $businessId)
                                    ->whereBetween('date', [
                                        now()->startOfWeek()->toDateString(),
                                        now()->endOfWeek()->toDateString()
                                    ])
                                    ->selectRaw('
                                        DAYNAME(date) as day_name,
                                        DATE(date) as date,
                                        COUNT(*) as meeting_count,
                                        SUM(
                                            CASE 
                                                WHEN end_time IS NOT NULL 
                                                THEN TIME_TO_SEC(TIMEDIFF(end_time, start_time)) / 60
                                                ELSE 60
                                            END
                                        ) as total_minutes
                                    ')
                                    ->groupBy('date', 'day_name')
                                    ->orderBy('date')
                                    ->get();

            // Average meeting duration
            $avgDuration = Meeting::where('business_id', $businessId)
                                 ->whereNotNull('end_time')
                                 ->selectRaw('
                                     AVG(TIME_TO_SEC(TIMEDIFF(end_time, start_time)) / 60) as avg_minutes
                                 ')
                                 ->value('avg_minutes');

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_meetings' => $totalMeetings,
                        'upcoming_meetings' => $upcomingMeetings,
                        'my_meetings' => $myMeetings,
                        'today_meetings' => $todayMeetings,
                        'completed_meetings' => $completedMeetings,
                        'overdue_meetings' => $overdueMeetings,
                        'completion_rate' => $totalMeetings > 0 ? round(($completedMeetings / $totalMeetings) * 100, 2) : 0,
                        'avg_duration_minutes' => $avgDuration ? round($avgDuration, 2) : 0,
                    ],
                    'status_breakdown' => $statusBreakdown,
                    'priority_breakdown' => $priorityBreakdown,
                    'type_breakdown' => $typeBreakdown,
                    'attendance_breakdown' => $attendanceStats,
                    'monthly_trends' => $monthlyData,
                    'weekly_schedule' => $weeklySchedule,
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to fetch meeting statistics: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch meeting statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics']]
            ], 500);
        }
    }

    /**
     * Get meeting statuses for dropdown
     */
    public function getStatuses(Request $request): JsonResponse
    {
        try {
            $statuses = $this->meetingService->loadStatusList();

            return response()->json([
                'success' => true,
                'data' => $statuses->map(function($status) {
                    return [
                        'id' => $status->status_id,
                        'name' => $status->name,
                        'color' => $status->color ?? '#6c757d',
                        'description' => $status->description ?? null,
                    ];
                })
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch meeting statuses',
                'errors' => ['server' => ['An error occurred while fetching statuses: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get meeting priorities for dropdown
     */
    public function getPriorities(Request $request): JsonResponse
    {
        try {
            $priorities = $this->meetingService->loadPriorities();

            return response()->json([
                'success' => true,
                'data' => $priorities->map(function($priority) {
                    return [
                        'id' => $priority->priority_id,
                        'name' => $priority->name,
                        'color' => $priority->color ?? '#6c757d',
                        'level' => $priority->level ?? 1,
                    ];
                })
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch meeting priorities',
                'errors' => ['server' => ['An error occurred while fetching priorities: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get staff members for assignment dropdown
     */
    public function getStaffMembers(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $staffMembers = Staff::where('business_id', $businessId)
                                ->where('status', 1)
                                ->select('staff_id as id', 'first_name', 'last_name', 'email', 'picture')
                                ->orderBy('first_name')
                                ->get()
                                ->map(function ($member) {
                                    return [
                                        'id' => $member->id,
                                        'name' => $member->first_name . ' ' . $member->last_name,
                                        'email' => $member->email,
                                        'avatar' => $member->picture ? asset('storage/' . $member->picture) : null,
                                    ];
                                });

            return response()->json([
                'success' => true,
                'data' => $staffMembers
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch staff members',
                'errors' => ['server' => ['An error occurred while fetching staff members: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get clients for meeting creation dropdown
     */
    public function getClients(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $clients = Client::where('business_id', $businessId)
                           ->where('status', 1)
                           ->select('client_id as id', 'first_name', 'last_name', 'email', 'phone', 'type')
                           ->orderBy('first_name')
                           ->get()
                           ->map(function ($client) {
                               return [
                                   'id' => $client->id,
                                   'name' => $client->first_name . ' ' . $client->last_name,
                                   'email' => $client->email,
                                   'phone' => $client->phone,
                                   'company_name' => $client->type,
                               ];
                           });

            return response()->json([
                'success' => true,
                'data' => $clients
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch clients',
                'errors' => ['server' => ['An error occurred while fetching clients: ' . $e->getMessage()]]
            ], 500);
        }
    }
}
