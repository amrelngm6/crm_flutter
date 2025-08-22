<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Tasks\Models\Task;
use App\Modules\Tasks\Services\TaskService;
use App\Modules\Tasks\Models\TaskChecklist;
use App\Modules\Core\Models\Status;
use App\Modules\Core\Models\ModelMember;
use App\Modules\Priorities\Models\Priority;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Requests\TaskRequest;
use App\Modules\MobileAPI\Resources\TaskResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    /**
     * Get paginated tasks list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Task::where('business_id', $businessId)
                        ->with(['status', 'team', 'project', 'priority']);

            // Filter by assigned tasks only 
            $query->assignedTo($staff->staff_id);

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('description', 'like', "%{$search}%");
                });
            }

            // Filter by status
            if ($request->get('status_id') > -1) {
                $query->where('status_id', $request->get('status_id'));
            }

            // Filter by priority
            if ($priority = $request->get('priority_id')) {
                $query->where('priority_id', $priority);
            }

            // Filter by model type (project, lead, etc.)
            if ($modelType = $request->get('model_type')) {
                $query->where('model_type', $modelType);
            }

            // Filter by model ID
            if ($modelId = $request->get('model_id')) {
                $query->where('model_id', $modelId);
            }

            // Filter by due date
            if ($request->get('overdue')) {
                $query->whereNotNull('due_date')
                      ->where('due_date', '<', now())
                      ->whereNull('finished_date');
            }

            if ($request->get('due_today')) {
                $query->whereDate('due_date', today());
            }

            // Filter by date range
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('created_at', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('created_at', '<=', $endDate);
            }

            // Filter by visibility
            if ($request->has('is_public')) {
                $query->where('is_public', $request->get('is_public'));
            }

            if ($request->has('visible_to_client')) {
                $query->where('visible_to_client', $request->get('visible_to_client'));
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $tasks = $query->paginate($request->get('per_page', 20));

            $loadStatusList = TaskService::loadStatusList();

            $loadPriorityList = TaskService::loadPriorityList();

            return response()->json([
                'success' => true,
                'data' => [
                    'status_list' => array_values($loadStatusList->map(function ($status) {
                        return [
                            'id' => $status->status_id,
                            'name' => $status->name,
                            'color' => $status->color,
                        ];
                    })->toArray()),
                    'priorities'=> $loadPriorityList->map(function ($priority) {
                        return [
                            'id' => $priority->priority_id,
                            'name' => $priority->name,
                            'color' => $priority->color,
                        ];
                    }),
                    'tasks' => TaskResource::collection($tasks->items()),
                    'pagination' => [
                        'current_page' => $tasks->currentPage(),
                        'last_page' => $tasks->lastPage(),
                        'per_page' => $tasks->perPage(),
                        'total' => $tasks->total(),
                        'from' => $tasks->firstItem(),
                        'to' => $tasks->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch tasks',
                'errors' => ['server' => ['An error occurred while fetching tasks: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single task details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $task = Task::where('business_id', $businessId)
                       ->with(['status', 'team', 'project', 'priority', 'checklist', 'comments', 'timesheets'])
                       ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new TaskResource($task)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found',
                'errors' => ['task' => ['Task not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch task',
                'errors' => ['server' => ['An error occurred while fetching task: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new task
     */
    public function store(TaskRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['created_by'] = $staff->staff_id;

            $task = Task::create($data);

            // Assign team members to task
            if (isset($data['team']) && is_array($data['team'])) {
                foreach ($data['team'] as $memberId) {
                    ModelMember::create([
                        'model_type' => Task::class,
                        'model_id' => $task->task_id,
                        'user_type' => Staff::class,
                        'user_id' => $memberId,
                    ]);
                }
            } else {
                // Assign to creator by default
                ModelMember::create([
                    'model_type' => Task::class,
                    'model_id' => $task->task_id,
                    'user_type' => Staff::class,
                    'user_id' => $staff->staff_id,
                ]);
            }

            // Add checklist items if provided
            if (isset($data['checklist']) && is_array($data['checklist'])) {
                foreach ($data['checklist'] as $index => $checklistItem) {
                    TaskChecklist::create([
                        'business_id' => $businessId,
                        'task_id' => $task->task_id,
                        'description' => $checklistItem['description'],
                        'points' => $checklistItem['points'] ?? 0,
                        'sort' => $index + 1,
                        'visible_to_client' => $checklistItem['visible_to_client'] ?? 0,
                        'status' => 0,
                        'created_by' => $staff->staff_id,
                    ]);
                }
            }

            $task->load(['status', 'team', 'project', 'priority', 'checklist']);

            return response()->json([
                'success' => true,
                'message' => 'Task created successfully',
                'data' => new TaskResource($task)
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
                'message' => 'Failed to create task',
                'errors' => ['server' => ['An error occurred while creating task: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update task
     */
    public function update(TaskRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $task = Task::where('business_id', $businessId)->findOrFail($id);
            
            $data = $request->validated();
            $task->update($data);

            // Update team members if provided
            if (isset($data['team']) && is_array($data['team'])) {
                // Remove existing team members
                ModelMember::where('model_type', Task::class)
                          ->where('model_id', $task->task_id)
                          ->delete();

                // Add new team members
                foreach ($data['team'] as $memberId) {
                    ModelMember::create([
                        'model_type' => Task::class,
                        'model_id' => $task->task_id,
                        'user_type' => Staff::class,
                        'user_id' => $memberId,
                    ]);
                }
            }

            // Update checklist items if provided
            if (isset($data['checklist']) && is_array($data['checklist'])) {
                // Remove existing checklist items
                TaskChecklist::where('task_id', $task->task_id)->delete();

                // Add new checklist items
                foreach ($data['checklist'] as $index => $checklistItem) {
                    TaskChecklist::create([
                        'business_id' => $businessId,
                        'task_id' => $task->task_id,
                        'description' => $checklistItem['description'],
                        'points' => $checklistItem['points'] ?? 0,
                        'sort' => $index + 1,
                        'visible_to_client' => $checklistItem['visible_to_client'] ?? 0,
                        'status' => $checklistItem['status'] ?? 0,
                        'created_by' => $staff->staff_id,
                    ]);
                }
            }

            $task->load(['status', 'team', 'project', 'priority', 'checklist']);

            return response()->json([
                'success' => true,
                'message' => 'Task updated successfully',
                'data' => new TaskResource($task)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found',
                'errors' => ['task' => ['Task not found']]
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
                'message' => 'Failed to update task',
                'errors' => ['server' => ['An error occurred while updating task: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete task
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $task = Task::where('business_id', $businessId)->findOrFail($id);
            $task->delete();

            return response()->json([
                'success' => true,
                'message' => 'Task deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found',
                'errors' => ['task' => ['Task not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete task',
                'errors' => ['server' => ['An error occurred while deleting task']]
            ], 500);
        }
    }

    /**
     * Mark task as completed
     */
    public function markCompleted(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $task = Task::where('business_id', $businessId)->findOrFail($id);
            
            // Get completed status ID
            $completedStatus = Status::where('model', Task::class)
                                   ->where('name', 'completed')
                                   ->first();

            if (!$completedStatus) {
                return response()->json([
                    'success' => false,
                    'message' => 'Completed status not found',
                    'errors' => ['status' => ['Completed status not configured']]
                ], 400);
            }

            $task->update([
                'status_id' => $completedStatus->status_id,
                'finished_date' => now(),
            ]);

            $task->load(['status', 'team', 'project', 'priority']);

            return response()->json([
                'success' => true,
                'message' => 'Task marked as completed',
                'data' => new TaskResource($task)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found',
                'errors' => ['task' => ['Task not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to mark task as completed',
                'errors' => ['server' => ['An error occurred while updating task: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get task statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Basic statistics
            $totalTasks = Task::where('business_id', $businessId)
                          ->assignedTo($staff->staff_id)
                          ->count();
            $myTasks = Task::where('business_id', $businessId)
                          ->assignedTo($staff->staff_id)
                          ->count();
            $completedTasks = Task::where('business_id', $businessId)
                          ->assignedTo($staff->staff_id)
                                 ->whereNotNull('finished_date')
                                 ->count();
            $overdueTasks = Task::where('business_id', $businessId)
                               ->assignedTo($staff->staff_id)
                               ->whereNotNull('due_date')
                               ->where('due_date', '<', now())
                               ->whereNull('finished_date')
                               ->count();
            $todayTasks = Task::where('business_id', $businessId)
                          ->assignedTo($staff->staff_id)
                             ->whereDate('due_date', today())
                             ->count();
            $upcomingTasks = Task::where('business_id', $businessId)
                                ->assignedTo($staff->staff_id)
                                ->where('due_date', '>', now())
                                ->whereNull('finished_date')
                                ->count();

            // Status breakdown
            $statusBreakdown = Task::where('tasks.business_id', $businessId)
                          ->assignedTo($staff->staff_id)
                                  ->leftJoin('status_list', 'tasks.status_id', '=', 'status_list.status_id')
                                  ->selectRaw('
                                      COALESCE(status_list.name, "No Status") as status_name, 
                                      COALESCE(status_list.color, "#6c757d") as color, 
                                      COUNT(*) as count
                                  ')
                                  ->groupBy('tasks.status_id', 'status_list.name', 'status_list.color')
                                  ->get();

            // Priority breakdown
            $priorityBreakdown = Task::where('tasks.business_id', $businessId)
                                    ->leftJoin('priorities', 'tasks.priority_id', '=', 'priorities.priority_id')
                                    ->selectRaw('
                                        COALESCE(priorities.name, "No Priority") as priority_name, 
                                        COALESCE(priorities.color, "#6c757d") as color, 
                                        COUNT(*) as count
                                    ')
                                    ->groupBy('tasks.priority_id', 'priorities.name', 'priorities.color')
                                    ->get();

            // Assignment breakdown
            $assignmentBreakdown = Task::where('tasks.business_id', $businessId)
                                      ->join('model_members', function($join) {
                                          $join->on('tasks.task_id', '=', 'model_members.model_id')
                                               ->where('model_members.model_type', Task::class);
                                      })
                                      ->join('staff', 'model_members.user_id', '=', 'staff.staff_id')
                                      ->selectRaw('
                                          CONCAT(staff.first_name, " ", staff.last_name) as staff_name,
                                          COUNT(*) as count
                                      ')
                                      ->groupBy('staff.staff_id', 'staff.first_name', 'staff.last_name')
                                      ->get();

            // Model type breakdown (tasks by related entity)
            $modelTypeBreakdown = Task::where('business_id', $businessId)
                          ->assignedTo($staff->staff_id)
                                     ->selectRaw('
                                         COALESCE(model_type, "No Model") as model_type,
                                         COUNT(*) as count
                                     ')
                                     ->groupBy('model_type')
                                     ->get()
                                     ->map(function($item) {
                                         // Clean up model type names for better display
                                         $modelName = str_replace(['App\\Modules\\', '\\Models\\'], ['', ' '], $item->model_type);
                                         $modelName = str_replace('\\', ' ', $modelName);
                                         return [
                                             'model_type' => $modelName ?: 'No Model',
                                             'count' => $item->count
                                         ];
                                     });

            // Monthly trends (last 12 months)
            $monthlyData = Task::where('business_id', $businessId)
                          ->assignedTo($staff->staff_id)
                              ->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as month, COUNT(*) as count')
                              ->where('created_at', '>=', now()->subMonths(12))
                              ->groupBy('month')
                              ->orderBy('month')
                              ->get();

            // Task completion trends (last 12 months)
            $completionTrends = Task::where('business_id', $businessId)
                          ->assignedTo($staff->staff_id)
                                   ->whereNotNull('finished_date')
                                   ->selectRaw('DATE_FORMAT(finished_date, "%Y-%m") as month, COUNT(*) as completed_count')
                                   ->where('finished_date', '>=', now()->subMonths(12))
                                   ->groupBy('month')
                                   ->orderBy('month')
                                   ->get();

            // Task aging analysis (overdue tasks by age)
            $taskAging = Task::where('business_id', $businessId)
                            ->whereNotNull('due_date')
                            ->whereNull('finished_date')
                            ->selectRaw('
                                CASE 
                                    WHEN DATEDIFF(NOW(), due_date) <= 0 THEN "Not Overdue"
                                    WHEN DATEDIFF(NOW(), due_date) <= 7 THEN "1-7 days overdue"
                                    WHEN DATEDIFF(NOW(), due_date) <= 30 THEN "8-30 days overdue"
                                    ELSE "30+ days overdue"
                                END as age_group,
                                COUNT(*) as count
                            ')
                            ->groupBy('age_group')
                            ->get();

            // Checklist completion statistics
            $checklistStats = Task::where('tasks.business_id', $businessId)
                          ->assignedTo($staff->staff_id)
                                 ->leftJoin('task_checklists', 'tasks.task_id', '=', 'task_checklists.task_id')
                                 ->selectRaw('
                                     COUNT(DISTINCT tasks.task_id) as tasks_with_checklist,
                                     COUNT(task_checklists.id) as total_checklist_items,
                                     COUNT(CASE WHEN task_checklists.status = 1 THEN 1 END) as completed_checklist_items
                                 ')
                                 ->whereNotNull('task_checklists.id')
                                 ->first();

            // Average task duration (for completed tasks)
            $avgTaskDuration = Task::where('business_id', $businessId)
                                  ->whereNotNull('finished_date')
                                  ->whereNotNull('start_date')
                                  ->selectRaw('AVG(DATEDIFF(finished_date, start_date)) as avg_duration')
                                  ->value('avg_duration');

            // Productivity metrics
            $productivityMetrics = [
                'completion_rate' => $totalTasks > 0 ? round(($completedTasks / $totalTasks) * 100, 2) : 0,
                'overdue_rate' => $totalTasks > 0 ? round(($overdueTasks / $totalTasks) * 100, 2) : 0,
                'checklist_completion_rate' => $checklistStats && $checklistStats->total_checklist_items > 0 
                    ? round(($checklistStats->completed_checklist_items / $checklistStats->total_checklist_items) * 100, 2) 
                    : 0,
            ];

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [ 
                        'total_tasks' => $totalTasks,
                        'my_tasks' => $myTasks,
                        'completed_tasks' => $completedTasks,
                        'overdue_tasks' => $overdueTasks,
                        'today_tasks' => $todayTasks,
                        'upcoming_tasks' => $upcomingTasks,
                        'avg_task_duration_days' => $avgTaskDuration ? round($avgTaskDuration, 1) : 0,
                    ],
                    'productivity_metrics' => $productivityMetrics,
                    'status_breakdown' => $statusBreakdown,
                    'priority_breakdown' => $priorityBreakdown,
                    'assignment_breakdown' => $assignmentBreakdown,
                    'model_type_breakdown' => $modelTypeBreakdown,
                    'monthly_trends' => $monthlyData,
                    'completion_trends' => $completionTrends,
                    'task_aging' => $taskAging,
                    'checklist_stats' => $checklistStats,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch task statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get task statuses for dropdown
     */
    public function getStatuses(Request $request): JsonResponse
    {
        try {
            $statuses = Status::where('model', Task::class)
                             ->select('status_id as id', 'name', 'color')
                             ->orderBy('sort_order')
                             ->get();

            return response()->json([
                'success' => true,
                'data' => $statuses
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch task statuses',
                'errors' => ['server' => ['An error occurred while fetching statuses: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get priorities for dropdown
     */
    public function getPriorities(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $priorities = Priority::where('business_id', $businessId)
                                 ->where('model', Task::class)
                                 ->select('priority_id as id', 'name', 'color', 'sort')
                                 ->orderBy('sort')
                                 ->get();

            return response()->json([
                'success' => true,
                'data' => $priorities
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch priorities',
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
     * Add checklist item
     */
    public function addChecklistItem(Request $request, int $taskId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $task = Task::where('business_id', $businessId)->findOrFail($taskId);

            $checklistItem = $task->checklist()->create([
                'description' => $request->get('description'),
                'status' => $request->get('status', 0),
                'finished' => $request->get('finished', 0),
                'finished_date' => $request->get('finished') ? now() : null,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Checklist item added successfully',
                'data' => [
                    'id' => $checklistItem->id,
                    'description' => $checklistItem->description,
                    'finished' => $checklistItem->finished,
                    'finished_date' => $checklistItem->finished_date,
                    'status' => $checklistItem->status,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to add checklist item',
                'errors' => ['server' => ['An error occurred while adding checklist item: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update checklist item
     */
    public function updateChecklistItem(Request $request, int $taskId, int $checklistId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $task = Task::where('business_id', $businessId)->findOrFail($taskId);
            $checklistItem = TaskChecklist::where('task_id', $task->task_id)
                                         ->where('id', $checklistId)
                                         ->firstOrFail();

            $checklistItem->update([
                'status' => $request->get('status', $checklistItem->status),
                'finished' => $request->get('finished', $checklistItem->finished),
                'finished_date' => $request->get('finished') ? now() : null,
                'description' => $request->get('description', $checklistItem->description),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Checklist item updated successfully',
                'data' => [
                    'id' => $checklistItem->id,
                    'description' => $checklistItem->description,
                    'finished' => $checklistItem->finished,
                    'finished_date' => $checklistItem->finished_date,
                    'status' => $checklistItem->status,
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Task or checklist item not found',
                'errors' => ['item' => ['Task or checklist item not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update checklist item',
                'errors' => ['server' => ['An error occurred while updating checklist item: ' . $e->getMessage()]]
            ], 500);
        }
    }
}
