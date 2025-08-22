<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Notes\Models\Note;
use App\Modules\Notes\Services\NoteService;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Requests\NoteRequest;
use App\Modules\MobileAPI\Resources\NoteResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Carbon\Carbon;

class NoteController extends Controller
{
    protected $noteService;

    public function __construct(NoteService $noteService)
    {
        $this->noteService = $noteService;
    }

    /**
     * Get paginated notes list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Note::forBusiness($businessId)
                         ->with(['user', 'model']);

            // Filter by model type and ID (specific entity notes)
            if ($modelType = $request->get('model_type')) {
                $query->where('model_type', $modelType);
                
                if ($modelId = $request->get('model_id')) {
                    $query->where('model_id', $modelId);
                }
            }

            // Filter by user (my notes only) if requested
            if ($request->get('my_notes_only', false)) {
                $query->where('user_id', $staff->staff_id)
                     ->where('user_type', Staff::class);
            }

            // Filter by specific user
            if ($userId = $request->get('user_id')) {
                $query->where('user_id', $userId)
                     ->where('user_type', Staff::class);
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
                $query->where('description', 'like', "%{$search}%");
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $notes = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'notes' => NoteResource::collection($notes->items()),
                    'pagination' => [
                        'current_page' => $notes->currentPage(),
                        'last_page' => $notes->lastPage(),
                        'per_page' => $notes->perPage(),
                        'total' => $notes->total(),
                        'from' => $notes->firstItem(),
                        'to' => $notes->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch notes',
                'errors' => ['server' => ['An error occurred while fetching notes: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single note details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $note = Note::forBusiness($businessId)
                        ->with(['user', 'model'])
                        ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new NoteResource($note)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Note not found',
                'errors' => ['note' => ['Note not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch note',
                'errors' => ['server' => ['An error occurred while fetching note: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new note
     */
    public function store(NoteRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['user_id'] = $staff->staff_id;
            $data['user_type'] = Staff::class;

            $note = $this->noteService->createNote($data);
            $note->load(['user', 'model']);

            return response()->json([
                'success' => true,
                'message' => 'Note created successfully',
                'data' => new NoteResource($note)
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
                'message' => 'Failed to create note',
                'errors' => ['server' => ['An error occurred while creating note: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update note
     */
    public function update(NoteRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $note = Note::forBusiness($businessId)->findOrFail($id);
            
            // Check if user can edit this note (only the creator can edit)
            if ($note->user_id !== $staff->staff_id || $note->user_type !== Staff::class) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to edit this note',
                    'errors' => ['note' => ['You can only edit your own notes']]
                ], 403);
            }

            $data = $request->validated();
            $updated = $note->update($data);

            if ($updated) {
                $note->refresh();
                $note->load(['user', 'model']);
                
                return response()->json([
                    'success' => true,
                    'message' => 'Note updated successfully',
                    'data' => new NoteResource($note)
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to update note',
                'errors' => ['note' => ['Note could not be updated']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Note not found',
                'errors' => ['note' => ['Note not found']]
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
                'message' => 'Failed to update note',
                'errors' => ['server' => ['An error occurred while updating note: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete note
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $note = Note::forBusiness($businessId)->findOrFail($id);
            
            // Check if user can delete this note (only the creator can delete)
            if ($note->user_id !== $staff->staff_id || $note->user_type !== Staff::class) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to delete this note',
                    'errors' => ['note' => ['You can only delete your own notes']]
                ], 403);
            }

            $deleted = $this->noteService->deleteNote($id);

            if ($deleted) {
                return response()->json([
                    'success' => true,
                    'message' => 'Note deleted successfully'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete note',
                'errors' => ['note' => ['Note could not be deleted']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Note not found',
                'errors' => ['note' => ['Note not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete note',
                'errors' => ['server' => ['An error occurred while deleting note: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get notes for specific model (Lead, Project, Ticket, etc.)
     */
    public function getModelNotes(Request $request, string $modelType, int $modelId): JsonResponse
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

            $notes = Note::forBusiness($businessId)
                         ->where('model_type', $modelType)
                         ->where('model_id', $modelId)
                         ->with(['user', 'model'])
                         ->orderBy('created_at', 'desc')
                         ->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'notes' => NoteResource::collection($notes->items()),
                    'pagination' => [
                        'current_page' => $notes->currentPage(),
                        'last_page' => $notes->lastPage(),
                        'per_page' => $notes->perPage(),
                        'total' => $notes->total(),
                        'from' => $notes->firstItem(),
                        'to' => $notes->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch model notes',
                'errors' => ['server' => ['An error occurred while fetching model notes: ' . $e->getMessage()]]
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
     * Get note statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Base query for business notes
            $baseQuery = Note::forBusiness($businessId);

            $totalNotes = (clone $baseQuery)->count();
            $myNotes = (clone $baseQuery)->where('user_id', $staff->staff_id)
                                        ->where('user_type', Staff::class)
                                        ->count();

            // Today's statistics
            $todayNotes = (clone $baseQuery)->whereDate('created_at', today())->count();
            $myTodayNotes = (clone $baseQuery)->where('user_id', $staff->staff_id)
                                             ->where('user_type', Staff::class)
                                             ->whereDate('created_at', today())
                                             ->count();

            // This week's statistics
            $thisWeekNotes = (clone $baseQuery)->whereBetween('created_at', [
                now()->startOfWeek(),
                now()->endOfWeek()
            ])->count();

            $myThisWeekNotes = (clone $baseQuery)->where('user_id', $staff->staff_id)
                                                ->where('user_type', Staff::class)
                                                ->whereBetween('created_at', [
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
            $dailyTrends = (clone $baseQuery)->selectRaw('DATE(created_at) as date, COUNT(*) as notes')
                                            ->where('created_at', '>=', now()->subDays(7))
                                            ->groupBy('date')
                                            ->orderBy('date')
                                            ->get();

            // Top contributors
            $topContributors = (clone $baseQuery)->selectRaw('user_id, user_type, COUNT(*) as notes_count')
                                                 ->where('user_type', Staff::class)
                                                 ->groupBy('user_id', 'user_type')
                                                 ->orderBy('notes_count', 'desc')
                                                 ->limit(5)
                                                 ->with('user')
                                                 ->get()
                                                 ->map(function ($item) {
                                                     return [
                                                         'user_id' => $item->user_id,
                                                         'name' => $item->user ? $item->user->first_name . ' ' . $item->user->last_name : 'Unknown',
                                                         'notes_count' => $item->notes_count,
                                                     ];
                                                 });

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_notes' => $totalNotes,
                        'my_notes' => $myNotes,
                        'today_notes' => $todayNotes,
                        'my_today_notes' => $myTodayNotes,
                        'this_week_notes' => $thisWeekNotes,
                        'my_this_week_notes' => $myThisWeekNotes,
                        'average_notes_per_day' => $thisWeekNotes > 0 ? round($thisWeekNotes / 7, 1) : 0,
                    ],
                    'model_breakdown' => $modelBreakdown,
                    'daily_trends' => $dailyTrends,
                    'top_contributors' => $topContributors,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch note statistics',
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
