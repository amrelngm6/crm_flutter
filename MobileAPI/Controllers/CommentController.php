<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Actions\Models\Comment;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Requests\CommentRequest;
use App\Modules\MobileAPI\Resources\CommentResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Carbon\Carbon;

class CommentController extends Controller
{
    /**
     * Get paginated comments list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Comment::where('business_id', $businessId)
                           ->with(['user', 'model', 'file']);

            // Filter by model type and ID (specific entity comments)
            if ($modelType = $request->get('model_type')) {
                $query->where('model_type', $modelType);
                
                if ($modelId = $request->get('model_id')) {
                    $query->where('model_id', $modelId);
                }
            }

            // Filter by user (my comments only) if requested
            if ($request->get('my_comments_only', false)) {
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

            // Filter by date range
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('created_at', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('created_at', '<=', $endDate);
            }

            // Filter by specific date
            if ($date = $request->get('date')) {
                $query->whereDate('created_at', $date);
            }

            // Filter by this week
            if ($request->get('this_week')) {
                $query->whereBetween('created_at', [
                    now()->startOfWeek(),
                    now()->endOfWeek()
                ]);
            }

            // Filter by this month
            if ($request->get('this_month')) {
                $query->whereBetween('created_at', [
                    now()->startOfMonth(),
                    now()->endOfMonth()
                ]);
            }

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where('message', 'like', "%{$search}%");
            }

            // Filter comments with attachments
            if ($request->get('with_files')) {
                $query->whereHas('file');
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $comments = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'comments' => CommentResource::collection($comments->items()),
                    'pagination' => [
                        'current_page' => $comments->currentPage(),
                        'last_page' => $comments->lastPage(),
                        'per_page' => $comments->perPage(),
                        'total' => $comments->total(),
                        'from' => $comments->firstItem(),
                        'to' => $comments->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch comments',
                'errors' => ['server' => ['An error occurred while fetching comments: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single comment details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $comment = Comment::where('business_id', $businessId)
                             ->with(['user', 'model', 'file'])
                             ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new CommentResource($comment)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Comment not found',
                'errors' => ['comment' => ['Comment not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch comment',
                'errors' => ['server' => ['An error occurred while fetching comment: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new comment
     */
    public function store(CommentRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['user_id'] = $staff->staff_id;
            $data['user_type'] = Staff::class;

            // Set default status if not provided
            if (!isset($data['status_id'])) {
                $data['status_id'] = 1; // Active/Published status
            }

            $comment = Comment::create($data);
            $comment->load(['user', 'model', 'file']);

            return response()->json([
                'success' => true,
                'message' => 'Comment created successfully',
                'data' => new CommentResource($comment)
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
                'message' => 'Failed to create comment',
                'errors' => ['server' => ['An error occurred while creating comment: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update comment
     */
    public function update(CommentRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $comment = Comment::where('business_id', $businessId)->findOrFail($id);
            
            // Check if user can edit this comment (only the creator can edit)
            if ($comment->user_id !== $staff->staff_id || $comment->user_type !== Staff::class) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to edit this comment',
                    'errors' => ['comment' => ['You can only edit your own comments']]
                ], 403);
            }

            $data = $request->validated();
            $updated = $comment->update($data);

            if ($updated) {
                $comment->refresh();
                $comment->load(['user', 'model', 'file']);
                
                return response()->json([
                    'success' => true,
                    'message' => 'Comment updated successfully',
                    'data' => new CommentResource($comment)
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to update comment',
                'errors' => ['comment' => ['Comment could not be updated']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Comment not found',
                'errors' => ['comment' => ['Comment not found']]
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
                'message' => 'Failed to update comment',
                'errors' => ['server' => ['An error occurred while updating comment: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete comment
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $comment = Comment::where('business_id', $businessId)->findOrFail($id);
            
            // Check if user can delete this comment (only the creator can delete)
            if ($comment->user_id !== $staff->staff_id || $comment->user_type !== Staff::class) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to delete this comment',
                    'errors' => ['comment' => ['You can only delete your own comments']]
                ], 403);
            }

            $deleted = $comment->delete();

            if ($deleted) {
                return response()->json([
                    'success' => true,
                    'message' => 'Comment deleted successfully'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete comment',
                'errors' => ['comment' => ['Comment could not be deleted']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Comment not found',
                'errors' => ['comment' => ['Comment not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete comment',
                'errors' => ['server' => ['An error occurred while deleting comment: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get comments for specific model (Lead, Project, Ticket, etc.)
     */
    public function getModelComments(Request $request, string $modelType, int $modelId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Validate model type
            $allowedModelTypes = [
                'App\Modules\Leads\Models\Lead',
                'App\Modules\Projects\Models\Project',
                'App\Modules\Tickets\Models\Ticket',
                'App\Modules\Tasks\Models\Task',
                'App\Modules\Deals\Models\Deal',
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

            $comments = Comment::where('business_id', $businessId)
                              ->where('model_type', $modelType)
                              ->where('model_id', $modelId)
                              ->with(['user', 'model', 'file'])
                              ->orderBy('created_at', 'desc')
                              ->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'comments' => CommentResource::collection($comments->items()),
                    'pagination' => [
                        'current_page' => $comments->currentPage(),
                        'last_page' => $comments->lastPage(),
                        'per_page' => $comments->perPage(),
                        'total' => $comments->total(),
                        'from' => $comments->firstItem(),
                        'to' => $comments->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch model comments',
                'errors' => ['server' => ['An error occurred while fetching model comments: ' . $e->getMessage()]]
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
                    'value' => 'App\Modules\Tickets\Models\Ticket',
                    'label' => 'Ticket',
                    'icon' => 'life-buoy',
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
     * Get comment statuses for dropdown
     */
    public function getStatuses(Request $request): JsonResponse
    {
        try {
            // Basic comment statuses - can be extended with actual Status model if needed
            $statuses = [
                [
                    'id' => 1,
                    'name' => 'Active',
                    'color' => '#28a745',
                ],
                [
                    'id' => 2,
                    'name' => 'Pending',
                    'color' => '#ffc107',
                ],
                [
                    'id' => 3,
                    'name' => 'Hidden',
                    'color' => '#6c757d',
                ],
            ];

            return response()->json([
                'success' => true,
                'data' => $statuses
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch comment statuses',
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
     * Get comment statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Base query for business comments
            $baseQuery = Comment::where('business_id', $businessId);

            $totalComments = (clone $baseQuery)->count();
            $myComments = (clone $baseQuery)->where('user_id', $staff->staff_id)
                                           ->where('user_type', Staff::class)
                                           ->count();

            // Today's statistics
            $todayComments = (clone $baseQuery)->whereDate('created_at', today())->count();
            $myTodayComments = (clone $baseQuery)->where('user_id', $staff->staff_id)
                                                ->where('user_type', Staff::class)
                                                ->whereDate('created_at', today())
                                                ->count();

            // This week's statistics
            $thisWeekComments = (clone $baseQuery)->whereBetween('created_at', [
                now()->startOfWeek(),
                now()->endOfWeek()
            ])->count();

            $myThisWeekComments = (clone $baseQuery)->where('user_id', $staff->staff_id)
                                                   ->where('user_type', Staff::class)
                                                   ->whereBetween('created_at', [
                                                       now()->startOfWeek(),
                                                       now()->endOfWeek()
                                                   ])->count();

            // Comments with attachments
            $commentsWithFiles = (clone $baseQuery)->whereHas('file')->count();

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
                                                ->groupBy('status_id')
                                                ->get();

            // Daily trends (last 7 days)
            $dailyTrends = (clone $baseQuery)->selectRaw('DATE(created_at) as date, COUNT(*) as comments')
                                            ->where('created_at', '>=', now()->subDays(7))
                                            ->groupBy('date')
                                            ->orderBy('date')
                                            ->get();

            // Top contributors
            $topContributors = (clone $baseQuery)->selectRaw('user_id, user_type, COUNT(*) as comments_count')
                                                 ->where('user_type', Staff::class)
                                                 ->groupBy('user_id', 'user_type')
                                                 ->orderBy('comments_count', 'desc')
                                                 ->limit(5)
                                                 ->with('user')
                                                 ->get()
                                                 ->map(function ($item) {
                                                     return [
                                                         'user_id' => $item->user_id,
                                                         'name' => $item->user ? $item->user->first_name . ' ' . $item->user->last_name : 'Unknown',
                                                         'comments_count' => $item->comments_count,
                                                     ];
                                                 });

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_comments' => $totalComments,
                        'my_comments' => $myComments,
                        'today_comments' => $todayComments,
                        'my_today_comments' => $myTodayComments,
                        'this_week_comments' => $thisWeekComments,
                        'my_this_week_comments' => $myThisWeekComments,
                        'comments_with_files' => $commentsWithFiles,
                        'average_comments_per_day' => $thisWeekComments > 0 ? round($thisWeekComments / 7, 1) : 0,
                    ],
                    'model_breakdown' => $modelBreakdown,
                    'status_breakdown' => $statusBreakdown,
                    'daily_trends' => $dailyTrends,
                    'top_contributors' => $topContributors,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch comment statistics',
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
            'App\Modules\Tickets\Models\Ticket' => 'Ticket',
            'App\Modules\Tasks\Models\Task' => 'Task',
            'App\Modules\Deals\Models\Deal' => 'Deal',
            'App\Modules\Customers\Models\Staff' => 'Staff',
            'App\Modules\Proposals\Models\Proposal' => 'Proposal',
            'App\Modules\Estimates\Models\Estimate' => 'Estimate',
        ];

        return $modelNames[$modelType] ?? 'Unknown';
    }
}
