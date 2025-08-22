<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Actions\Models\Reminder;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Requests\ReminderRequest;
use App\Modules\MobileAPI\Resources\ReminderResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Carbon\Carbon;

class ReminderController extends Controller
{
    /**
     * Get paginated reminders list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Reminder::forBusiness($businessId)
                             ->with(['user', 'model']);

            // Filter by user (my reminders only) if requested
            if ($request->get('my_reminders_only', false)) {
                $query->where('user_id', $staff->staff_id)
                     ->where('user_type', Staff::class);
            }

            // Filter by specific user
            if ($userId = $request->get('user_id')) {
                $query->where('user_id', $userId)
                     ->where('user_type', Staff::class);
            }

            // Filter by notification status
            if ($request->has('is_notified')) {
                $query->where('is_notified', (bool) $request->get('is_notified'));
            }

            // Filter by model type and ID (specific entity reminders)
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

            // Filter by specific date
            if ($date = $request->get('date')) {
                $query->whereDate('date', $date);
            }

            // Filter by today
            if ($request->get('today')) {
                $query->whereDate('date', today());
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

            // Filter overdue reminders
            if ($request->get('overdue')) {
                $query->where('date', '<', now())
                     ->where('is_notified', false);
            }

            // Filter upcoming reminders (next 24 hours)
            if ($request->get('upcoming')) {
                $query->whereBetween('date', [
                    now(),
                    now()->addDay()
                ])->where('is_notified', false);
            }

            // Filter pending (not notified) reminders
            if ($request->get('pending')) {
                $query->where('is_notified', false);
            }

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('description', 'like', "%{$search}%");
                });
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'date');
            $sortOrder = $request->get('sort_order', 'asc');
            $query->orderBy($sortBy, $sortOrder);

            $reminders = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'reminders' => ReminderResource::collection($reminders->items()),
                    'pagination' => [
                        'current_page' => $reminders->currentPage(),
                        'last_page' => $reminders->lastPage(),
                        'per_page' => $reminders->perPage(),
                        'total' => $reminders->total(),
                        'from' => $reminders->firstItem(),
                        'to' => $reminders->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch reminders',
                'errors' => ['server' => ['An error occurred while fetching reminders: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single reminder details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $reminder = Reminder::forBusiness($businessId)
                               ->with(['user', 'model'])
                               ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new ReminderResource($reminder)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Reminder not found',
                'errors' => ['reminder' => ['Reminder not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch reminder',
                'errors' => ['server' => ['An error occurred while fetching reminder: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new reminder
     */
    public function store(ReminderRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['user_id'] = $staff->staff_id;
            $data['user_type'] = Staff::class;
            $data['is_notified'] = false;

            // Set default model to current user if not specified
            if (!isset($data['model_id'])) {
                $data['model_id'] = $staff->staff_id;
                $data['model_type'] = Staff::class;
            }

            $reminder = Reminder::create($data);
            $reminder->load(['user', 'model']);

            return response()->json([
                'success' => true,
                'message' => 'Reminder created successfully',
                'data' => new ReminderResource($reminder)
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
                'message' => 'Failed to create reminder',
                'errors' => ['server' => ['An error occurred while creating reminder: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update reminder
     */
    public function update(ReminderRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $reminder = Reminder::forBusiness($businessId)->findOrFail($id);
            
            // Check if user can edit this reminder (only the creator can edit)
            if ($reminder->user_id !== $staff->staff_id || $reminder->user_type !== Staff::class) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to edit this reminder',
                    'errors' => ['reminder' => ['You can only edit your own reminders']]
                ], 403);
            }

            $data = $request->validated();
            $updated = $reminder->update($data);

            if ($updated) {
                $reminder->refresh();
                $reminder->load(['user', 'model']);
                
                return response()->json([
                    'success' => true,
                    'message' => 'Reminder updated successfully',
                    'data' => new ReminderResource($reminder)
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to update reminder',
                'errors' => ['reminder' => ['Reminder could not be updated']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Reminder not found',
                'errors' => ['reminder' => ['Reminder not found']]
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
                'message' => 'Failed to update reminder',
                'errors' => ['server' => ['An error occurred while updating reminder: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete reminder
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $reminder = Reminder::forBusiness($businessId)->findOrFail($id);
            
            // Check if user can delete this reminder (only the creator can delete)
            if ($reminder->user_id !== $staff->staff_id || $reminder->user_type !== Staff::class) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to delete this reminder',
                    'errors' => ['reminder' => ['You can only delete your own reminders']]
                ], 403);
            }

            $deleted = $reminder->delete();

            if ($deleted) {
                return response()->json([
                    'success' => true,
                    'message' => 'Reminder deleted successfully'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete reminder',
                'errors' => ['reminder' => ['Reminder could not be deleted']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Reminder not found',
                'errors' => ['reminder' => ['Reminder not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete reminder',
                'errors' => ['server' => ['An error occurred while deleting reminder: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Mark reminder as notified
     */
    public function markNotified(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $reminder = Reminder::forBusiness($businessId)->findOrFail($id);
            
            // Check if user can mark this reminder (only the owner can mark)
            if ($reminder->user_id !== $staff->staff_id || $reminder->user_type !== Staff::class) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to mark this reminder',
                    'errors' => ['reminder' => ['You can only mark your own reminders']]
                ], 403);
            }

            $updated = $reminder->update(['is_notified' => true]);

            if ($updated) {
                $reminder->refresh();
                $reminder->load(['user', 'model']);
                
                return response()->json([
                    'success' => true,
                    'message' => 'Reminder marked as notified',
                    'data' => new ReminderResource($reminder)
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to mark reminder as notified',
                'errors' => ['reminder' => ['Reminder could not be updated']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Reminder not found',
                'errors' => ['reminder' => ['Reminder not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to mark reminder as notified',
                'errors' => ['server' => ['An error occurred while updating reminder: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Snooze reminder (postpone by specified minutes)
     */
    public function snooze(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $request->validate([
                'minutes' => 'required|integer|min:1|max:1440', // Max 24 hours
            ]);

            $reminder = Reminder::forBusiness($businessId)->findOrFail($id);
            
            // Check if user can snooze this reminder
            if ($reminder->user_id !== $staff->staff_id || $reminder->user_type !== Staff::class) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to snooze this reminder',
                    'errors' => ['reminder' => ['You can only snooze your own reminders']]
                ], 403);
            }

            $newDate = Carbon::parse($reminder->date)->addMinutes($request->minutes);
            
            $updated = $reminder->update([
                'date' => $newDate,
                'is_notified' => false, // Reset notification status
            ]);

            if ($updated) {
                $reminder->refresh();
                $reminder->load(['user', 'model']);
                
                return response()->json([
                    'success' => true,
                    'message' => "Reminder snoozed for {$request->minutes} minutes",
                    'data' => new ReminderResource($reminder)
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to snooze reminder',
                'errors' => ['reminder' => ['Reminder could not be updated']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Reminder not found',
                'errors' => ['reminder' => ['Reminder not found']]
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
                'message' => 'Failed to snooze reminder',
                'errors' => ['server' => ['An error occurred while updating reminder: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get reminders for specific model (Lead, Project, Task, etc.)
     */
    public function getModelReminders(Request $request, string $modelType, int $modelId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Validate model type
            $allowedModelTypes = [
                'App\Modules\Leads\Models\Lead',
                'App\Modules\Projects\Models\Project',
                'App\Modules\Tasks\Models\Task',
                'App\Modules\Deals\Models\Deal',
                'App\Modules\Tickets\Models\Ticket',
                'App\Modules\Customers\Models\Staff',
                'App\Modules\Proposals\Models\Proposal',
                'App\Modules\Estimates\Models\Estimate',
            ];

            if (!in_array($modelType, $allowedModelTypes)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid model type',
                    'errors' => ['model_type' => ['Invalid model type specified']]
                ], 422);
            }

            $reminders = Reminder::forBusiness($businessId)
                                 ->where('model_type', $modelType)
                                 ->where('model_id', $modelId)
                                 ->with(['user', 'model'])
                                 ->orderBy('date', 'asc')
                                 ->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'reminders' => ReminderResource::collection($reminders->items()),
                    'pagination' => [
                        'current_page' => $reminders->currentPage(),
                        'last_page' => $reminders->lastPage(),
                        'per_page' => $reminders->perPage(),
                        'total' => $reminders->total(),
                        'from' => $reminders->firstItem(),
                        'to' => $reminders->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch model reminders',
                'errors' => ['server' => ['An error occurred while fetching model reminders: ' . $e->getMessage()]]
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
                    'value' => 'App\Modules\Leads\Models\Lead',
                    'label' => 'Lead',
                    'icon' => 'user-plus',
                ],
                [
                    'value' => 'App\Modules\Projects\Models\Project',
                    'label' => 'Project',
                    'icon' => 'folder',
                ],
                [
                    'value' => 'App\Modules\Tasks\Models\Task',
                    'label' => 'Task',
                    'icon' => 'check-square',
                ],
                [
                    'value' => 'App\Modules\Deals\Models\Deal',
                    'label' => 'Deal',
                    'icon' => 'dollar-sign',
                ],
                [
                    'value' => 'App\Modules\Tickets\Models\Ticket',
                    'label' => 'Ticket',
                    'icon' => 'life-buoy',
                ],
                [
                    'value' => 'App\Modules\Customers\Models\Staff',
                    'label' => 'Staff',
                    'icon' => 'users',
                ],
                [
                    'value' => 'App\Modules\Proposals\Models\Proposal',
                    'label' => 'Proposal',
                    'icon' => 'file-text',
                ],
                [
                    'value' => 'App\Modules\Estimates\Models\Estimate',
                    'label' => 'Estimate',
                    'icon' => 'calculator',
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
     * Get reminder statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Base query for user's reminders
            $baseQuery = Reminder::forBusiness($businessId)
                                 ->where('user_id', $staff->staff_id)
                                 ->where('user_type', Staff::class);

            $totalReminders = (clone $baseQuery)->count();
            $pendingReminders = (clone $baseQuery)->where('is_notified', false)->count();
            $notifiedReminders = (clone $baseQuery)->where('is_notified', true)->count();
            $overdueReminders = (clone $baseQuery)->where('date', '<', now())
                                                  ->where('is_notified', false)
                                                  ->count();

            // Today's reminders
            $todayReminders = (clone $baseQuery)->whereDate('date', today())->count();
            $todayPendingReminders = (clone $baseQuery)->whereDate('date', today())
                                                      ->where('is_notified', false)
                                                      ->count();

            // Upcoming reminders (next 24 hours)
            $upcomingReminders = (clone $baseQuery)->whereBetween('date', [
                now(),
                now()->addDay()
            ])->where('is_notified', false)->count();

            // This week's reminders
            $thisWeekReminders = (clone $baseQuery)->whereBetween('date', [
                now()->startOfWeek(),
                now()->endOfWeek()
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

            // Daily trends (last 7 days)
            $dailyTrends = (clone $baseQuery)->selectRaw('DATE(date) as date, COUNT(*) as reminders')
                                            ->where('date', '>=', now()->subDays(7))
                                            ->groupBy('date')
                                            ->orderBy('date')
                                            ->get();

            // Notification rate
            $notificationRate = $totalReminders > 0 ? round(($notifiedReminders / $totalReminders) * 100, 1) : 0;

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_reminders' => $totalReminders,
                        'pending_reminders' => $pendingReminders,
                        'notified_reminders' => $notifiedReminders,
                        'overdue_reminders' => $overdueReminders,
                        'today_reminders' => $todayReminders,
                        'today_pending_reminders' => $todayPendingReminders,
                        'upcoming_reminders' => $upcomingReminders,
                        'this_week_reminders' => $thisWeekReminders,
                        'notification_rate' => $notificationRate,
                    ],
                    'model_breakdown' => $modelBreakdown,
                    'daily_trends' => $dailyTrends,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch reminder statistics',
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
            'App\Modules\Leads\Models\Lead' => 'Lead',
            'App\Modules\Projects\Models\Project' => 'Project',
            'App\Modules\Tasks\Models\Task' => 'Task',
            'App\Modules\Deals\Models\Deal' => 'Deal',
            'App\Modules\Tickets\Models\Ticket' => 'Ticket',
            'App\Modules\Customers\Models\Staff' => 'Staff',
            'App\Modules\Proposals\Models\Proposal' => 'Proposal',
            'App\Modules\Estimates\Models\Estimate' => 'Estimate',
        ];

        return $modelNames[$modelType] ?? 'Unknown';
    }
}
