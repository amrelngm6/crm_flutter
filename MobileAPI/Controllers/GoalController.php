<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Goals\Models\Goal;
use App\Modules\Goals\Services\GoalService;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Requests\GoalRequest;
use App\Modules\MobileAPI\Resources\GoalResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Carbon\Carbon;

class GoalController extends Controller
{
    protected $goalService;

    public function __construct(GoalService $goalService)
    {
        $this->goalService = $goalService;
    }

    /**
     * Get paginated goals list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Goal::forBusiness($businessId)
                         ->with(['user', 'model', 'status']);

            // Filter by user (my goals only) if requested
            if ($request->get('my_goals_only', false)) {
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

            // Filter by model type and ID (specific entity goals)
            if ($modelType = $request->get('model_type')) {
                $query->where('model_type', $modelType);
                
                if ($modelId = $request->get('model_id')) {
                    $query->where('model_id', $modelId);
                }
            }

            // Filter by date range
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('date', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('date', '<=', $endDate);
            }

            // Filter by due date range
            if ($dueDateStart = $request->get('due_date_start')) {
                $query->whereDate('due_date', '>=', $dueDateStart);
            }
            if ($dueDateEnd = $request->get('due_date_end')) {
                $query->whereDate('due_date', '<=', $dueDateEnd);
            }

            // Filter by specific date
            if ($date = $request->get('date')) {
                $query->whereDate('date', $date);
            }

            // Filter by this week
            if ($request->get('this_week')) {
                $query->whereBetween('date', [
                    now()->startOfWeek(),
                    now()->endOfWeek()
                ]);
            }

            // Filter by this month
            if ($request->get('this_month')) {
                $query->whereBetween('date', [
                    now()->startOfMonth(),
                    now()->endOfMonth()
                ]);
            }

            // Filter due this week
            if ($request->get('due_this_week')) {
                $query->whereBetween('due_date', [
                    now()->startOfWeek(),
                    now()->endOfWeek()
                ]);
            }

            // Filter overdue goals
            if ($request->get('overdue')) {
                $query->where('due_date', '<', now())
                     ->whereNotIn('status_id', [3]); // Assuming status 3 is completed
            }

            // Filter upcoming goals (due in next 7 days)
            if ($request->get('upcoming')) {
                $query->whereBetween('due_date', [
                    now(),
                    now()->addDays(7)
                ]);
            }

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('description', 'like', "%{$search}%");
                });
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'due_date');
            $sortOrder = $request->get('sort_order', 'asc');
            $query->orderBy($sortBy, $sortOrder);

            $goals = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'goals' => GoalResource::collection($goals->items()),
                    'pagination' => [
                        'current_page' => $goals->currentPage(),
                        'last_page' => $goals->lastPage(),
                        'per_page' => $goals->perPage(),
                        'total' => $goals->total(),
                        'from' => $goals->firstItem(),
                        'to' => $goals->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch goals',
                'errors' => ['server' => ['An error occurred while fetching goals: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single goal details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $goal = Goal::forBusiness($businessId)
                        ->with(['user', 'model', 'status'])
                        ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new GoalResource($goal)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Goal not found',
                'errors' => ['goal' => ['Goal not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch goal',
                'errors' => ['server' => ['An error occurred while fetching goal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new goal
     */
    public function store(GoalRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['user_id'] = $staff->staff_id;
            $data['user_type'] = Staff::class;

            // Set default model to current user if not specified
            if (!isset($data['model_id'])) {
                $data['model_id'] = $staff->staff_id;
                $data['model_type'] = Staff::class;
            }

            $goal = $this->goalService->createGoal($data);
            $goal->load(['user', 'model', 'status']);

            return response()->json([
                'success' => true,
                'message' => 'Goal created successfully',
                'data' => new GoalResource($goal)
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
                'message' => 'Failed to create goal',
                'errors' => ['server' => ['An error occurred while creating goal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update goal
     */
    public function update(GoalRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $goal = Goal::forBusiness($businessId)->findOrFail($id);
            
            $data = $request->validated();
            $updated = $this->goalService->updateGoal($id, $data);

            if ($updated) {
                $goal->refresh();
                $goal->load(['user', 'model', 'status']);
                
                return response()->json([
                    'success' => true,
                    'message' => 'Goal updated successfully',
                    'data' => new GoalResource($goal)
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to update goal',
                'errors' => ['goal' => ['Goal could not be updated']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Goal not found',
                'errors' => ['goal' => ['Goal not found']]
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
                'message' => 'Failed to update goal',
                'errors' => ['server' => ['An error occurred while updating goal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete goal
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $goal = Goal::forBusiness($businessId)->findOrFail($id);
            $deleted = $this->goalService->deleteGoal($id);

            if ($deleted) {
                return response()->json([
                    'success' => true,
                    'message' => 'Goal deleted successfully'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete goal',
                'errors' => ['goal' => ['Goal could not be deleted']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Goal not found',
                'errors' => ['goal' => ['Goal not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete goal',
                'errors' => ['server' => ['An error occurred while deleting goal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get goals for specific model (Project, Staff, etc.)
     */
    public function getModelGoals(Request $request, string $modelType, int $modelId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Validate model type
            $allowedModelTypes = [
                'App\Modules\Projects\Models\Project',
                'App\Modules\Customers\Models\Staff',
                'App\Modules\Deals\Models\Deal',
                'App\Modules\Tasks\Models\Task',
            ];

            if (!in_array($modelType, $allowedModelTypes)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid model type',
                    'errors' => ['model_type' => ['Invalid model type specified']]
                ], 422);
            }

            $goals = Goal::forBusiness($businessId)
                         ->where('model_type', $modelType)
                         ->where('model_id', $modelId)
                         ->with(['user', 'model', 'status'])
                         ->orderBy('due_date', 'asc')
                         ->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'goals' => GoalResource::collection($goals->items()),
                    'pagination' => [
                        'current_page' => $goals->currentPage(),
                        'last_page' => $goals->lastPage(),
                        'per_page' => $goals->perPage(),
                        'total' => $goals->total(),
                        'from' => $goals->firstItem(),
                        'to' => $goals->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch model goals',
                'errors' => ['server' => ['An error occurred while fetching model goals: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Mark goal as completed
     */
    public function markCompleted(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $goal = Goal::forBusiness($businessId)->findOrFail($id);
            
            $updated = $this->goalService->updateGoal($id, [
                'status_id' => 3, // Assuming 3 is completed status
            ]);

            if ($updated) {
                $goal->refresh();
                $goal->load(['user', 'model', 'status']);
                
                return response()->json([
                    'success' => true,
                    'message' => 'Goal marked as completed',
                    'data' => new GoalResource($goal)
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to mark goal as completed',
                'errors' => ['goal' => ['Goal could not be updated']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Goal not found',
                'errors' => ['goal' => ['Goal not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to mark goal as completed',
                'errors' => ['server' => ['An error occurred while updating goal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get goal statuses for dropdown
     */
    public function getStatuses(Request $request): JsonResponse
    {
        try {
            $statuses = GoalService::loadStatusList();

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
                'message' => 'Failed to fetch goal statuses',
                'errors' => ['server' => ['An error occurred while fetching statuses: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get available model types for dropdown
     */
    public function getModelTypes(Request $request): JsonResponse
    {
        try {
            $modelTypes = [
                [
                    'value' => 'App\Modules\Projects\Models\Project',
                    'label' => 'Project',
                    'icon' => 'folder',
                ],
                [
                    'value' => 'App\Modules\Customers\Models\Staff',
                    'label' => 'Staff',
                    'icon' => 'users',
                ],
                [
                    'value' => 'App\Modules\Deals\Models\Deal',
                    'label' => 'Deal',
                    'icon' => 'dollar-sign',
                ],
                [
                    'value' => 'App\Modules\Tasks\Models\Task',
                    'label' => 'Task',
                    'icon' => 'check-square',
                ],
            ];

            return response()->json([
                'success' => true,
                'data' => $modelTypes
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch model types',
                'errors' => ['server' => ['An error occurred while fetching model types: ' . $e->getMessage()]]
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
     * Get goal statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Base query for user's goals
            $baseQuery = Goal::forBusiness($businessId)
                             ->where('user_id', $staff->staff_id)
                             ->where('user_type', Staff::class);

            $totalGoals = (clone $baseQuery)->count();
            $completedGoals = (clone $baseQuery)->where('status_id', 3)->count(); // Assuming 3 is completed
            $activeGoals = (clone $baseQuery)->where('status_id', 1)->count(); // Assuming 1 is active
            $overdueGoals = (clone $baseQuery)->where('due_date', '<', now())
                                             ->whereNotIn('status_id', [3])
                                             ->count();

            // This week's goals
            $thisWeekGoals = (clone $baseQuery)->whereBetween('due_date', [
                now()->startOfWeek(),
                now()->endOfWeek()
            ])->count();

            // This month's goals
            $thisMonthGoals = (clone $baseQuery)->whereBetween('due_date', [
                now()->startOfMonth(),
                now()->endOfMonth()
            ])->count();

            // Upcoming goals (next 7 days)
            $upcomingGoals = (clone $baseQuery)->whereBetween('due_date', [
                now(),
                now()->addDays(7)
            ])->count();

            // Model type breakdown
            $modelBreakdown = (clone $baseQuery)->selectRaw('model_type, COUNT(*) as count')
                                               ->whereNotNull('model_type')
                                               ->groupBy('model_type')
                                               ->get()
                                               ->map(function ($item) {
                                                   return [
                                                       'model_type' => $item->model_type,
                                                       'model_name' => $this->getModelDisplayName($item->model_type),
                                                       'count' => $item->count,
                                                   ];
                                               });

            // Status breakdown
            $statusBreakdown = (clone $baseQuery)->selectRaw('status_id, COUNT(*) as count')
                                                 ->with('status')
                                                 ->groupBy('status_id')
                                                 ->get()
                                                 ->map(function ($item) {
                                                     return [
                                                         'status_id' => $item->status_id,
                                                         'status_name' => $item->status->name ?? 'Unknown',
                                                         'count' => $item->count,
                                                     ];
                                                 });

            // Completion rate over time (last 30 days)
            $completionTrends = (clone $baseQuery)->selectRaw('DATE(updated_at) as date, 
                                                              SUM(CASE WHEN status_id = 3 THEN 1 ELSE 0 END) as completed,
                                                              COUNT(*) as total')
                                                 ->where('updated_at', '>=', now()->subDays(30))
                                                 ->groupBy('date')
                                                 ->orderBy('date')
                                                 ->get();

            // Progress percentage
            $progressPercentage = $totalGoals > 0 ? round(($completedGoals / $totalGoals) * 100, 1) : 0;

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_goals' => $totalGoals,
                        'completed_goals' => $completedGoals,
                        'active_goals' => $activeGoals,
                        'overdue_goals' => $overdueGoals,
                        'this_week_goals' => $thisWeekGoals,
                        'this_month_goals' => $thisMonthGoals,
                        'upcoming_goals' => $upcomingGoals,
                        'progress_percentage' => $progressPercentage,
                        'completion_rate' => $totalGoals > 0 ? round(($completedGoals / $totalGoals) * 100, 1) : 0,
                    ],
                    'model_breakdown' => $modelBreakdown,
                    'status_breakdown' => $statusBreakdown,
                    'completion_trends' => $completionTrends,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch goal statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get display name for model type
     */
    private function getModelDisplayName(string $modelType): string
    {
        $modelNames = [
            'App\Modules\Projects\Models\Project' => 'Project',
            'App\Modules\Customers\Models\Staff' => 'Staff',
            'App\Modules\Deals\Models\Deal' => 'Deal',
            'App\Modules\Tasks\Models\Task' => 'Task',
        ];

        return $modelNames[$modelType] ?? 'Unknown';
    }
}
