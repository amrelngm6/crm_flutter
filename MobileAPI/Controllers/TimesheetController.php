<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Timesheets\Models\Timesheet;
use App\Modules\Timesheets\Services\TimesheetService;
use App\Modules\Core\Models\Status;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Requests\TimesheetRequest;
use App\Modules\MobileAPI\Resources\TimesheetResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Carbon\Carbon;

class TimesheetController extends Controller
{
    protected $timesheetService;

    public function __construct(TimesheetService $timesheetService)
    {
        $this->timesheetService = $timesheetService;
    }

    /**
     * Get paginated timesheets list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Timesheet::forBusiness($businessId)
                              ->with(['user', 'model']);

            // Filter by user (my timesheets only) if requested
            if ($request->get('my_timesheets_only', false)) {
                $query->where('user_id', $staff->staff_id)
                     ->where('user_type', Staff::class);
            }

            // Filter by specific user
            if ($userId = $request->get('user_id')) {
                $query->where('user_id', $userId)
                     ->where('user_type', Staff::class);
            }

            // Filter by status
            if ($statusId = $request->get('status_id')) {
                $query->where('status_id', $statusId);
            }

            // Filter by model type
            if ($modelType = $request->get('model_type')) {
                $query->where('model_type', $modelType);
            }

            // Filter by model ID
            if ($modelId = $request->get('model_id')) {
                $query->where('model_id', $modelId);
            }

            // Filter by date range
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('start', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('start', '<=', $endDate);
            }

            // Filter by specific date
            if ($date = $request->get('date')) {
                $query->whereDate('start', $date);
            }

            // Filter by this week
            if ($request->get('this_week')) {
                $query->whereBetween('start', [
                    now()->startOfWeek(),
                    now()->endOfWeek()
                ]);
            }

            // Filter by this month
            if ($request->get('this_month')) {
                $query->whereBetween('start', [
                    now()->startOfMonth(),
                    now()->endOfMonth()
                ]);
            }

            // Filter active timesheets (no end time)
            if ($request->get('active_only')) {
                $query->whereNull('end');
            }

            // Filter completed timesheets (has end time)
            if ($request->get('completed_only')) {
                $query->whereNotNull('end');
            }

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where('notes', 'like', "%{$search}%");
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'start');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $timesheets = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'timesheets' => TimesheetResource::collection($timesheets->items()),
                    'pagination' => [
                        'current_page' => $timesheets->currentPage(),
                        'last_page' => $timesheets->lastPage(),
                        'per_page' => $timesheets->perPage(),
                        'total' => $timesheets->total(),
                        'from' => $timesheets->firstItem(),
                        'to' => $timesheets->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch timesheets',
                'errors' => ['server' => ['An error occurred while fetching timesheets: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single timesheet details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $timesheet = Timesheet::forBusiness($businessId)
                                 ->with(['user', 'model'])
                                 ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new TimesheetResource($timesheet)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Timesheet not found',
                'errors' => ['timesheet' => ['Timesheet not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch timesheet',
                'errors' => ['server' => ['An error occurred while fetching timesheet: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new timesheet
     */
    public function store(TimesheetRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['created_by'] = $staff->staff_id;
            
            // Set user to current staff if not specified
            if (!isset($data['user_id'])) {
                $data['user_id'] = $staff->staff_id;
                $data['user_type'] = Staff::class;
            }

            $timesheet = $this->timesheetService->createTimesheet($data);
            $timesheet->load(['user', 'model']);

            return response()->json([
                'success' => true,
                'message' => 'Timesheet created successfully',
                'data' => new TimesheetResource($timesheet)
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
                'message' => 'Failed to create timesheet',
                'errors' => ['server' => ['An error occurred while creating timesheet: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update timesheet
     */
    public function update(TimesheetRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $timesheet = Timesheet::forBusiness($businessId)->findOrFail($id);
            
            $data = $request->validated();
            $updated = $this->timesheetService->updateTimesheet($id, $data);
            
            if ($updated) {
                $timesheet->refresh();
                $timesheet->load(['user', 'model']);
                
                return response()->json([
                    'success' => true,
                    'message' => 'Timesheet updated successfully',
                    'data' => new TimesheetResource($timesheet)
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to update timesheet',
                'errors' => ['timesheet' => ['Timesheet could not be updated']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Timesheet not found',
                'errors' => ['timesheet' => ['Timesheet not found']]
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
                'message' => 'Failed to update timesheet',
                'errors' => ['server' => ['An error occurred while updating timesheet: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete timesheet
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $timesheet = Timesheet::forBusiness($businessId)->findOrFail($id);
            $deleted = $this->timesheetService->deleteTimesheet($id);

            if ($deleted) {
                return response()->json([
                    'success' => true,
                    'message' => 'Timesheet deleted successfully'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete timesheet',
                'errors' => ['timesheet' => ['Timesheet could not be deleted']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Timesheet not found',
                'errors' => ['timesheet' => ['Timesheet not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete timesheet',
                'errors' => ['server' => ['An error occurred while deleting timesheet: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Start new timesheet (clock in)
     */
    public function start(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $request->validate([
                'model_id' => 'nullable|integer',
                'model_type' => 'nullable|string',
                'notes' => 'nullable|string|max:1000',
            ]);

            // Check if user has an active timesheet
            $activeTimesheet = Timesheet::forBusiness($businessId)
                                       ->where('user_id', $staff->staff_id)
                                       ->where('user_type', Staff::class)
                                       ->whereNull('end')
                                       ->first();

            if ($activeTimesheet) {
                return response()->json([
                    'success' => false,
                    'message' => 'You already have an active timesheet running',
                    'errors' => ['timesheet' => ['Please stop the current timesheet before starting a new one']],
                    'data' => new TimesheetResource($activeTimesheet)
                ], 422);
            }

            $data = [
                'business_id' => $businessId,
                'user_id' => $staff->staff_id,
                'user_type' => Staff::class,
                'start' => now(),
                'model_id' => $request->model_id,
                'model_type' => $request->model_type,
                'notes' => $request->notes,
                'created_by' => $staff->staff_id,
                'status_id' => 1, // Active/Running status
            ];

            $timesheet = $this->timesheetService->createTimesheet($data);
            $timesheet->load(['user', 'model']);

            return response()->json([
                'success' => true,
                'message' => 'Timesheet started successfully',
                'data' => new TimesheetResource($timesheet)
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
                'message' => 'Failed to start timesheet',
                'errors' => ['server' => ['An error occurred while starting timesheet: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Stop active timesheet (clock out)
     */
    public function stop(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $timesheet = Timesheet::forBusiness($businessId)
                                 ->where('user_id', $staff->staff_id)
                                 ->where('user_type', Staff::class)
                                 ->findOrFail($id);

            if ($timesheet->end) {
                return response()->json([
                    'success' => false,
                    'message' => 'Timesheet is already stopped',
                    'errors' => ['timesheet' => ['This timesheet is already completed']]
                ], 422);
            }

            $request->validate([
                'notes' => 'nullable|string|max:1000',
            ]);

            $data = [
                'end' => now(),
                'status_id' => 2, // Completed status
            ];

            if ($request->has('notes')) {
                $data['notes'] = $request->notes;
            }

            $updated = $this->timesheetService->updateTimesheet($id, $data);

            if ($updated) {
                $timesheet->refresh();
                $timesheet->load(['user', 'model']);

                return response()->json([
                    'success' => true,
                    'message' => 'Timesheet stopped successfully',
                    'data' => new TimesheetResource($timesheet)
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to stop timesheet',
                'errors' => ['timesheet' => ['Timesheet could not be stopped']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Timesheet not found',
                'errors' => ['timesheet' => ['Timesheet not found']]
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
                'message' => 'Failed to stop timesheet',
                'errors' => ['server' => ['An error occurred while stopping timesheet: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get active timesheet for current user
     */
    public function getActive(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $activeTimesheet = Timesheet::forBusiness($businessId)
                                       ->where('user_id', $staff->staff_id)
                                       ->where('user_type', Staff::class)
                                       ->whereNull('end')
                                       ->with(['user', 'model'])
                                       ->first();

            return response()->json([
                'success' => true,
                'data' => $activeTimesheet ? new TimesheetResource($activeTimesheet) : null
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch active timesheet',
                'errors' => ['server' => ['An error occurred while fetching active timesheet: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get timesheet statuses for dropdown
     */
    public function getStatuses(Request $request): JsonResponse
    {
        try {
            $statuses = TimesheetService::loadStatusList();

            return response()->json([
                'success' => true,
                'data' => $statuses->map(function($status) {
                    return [
                        'id' => $status->status_id,
                        'name' => $status->name,
                        'color' => $status->color ?? '#6c757d',
                    ];
                })
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch timesheet statuses',
                'errors' => ['server' => ['An error occurred while fetching statuses: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get staff members for dropdown
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
                                        'avatar' => $member ? $member->avatar() : null,
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
     * Get timesheet statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Base query for user's timesheets
            $baseQuery = Timesheet::forBusiness($businessId)
                                 ->where('user_id', $staff->staff_id)
                                 ->where('user_type', Staff::class);

            $totalTimesheets = (clone $baseQuery)->count();
            $activeTimesheets = (clone $baseQuery)->whereNull('end')->count();
            $completedTimesheets = (clone $baseQuery)->whereNotNull('end')->count();

            // Calculate total hours worked
            $completedEntries = (clone $baseQuery)->whereNotNull('end')->get();
            $totalHours = $completedEntries->sum(function($timesheet) {
                if ($timesheet->start && $timesheet->end) {
                    return Carbon::parse($timesheet->end)->diffInHours(Carbon::parse($timesheet->start));
                }
                return 0;
            });

            // Today's statistics
            $todayTimesheets = (clone $baseQuery)->whereDate('start', today())->count();
            $todayHours = (clone $baseQuery)->whereDate('start', today())
                                           ->whereNotNull('end')
                                           ->get()
                                           ->sum(function($timesheet) {
                                               if ($timesheet->start && $timesheet->end) {
                                                   return Carbon::parse($timesheet->end)->diffInHours(Carbon::parse($timesheet->start));
                                               }
                                               return 0;
                                           });

            // This week's statistics
            $thisWeekTimesheets = (clone $baseQuery)->whereBetween('start', [
                now()->startOfWeek(),
                now()->endOfWeek()
            ])->count();

            $thisWeekHours = (clone $baseQuery)->whereBetween('start', [
                now()->startOfWeek(),
                now()->endOfWeek()
            ])->whereNotNull('end')->get()->sum(function($timesheet) {
                if ($timesheet->start && $timesheet->end) {
                    return Carbon::parse($timesheet->end)->diffInHours(Carbon::parse($timesheet->start));
                }
                return 0;
            });

            // Model type breakdown
            $modelBreakdown = (clone $baseQuery)->selectRaw('model_type, COUNT(*) as count, 
                                                           SUM(CASE WHEN end IS NOT NULL THEN 
                                                               TIMESTAMPDIFF(HOUR, start, end) 
                                                               ELSE 0 END) as total_hours')
                                              ->whereNotNull('model_type')
                                              ->groupBy('model_type')
                                              ->get();

            // Daily trends (last 7 days)
            $dailyTrends = (clone $baseQuery)->selectRaw('DATE(start) as date, COUNT(*) as entries,
                                                        SUM(CASE WHEN end IS NOT NULL THEN 
                                                            TIMESTAMPDIFF(HOUR, start, end) 
                                                            ELSE 0 END) as hours')
                                            ->where('start', '>=', now()->subDays(7))
                                            ->groupBy('date')
                                            ->orderBy('date')
                                            ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_timesheets' => $totalTimesheets,
                        'active_timesheets' => $activeTimesheets,
                        'completed_timesheets' => $completedTimesheets,
                        'total_hours' => round($totalHours, 2),
                        'today_timesheets' => $todayTimesheets,
                        'today_hours' => round($todayHours, 2),
                        'this_week_timesheets' => $thisWeekTimesheets,
                        'this_week_hours' => round($thisWeekHours, 2),
                        'average_hours_per_entry' => $completedTimesheets > 0 ? round($totalHours / $completedTimesheets, 2) : 0,
                    ],
                    'model_breakdown' => $modelBreakdown,
                    'daily_trends' => $dailyTrends,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch timesheet statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }
}
