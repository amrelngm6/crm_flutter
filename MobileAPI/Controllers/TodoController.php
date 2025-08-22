<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Todos\Models\Todo;
use App\Modules\Todos\Services\TodoService;
use App\Modules\Priorities\Models\Priority;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Requests\TodoRequest;
use App\Modules\MobileAPI\Resources\TodoResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TodoController extends Controller
{
    protected $todoService;

    public function __construct(TodoService $todoService)
    {
        $this->todoService = $todoService;
    }

    /**
     * Get paginated todos list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Todo::where('business_id', $businessId)
                         ->with(['priority', 'user']);

            // Filter by user (my todos only) - default behavior for todos
            $query->where('user_id', $staff->staff_id)
                    ->where('user_type', Staff::class);

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where('description', 'like', "%{$search}%");
            }

            // Filter by priority
            if ($priorityId = $request->get('priority_id')) {
                $query->where('priority_id', $priorityId);
            }

            // Filter by status
            if ($request->get('status_id') > -1) {
                $query->where('status_id', $request->get('status_id'));
            }

            // Filter by completion status
            if ($request->has('completed')) {
                if ($request->get('completed') == 'true') {
                    $query->where('status_id', 3); // Assuming 3 = completed
                } else {
                    $query->where('status_id', '!=', 3); // Not completed
                }
            }

            // Filter by date
            if ($date = $request->get('date')) {
                $query->whereDate('date', $date);
            }

            // Filter by date range
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('date', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('date', '<=', $endDate);
            }

            // Filter overdue todos
            if ($request->get('overdue') && $request->get('overdue') == 'true') {
                $query->whereDate('date', '<', today())
                     ->where('status_id', '!=', 3); // Not completed
            }

            // Filter today's todos
            if ($request->get('today') && $request->get('today') == 'true') {
                $query->whereDate('date', today());
            }

            // Filter this week's todos
            if ($request->get('this_week') && $request->get('this_week') == 'true') {
                $query->whereBetween('date', [
                    now()->startOfWeek(),
                    now()->endOfWeek()
                ]);
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'sort');
            $sortOrder = $request->get('sort_order', 'asc');
            
            // Default sorting: incomplete first, then by sort order, then by date
            if ($sortBy === 'default') {
                $query->orderBy('status_id', 'asc')
                     ->orderBy('sort', 'asc')
                     ->orderBy('date', 'asc');
            } else {
                $query->orderBy($sortBy, $sortOrder);
            }

            $todos = $query->paginate($request->get('per_page', 50));

            return response()->json([
                'success' => true,
                'data' => [
                    'todos' => TodoResource::collection($todos->items()),
                    'pagination' => [
                        'current_page' => $todos->currentPage(),
                        'last_page' => $todos->lastPage(),
                        'per_page' => $todos->perPage(),
                        'total' => $todos->total(),
                        'from' => $todos->firstItem(),
                        'to' => $todos->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch todos',
                'errors' => ['server' => ['An error occurred while fetching todos: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single todo details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $todo = Todo::where('business_id', $businessId)
                       ->with(['priority', 'user'])
                       ->findOrFail($id);

            // Check if user has access to this todo
            if ($todo->user_id != $staff->staff_id || $todo->user_type != Staff::class) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized access to todo',
                    'errors' => ['todo' => ['You do not have access to this todo']]
                ], 403);
            }

            return response()->json([
                'success' => true,
                'data' => new TodoResource($todo)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Todo not found',
                'errors' => ['todo' => ['Todo not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch todo',
                'errors' => ['server' => ['An error occurred while fetching todo: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new todo
     */
    public function store(TodoRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['user_id'] = $staff->staff_id;
            $data['user_type'] = Staff::class;

            // Set default sort order if not provided
            if (!isset($data['sort'])) {
                $lastSort = Todo::where('business_id', $businessId)
                               ->where('user_id', $staff->staff_id)
                               ->max('sort');
                $data['sort'] = ($lastSort ?? 0) + 1;
            }

            $todo = $this->todoService->createTodo($data);
            $todo->load(['priority', 'user']);

            return response()->json([
                'success' => true,
                'message' => 'Todo created successfully',
                'data' => new TodoResource($todo)
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
                'message' => 'Failed to create todo',
                'errors' => ['server' => ['An error occurred while creating todo: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update todo
     */
    public function update(TodoRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $todo = Todo::where('business_id', $businessId)
                       ->where('user_id', $staff->staff_id)
                       ->where('user_type', Staff::class)
                       ->findOrFail($id);
            
            $data = $request->validated();
            
            // Update finished time if marking as completed
            if (isset($data['status_id']) && $data['status_id'] == 1 && $todo->status_id != 1) {
                $data['finished_time'] = now();
            } elseif (isset($data['status_id']) && $data['status_id'] != 1) {
                $data['finished_time'] = null;
            }

            $updatedTodo = $this->todoService->updateTodo($id, $data);
            $updatedTodo->load(['priority', 'user']);

            return response()->json([
                'success' => true,
                'message' => 'Todo updated successfully',
                'data' => new TodoResource($updatedTodo)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Todo not found',
                'errors' => ['todo' => ['Todo not found']]
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
                'message' => 'Failed to update todo',
                'errors' => ['server' => ['An error occurred while updating todo: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete todo
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $todo = Todo::where('business_id', $businessId)
                       ->where('user_id', $staff->staff_id)
                       ->where('user_type', Staff::class)
                       ->findOrFail($id);

            $deleted = $this->todoService->deleteTodo($id);

            if ($deleted) {
                return response()->json([
                    'success' => true,
                    'message' => 'Todo deleted successfully'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete todo',
                'errors' => ['todo' => ['Todo could not be deleted']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Todo not found',
                'errors' => ['todo' => ['Todo not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete todo',
                'errors' => ['server' => ['An error occurred while deleting todo: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Mark todo as completed
     */
    public function markCompleted(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $todo = Todo::where('business_id', $businessId)
                       ->where('user_id', $staff->staff_id)
                       ->where('user_type', Staff::class)
                       ->findOrFail($id);

            $updatedTodo = $this->todoService->updateTodo($id, [
                'status_id' => 1, // Completed
                'finished_time' => now()
            ]);

            $updatedTodo->load(['priority', 'user']);

            return response()->json([
                'success' => true,
                'message' => 'Todo marked as completed',
                'data' => new TodoResource($updatedTodo)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Todo not found',
                'errors' => ['todo' => ['Todo not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to mark todo as completed',
                'errors' => ['server' => ['An error occurred while updating todo: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Mark todo as incomplete
     */
    public function markIncomplete(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $todo = Todo::where('business_id', $businessId)
                       ->where('user_id', $staff->staff_id)
                       ->where('user_type', Staff::class)
                       ->findOrFail($id);

            $updatedTodo = $this->todoService->updateTodo($id, [
                'status_id' => 0, // Incomplete
                'finished_time' => null
            ]);

            $updatedTodo->load(['priority', 'user']);

            return response()->json([
                'success' => true,
                'message' => 'Todo marked as incomplete',
                'data' => new TodoResource($updatedTodo)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Todo not found',
                'errors' => ['todo' => ['Todo not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to mark todo as incomplete',
                'errors' => ['server' => ['An error occurred while updating todo: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Reorder todos
     */
    public function reorder(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $request->validate([
                'todos' => 'required|array',
                'todos.*.id' => 'required|exists:todos,id',
                'todos.*.sort' => 'required|integer|min:1',
            ]);

            foreach ($request->todos as $todoData) {
                $todo = Todo::where('business_id', $businessId)
                           ->where('user_id', $staff->staff_id)
                           ->where('user_type', Staff::class)
                           ->where('id', $todoData['id'])
                           ->first();

                if ($todo) {
                    $todo->update(['sort' => $todoData['sort']]);
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'Todos reordered successfully'
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to reorder todos',
                'errors' => ['server' => ['An error occurred while reordering todos: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get todo priorities for dropdown
     */
    public function getPriorities(Request $request): JsonResponse
    {
        try {
            $priorities = $this->todoService->priorities();

            return response()->json([
                'success' => true,
                'data' => $priorities->map(function($priority) {
                    return [
                        'id' => $priority->priority_id,
                        'name' => $priority->name,
                        'color' => $priority->color ?? '#6c757d',
                        'level' => $priority->level ?? 1,
                        'sort' => $priority->sort ?? 0,
                    ];
                })
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch todo priorities',
                'errors' => ['server' => ['An error occurred while fetching priorities: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get todo statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Base query for user's todos
            $baseQuery = Todo::where('business_id', $businessId)
                            ->where('user_id', $staff->staff_id)
                            ->where('user_type', Staff::class);

            // Overview statistics
            $totalTodos = (clone $baseQuery)->count();
            $completedTodos = (clone $baseQuery)->where('status_id', 1)->count();
            $pendingTodos = $totalTodos - $completedTodos;

            // Time-based analytics
            $overdueTodos = (clone $baseQuery)
                           ->where('status_id', '!=', 1)
                           ->whereDate('date', '<', today())
                           ->count();

            $todayTodos = (clone $baseQuery)->whereDate('date', today())->count();
            $tomorrowTodos = (clone $baseQuery)->whereDate('date', today()->addDay())->count();

            $thisWeekTodos = (clone $baseQuery)
                           ->whereBetween('date', [
                               now()->startOfWeek(),
                               now()->endOfWeek()
                           ])
                           ->count();

            $nextWeekTodos = (clone $baseQuery)
                           ->whereBetween('date', [
                               now()->addWeek()->startOfWeek(),
                               now()->addWeek()->endOfWeek()
                           ])
                           ->count();

            // Priority breakdown
            $priorityBreakdown = Todo::where('todos.business_id', $businessId)
                                    ->where('user_id', $staff->staff_id)
                                    ->where('user_type', Staff::class)
                                    ->leftJoin('priorities', 'todos.priority_id', '=', 'priorities.priority_id')
                                    ->selectRaw('priorities.name as priority_name, priorities.color, priorities.priority_id, COUNT(*) as count, SUM(CASE WHEN todos.status_id = 1 THEN 1 ELSE 0 END) as completed')
                                    ->groupBy('priorities.priority_id', 'priorities.name', 'priorities.color')
                                    ->get();

            // Daily completion trends (last 30 days)
            $dailyTrends = Todo::where('todos.business_id', $businessId)
                              ->where('user_id', $staff->staff_id)
                              ->where('user_type', Staff::class)
                              ->where('status_id', 1)
                              ->where('finished_time', '>=', now()->subDays(30))
                              ->selectRaw('DATE(finished_time) as completion_date, COUNT(*) as completed')
                              ->groupBy('completion_date')
                              ->orderBy('completion_date')
                              ->get();

            // Weekly productivity
            $weeklyProductivity = Todo::where('todos.business_id', $businessId)
                                     ->where('user_id', $staff->staff_id)
                                     ->where('user_type', Staff::class)
                                     ->where('status_id', 1)
                                     ->where('finished_time', '>=', now()->subWeeks(4))
                                     ->selectRaw('YEARWEEK(finished_time) as week, COUNT(*) as completed')
                                     ->groupBy('week')
                                     ->orderBy('week')
                                     ->get();

            // Overdue analysis
            $overdueAnalysis = Todo::where('todos.business_id', $businessId)
                                  ->where('user_id', $staff->staff_id)
                                  ->where('user_type', Staff::class)
                                  ->where('status_id', '!=', 1)
                                  ->whereDate('date', '<', today())
                                  ->selectRaw('
                                      CASE 
                                          WHEN DATEDIFF(CURDATE(), date) <= 7 THEN "1_week"
                                          WHEN DATEDIFF(CURDATE(), date) <= 30 THEN "1_month"
                                          WHEN DATEDIFF(CURDATE(), date) <= 90 THEN "3_months"
                                          ELSE "over_3_months"
                                      END as overdue_period,
                                      COUNT(*) as count
                                  ')
                                  ->groupBy('overdue_period')
                                  ->get()
                                  ->keyBy('overdue_period');

            // Completion performance
            $avgCompletionTime = Todo::where('business_id', $businessId)
                                    ->where('user_id', $staff->staff_id)
                                    ->where('user_type', Staff::class)
                                    ->where('status_id', 1)
                                    ->whereNotNull('finished_time')
                                    ->selectRaw('AVG(DATEDIFF(finished_time, date)) as avg_days')
                                    ->value('avg_days');

            // Recent activity (last 7 days)
            $recentActivity = [
                'created' => (clone $baseQuery)->where('created_at', '>=', now()->subDays(7))->count(),
                'completed' => (clone $baseQuery)->where('status_id', 1)->where('finished_time', '>=', now()->subDays(7))->count(),
                'overdue_created' => (clone $baseQuery)->where('created_at', '>=', now()->subDays(7))->whereDate('date', '<', today())->count(),
            ];

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_todos' => $totalTodos,
                        'completed_todos' => $completedTodos,
                        'pending_todos' => $pendingTodos,
                        'overdue_todos' => $overdueTodos,
                        'today_todos' => $todayTodos,
                        'tomorrow_todos' => $tomorrowTodos,
                        'this_week_todos' => $thisWeekTodos,
                        'next_week_todos' => $nextWeekTodos,
                        'completion_rate' => $totalTodos > 0 ? round(($completedTodos / $totalTodos) * 100, 2) : 0,
                        'overdue_rate' => $totalTodos > 0 ? round(($overdueTodos / $totalTodos) * 100, 2) : 0,
                        'avg_completion_days' => round($avgCompletionTime ?? 0, 1),
                    ],
                    'priority_breakdown' => $priorityBreakdown,
                    'overdue_analysis' => $overdueAnalysis,
                    'recent_activity' => $recentActivity,
                    'daily_trends' => $dailyTrends,
                    'weekly_productivity' => $weeklyProductivity,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch todo statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }
}
