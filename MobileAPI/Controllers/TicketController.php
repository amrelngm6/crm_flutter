<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Tickets\Models\Ticket;
use App\Modules\Tickets\Services\TicketService;
use App\Modules\Core\Models\Status;
use App\Modules\Actions\Services\CommentService;
use App\Modules\Core\Models\Category;
use App\Modules\Priorities\Models\Priority;
use App\Modules\Customers\Models\Staff;
use App\Modules\Customers\Models\Client;
use App\Modules\MobileAPI\Requests\TicketRequest;
use App\Modules\MobileAPI\Resources\TicketResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TicketController extends Controller
{
    protected $ticketService;

    public function __construct(TicketService $ticketService)
    {
        $this->ticketService = $ticketService;
    }

    /**
     * Get paginated tickets list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Ticket::forBusiness($businessId)
                          ->with(['status', 'priority', 'category', 'staffMembers', 'client', 'model']);

            // Filter by assigned tickets only if requested
            $query->whereHas('staffMembers', function($q) use ($staff) {
                $q->where('user_id', $staff->staff_id)
                    ->where('user_type', Staff::class);
            });

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('subject', 'like', "%{$search}%")
                      ->orWhere('message', 'like', "%{$search}%");
                });
            }

            // Filter by status
            if ($request->get('status_id') > -1) {
                $query->where('status_id', $request->get('status_id'));
            }

            // Filter by priority
            if ($priorityId = $request->get('priority_id')) {
                $query->where('priority_id', $priorityId);
            }

            // Filter by category
            if ($categoryId = $request->get('category_id')) {
                $query->where('category_id', $categoryId);
            }

            // Filter by client
            if ($clientId = $request->get('client_id')) {
                $query->where('client_id', $clientId);
            }

            // Filter by model type
            if ($modelType = $request->get('model_type')) {
                $query->where('model_type', $modelType);
            }

            // Filter by model ID
            if ($modelId = $request->get('model_id')) {
                $query->where('model_id', $modelId);
            }

            // Filter by due date
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('due_date', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('due_date', '<=', $endDate);
            }

            // Filter by creation date
            if ($createdStartDate = $request->get('created_start_date')) {
                $query->whereDate('created_at', '>=', $createdStartDate);
            }
            if ($createdEndDate = $request->get('created_end_date')) {
                $query->whereDate('created_at', '<=', $createdEndDate);
            }

            // Filter overdue tickets
            if ($request->get('overdue')) {
                $query->whereDate('due_date', '<', today())
                     ->whereNotIn('status_id', [3, 4]); // Assuming 3=closed, 4=resolved
            }

            // Filter due soon tickets
            if ($request->get('due_soon')) {
                $query->whereDate('due_date', '<=', today()->addDays(7))
                     ->whereDate('due_date', '>=', today())
                     ->whereNotIn('status_id', [3, 4]);
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $tickets = $query->paginate($request->get('per_page', 20));

            $priorities = $this->ticketService->loadPriorities();

            return response()->json([
                'success' => true,
                'data' => [
                    'tickets' => TicketResource::collection($tickets->items()),
                    'pagination' => [
                        'current_page' => $tickets->currentPage(),
                        'last_page' => $tickets->lastPage(),
                        'per_page' => $tickets->perPage(),
                        'total' => $tickets->total(),
                        'from' => $tickets->firstItem(),
                        'to' => $tickets->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch tickets',
                'errors' => ['server' => ['An error occurred while fetching tickets: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single ticket details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $ticket = Ticket::forBusiness($businessId)
                           ->with(['status', 'priority', 'category', 'staffMembers', 'client', 'model', 'comments', 'tasks'])
                           ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new TicketResource($ticket)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Ticket not found',
                'errors' => ['ticket' => ['Ticket not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch ticket',
                'errors' => ['server' => ['An error occurred while fetching ticket: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new ticket
     */
    public function store(TicketRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['creator_id'] = $staff->staff_id;
            $data['creator_type'] = Staff::class;
            $data['client_type'] = Client::class;
            $data['model_type'] = Client::class;
            $data['model_id'] = $request->input('client_id');

            $ticket = $this->ticketService->createTicket($data);
            $ticket->load(['status', 'priority', 'category', 'staffMembers', 'client', 'model']);

            return response()->json([
                'success' => true,
                'message' => 'Ticket created successfully',
                'data' => new TicketResource($ticket)
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
                'message' => 'Failed to create ticket',
                'errors' => ['server' => ['An error occurred while creating ticket: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update ticket
     */
    public function update(TicketRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $ticket = Ticket::forBusiness($businessId)->findOrFail($id);
            
            $data = $request->validated();
            $updatedTicket = $this->ticketService->updateTicket($id, $data);
            
            if ($updatedTicket) {
                $updatedTicket->load(['status', 'priority', 'category', 'staffMembers', 'client', 'model']);
                
                return response()->json([
                    'success' => true,
                    'message' => 'Ticket updated successfully',
                    'data' => new TicketResource($updatedTicket)
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to update ticket',
                'errors' => ['ticket' => ['Ticket could not be updated']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Ticket not found',
                'errors' => ['ticket' => ['Ticket not found']]
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
                'message' => 'Failed to update ticket',
                'errors' => ['server' => ['An error occurred while updating ticket: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete ticket
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $ticket = Ticket::forBusiness($businessId)->findOrFail($id);
            $deleted = $this->ticketService->deleteTicket($id);

            if ($deleted) {
                return response()->json([
                    'success' => true,
                    'message' => 'Ticket deleted successfully'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete ticket',
                'errors' => ['ticket' => ['Ticket could not be deleted']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Ticket not found',
                'errors' => ['ticket' => ['Ticket not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete ticket',
                'errors' => ['server' => ['An error occurred while deleting ticket: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Add reply to ticket
     */
    public function reply(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $ticket = Ticket::forBusiness($businessId)->findOrFail($id);

            $request->validate([
                'message' => 'required|string|max:1000',
            ]);

            $reply = CommentService::createComment([
                'business_id' => $businessId,
                'model_id' => $ticket->id,
                'model_type' => get_class($ticket),
                'user_id' => $staff->id(),
                'user_type' => get_class($staff),
                'status' => '1',
                'message' => $request->message
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Reply added successfully',
                'data' => new TicketResource($ticket)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Ticket not found',
                'errors' => ['ticket' => ['Ticket not found']]
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
                'message' => 'Failed to add reply',
                'errors' => ['server' => ['An error occurred while adding reply: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Assign staff members to ticket
     */
    public function assignStaff(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $ticket = Ticket::forBusiness($businessId)->findOrFail($id);

            $request->validate([
                'staff_ids' => 'required|array',
                'staff_ids.*' => 'exists:staff,staff_id',
            ]);

            $this->ticketService->assignStaff($ticket, $request->staff_ids);
            $ticket->load(['staffMembers']);

            return response()->json([
                'success' => true,
                'message' => 'Staff assigned successfully',
                'data' => [
                    'assigned_staff' => $ticket->staffMembers->map(function($member) {
                        $staffMember = Staff::find($member->user_id);
                        return [
                            'id' => $staffMember->id(),
                            'name' => $staffMember->name,
                            'email' => $staffMember->email ?? null,
                            'avatar' => $staffMember ? $staffMember->avatar() : null,
                        ];
                    })
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Ticket not found',
                'errors' => ['ticket' => ['Ticket not found']]
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
                'message' => 'Failed to assign staff',
                'errors' => ['server' => ['An error occurred while assigning staff: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Remove staff members from ticket
     */
    public function removeStaff(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $ticket = Ticket::forBusiness($businessId)->findOrFail($id);

            $request->validate([
                'staff_ids' => 'required|array',
                'staff_ids.*' => 'exists:staff,staff_id',
            ]);

            $this->ticketService->removeStaff($ticket, $request->staff_ids);

            return response()->json([
                'success' => true,
                'message' => 'Staff removed successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Ticket not found',
                'errors' => ['ticket' => ['Ticket not found']]
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
                'message' => 'Failed to remove staff',
                'errors' => ['server' => ['An error occurred while removing staff: ' . $e->getMessage()]]
            ], 500);
        }
    }


    /**
     * Get ticket priorities for dropdown
     */
    public function getFormData(Request $request): JsonResponse
    {
        try {
            
            $staff = $request->user();
            $businessId = $staff->business_id;
            $priorities = $this->ticketService->loadPriorities();
            $categories = $this->ticketService->loadCats($businessId);
            $statuses = TicketService::loadStatusList();

            return response()->json([
                'success' => true,
                'priorities' => $priorities->map(function($priority) {
                        return [
                            'id' => $priority->priority_id,
                            'name' => $priority->name,
                            'color' => $priority->color ?? '#6c757d',
                            'level' => $priority->level ?? 1,
                        ];
                    }),
                'clients' => $this->getClients($request),
                'categories' => $categories->map(function($category) {
                    return [
                        'id' => $category->id,
                        'name' => $category->name,
                        'description' => $category->description ?? null,
                    ];
                }),
                'statuses' => $statuses->map(function($status) {
                    return [
                        'id' => $status->status_id,
                        'name' => $status->name,
                        'color' => $status->color ?? '#6c757d',
                    ];
                }),
                'staff' => $this->getStaffMembers($request),
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch ticket priorities',
                'errors' => ['server' => ['An error occurred while fetching priorities: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get staff members for assignment dropdown
     */
    public function getStaffMembers(Request $request)
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $staffMembers = Staff::where('business_id', $businessId)
                                ->where('status', 1)
                                ->select('staff_id', 'first_name', 'last_name', 'email', 'picture')
                                ->orderBy('first_name')
                                ->get()
                                ->map(function ($member) {
                                    return [
                                        'id' => $member->id(),
                                        'name' => $member->name,
                                        'email' => $member->email,
                                        'avatar' => $member->avatar() ?? '/data/images/default-avatar.png',
                                    ];
                                });

            return $staffMembers;

        } catch (\Exception $e) {
            return [];
        }
    }

    /**
     * Get clients for ticket creation dropdown
     */
    public function getClients(Request $request)
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $clients = Client::where('business_id', $businessId)
                        //    ->where('status', 1)
                           ->select('client_id', 'first_name', 'last_name', 'email', 'phone', 'type')
                           ->orderBy('clients.first_name')
                           ->get()
                           ->map(function ($client) {
                               return [
                                   'id' => $client->id(),
                                   'name' => $client->name,
                                   'email' => $client->email,
                                   'phone' => $client->phone,
                                   'avatar' => $client->avatar() ?? '/data/images/default-avatar.png',
                               ];
                           });
            return $clients;

        } catch (\Exception $e) {
            return [];
        }
    }

    /**
     * Get ticket statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $totalTickets = Ticket::forBusiness($businessId)->forUser($staff)->count();
            $openTickets = Ticket::forBusiness($businessId)->forUser($staff)->whereNotIn('status_id', [3, 4])->count();
            $myTickets = Ticket::forBusiness($businessId)->forUser($staff)->count();
            $overdueTickets = Ticket::forBusiness($businessId)->forUser($staff)
                                   ->whereDate('due_date', '<', today())
                                   ->whereNotIn('status_id', [3, 4])
                                   ->count();

            // Status breakdown
            $statusBreakdown = Ticket::where('tickets.business_id', $businessId)
                                    ->forUser($staff)
                                    ->join('status_list', 'tickets.status_id', '=', 'status_list.status_id')
                                    ->selectRaw('status_list.name as status_name, status_list.color, COUNT(*) as count')
                                    ->groupBy('tickets.status_id', 'status_list.name', 'status_list.color')
                                    ->get();

            // Priority breakdown
            $priorityBreakdown = Ticket::where('tickets.business_id', $businessId)
                                    ->forUser($staff)
                                      ->join('priorities', 'tickets.priority_id', '=', 'priorities.priority_id')
                                      ->selectRaw('priorities.name as priority_name, priorities.color, COUNT(*) as count')
                                      ->groupBy('tickets.priority_id', 'priorities.name', 'priorities.color')
                                      ->get();

            // Monthly trends (last 12 months)
            $monthlyData = Ticket::forBusiness($businessId)
                                ->forUser($staff)
                                ->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as month, COUNT(*) as count')
                                ->where('created_at', '>=', now()->subMonths(12))
                                ->groupBy('month')
                                ->orderBy('month')
                                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_tickets' => $totalTickets,
                        'open_tickets' => $openTickets,
                        'my_tickets' => $myTickets,
                        'overdue_tickets' => $overdueTickets,
                        'resolution_rate' => $totalTickets > 0 ? round((($totalTickets - $openTickets) / $totalTickets) * 100, 2) : 0,
                    ],
                    'status_breakdown' => $statusBreakdown,
                    'priority_breakdown' => $priorityBreakdown,
                    'monthly_trends' => $monthlyData,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch ticket statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }
}
