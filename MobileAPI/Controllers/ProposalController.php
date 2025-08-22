<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Proposals\Models\Proposal;
use App\Modules\Proposals\Models\ProposalItem;
use App\Modules\Core\Models\Status;
use App\Modules\Customers\Models\Staff;
use App\Modules\Customers\Models\Client;
use App\Modules\MobileAPI\Requests\ProposalRequest;
use App\Modules\MobileAPI\Resources\ProposalResource;
use App\Modules\Items\Models\Item;
use App\Modules\Items\Models\ItemGroup;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProposalController extends Controller
{
    /**
     * Get paginated proposals list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Proposal::where('business_id', $businessId)
                            ->with(['status', 'assignedTo', 'client', 'model']);

            // Filter by assigned proposals only if requested
            $query->where('assigned_to', $staff->staff_id);
 
            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('title', 'like', "%{$search}%")
                      ->orWhere('content', 'like', "%{$search}%");
                });
            }

            // Filter by status
            if ($statusId = $request->get('status_id')) {
                $query->where('status_id', $statusId);
            }

            // Filter by client
            if ($clientId = $request->get('client_id')) {
                $query->where('client_id', $clientId)
                     ->where('client_type', Client::class);
            }

            // Filter by model type
            if ($modelType = $request->get('model_type')) {
                $query->where('model', $modelType);
            }

            // Filter by model ID
            if ($modelId = $request->get('model_id')) {
                $query->where('model_id', $modelId);
            }

            // Filter by date range
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('date', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('date', '<=', $endDate);
            }

            // Filter by expiry date
            if ($request->get('expired')) {
                $query->whereDate('expiry_date', '<', today());
            }
            if ($request->get('expiring_soon')) {
                $query->whereDate('expiry_date', '<=', today()->addDays(7))
                     ->whereDate('expiry_date', '>=', today());
            }

            // Filter by converted status
            if ($request->has('converted_to_invoice')) {
                $query->where('converted_to_invoice', $request->get('converted_to_invoice'));
            }

            // Filter by amount range
            if ($minTotal = $request->get('min_total')) {
                $query->where('total', '>=', $minTotal);
            }
            if ($maxTotal = $request->get('max_total')) {
                $query->where('total', '<=', $maxTotal);
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $proposals = $query->paginate($request->get('per_page', 20));

            $groups = ItemGroup::forBusiness($businessId)
                             ->withCount('items')
                             ->orderBy('name')
                             ->get();

            $items = Item::forBusiness($businessId)
                         ->orderBy('name')
                         ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'proposals' => ProposalResource::collection($proposals->items()),
                    'item-groups' => $groups->map(function($group) {
                        return [
                            'id' => $group->id,
                            'name' => $group->name,
                            'items_count' => $group->items_count,
                        ];
                    }),
                    'items' => $items->map(function($item) {
                        return [
                            'id' => $item->id,
                            'name' => $item->name,
                            'price' => $item->price,
                        ];
                    }),
                    'pagination' => [
                        'current_page' => $proposals->currentPage(),
                        'last_page' => $proposals->lastPage(),
                        'per_page' => $proposals->perPage(),
                        'total' => $proposals->total(),
                        'from' => $proposals->firstItem(),
                        'to' => $proposals->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch proposals',
                'errors' => ['server' => ['An error occurred while fetching proposals: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single proposal details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $proposal = Proposal::where('business_id', $businessId)
                               ->with(['status', 'assignedTo', 'client', 'model', 'items', 'invoice'])
                               ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new ProposalResource($proposal)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Proposal not found',
                'errors' => ['proposal' => ['Proposal not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch proposal',
                'errors' => ['server' => ['An error occurred while fetching proposal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new proposal
     */
    public function store(ProposalRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['created_by'] = $staff->staff_id;
            $data['assigned_to'] = $data['assigned_to'] ?? $staff->staff_id;

            // Calculate totals from items if provided
            if (isset($data['items']) && is_array($data['items'])) {
                $subtotal = 0;
                $taxAmount = 0;
                
                foreach ($data['items'] as $item) {
                    $itemSubtotal = $item['quantity'] * $item['unit_price'];
                    $itemTax = $itemSubtotal * ($item['tax'] / 100);
                    $subtotal += $itemSubtotal;
                    $taxAmount += $itemTax;
                }
                
                $data['subtotal'] = $subtotal;
                $data['tax_amount'] = $taxAmount;
                $data['total'] = $subtotal - ($data['discount_amount'] ?? 0) + $taxAmount;
            }

            $proposal = Proposal::create($data);

            // Add proposal items if provided
            if (isset($data['items']) && is_array($data['items'])) {
                foreach ($data['items'] as $itemData) {
                    $itemData['business_id'] = $businessId;
                    $itemData['proposal_id'] = $proposal->id;
                    $itemData['subtotal'] = $itemData['quantity'] * $itemData['unit_price'];
                    $itemData['total'] = $itemData['subtotal'] + ($itemData['subtotal'] * ($itemData['tax'] / 100));
                    
                    ProposalItem::create($itemData);
                }
            }

            $proposal->load(['status', 'assignedTo', 'client', 'model', 'items']);

            return response()->json([
                'success' => true,
                'message' => 'Proposal created successfully',
                'data' => new ProposalResource($proposal)
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
                'message' => 'Failed to create proposal',
                'errors' => ['server' => ['An error occurred while creating proposal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update proposal
     */
    public function update(ProposalRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $proposal = Proposal::where('business_id', $businessId)->findOrFail($id);
            
            $data = $request->validated();

            // Calculate totals from items if provided
            if (isset($data['items']) && is_array($data['items'])) {
                $subtotal = 0;
                $taxAmount = 0;
                
                foreach ($data['items'] as $item) {
                    $itemSubtotal = $item['quantity'] * $item['unit_price'];
                    $itemTax = $itemSubtotal * ($item['tax'] / 100);
                    $subtotal += $itemSubtotal;
                    $taxAmount += $itemTax;
                }
                
                $data['subtotal'] = $subtotal;
                $data['tax_amount'] = $taxAmount;
                $data['total'] = $subtotal - ($data['discount_amount'] ?? 0) + $taxAmount;

                // Update proposal items
                ProposalItem::where('proposal_id', $proposal->id)->delete();
                
                foreach ($data['items'] as $itemData) {
                    $itemData['business_id'] = $businessId;
                    $itemData['proposal_id'] = $proposal->id;
                    $itemData['subtotal'] = $itemData['quantity'] * $itemData['unit_price'];
                    $itemData['total'] = $itemData['subtotal'] + ($itemData['subtotal'] * ($itemData['tax'] / 100));
                    
                    ProposalItem::create($itemData);
                }
            }

            $proposal->update($data);
            $proposal->load(['status', 'assignedTo', 'client', 'model', 'items']);

            return response()->json([
                'success' => true,
                'message' => 'Proposal updated successfully',
                'data' => new ProposalResource($proposal)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Proposal not found',
                'errors' => ['proposal' => ['Proposal not found']]
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
                'message' => 'Failed to update proposal',
                'errors' => ['server' => ['An error occurred while updating proposal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete proposal
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $proposal = Proposal::where('business_id', $businessId)->findOrFail($id);
            $proposal->delete();

            return response()->json([
                'success' => true,
                'message' => 'Proposal deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Proposal not found',
                'errors' => ['proposal' => ['Proposal not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete proposal',
                'errors' => ['server' => ['An error occurred while deleting proposal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Convert proposal to invoice
     */
    public function convertToInvoice(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $proposal = Proposal::where('business_id', $businessId)->findOrFail($id);

            if ($proposal->converted_to_invoice) {
                return response()->json([
                    'success' => false,
                    'message' => 'Proposal already converted to invoice',
                    'errors' => ['proposal' => ['This proposal has already been converted']]
                ], 400);
            }

            // Here you would typically create an invoice
            // For now, just mark as converted
            $proposal->update([
                'converted_to_invoice' => true,
                'converted_at' => now(),
            ]);

            $proposal->load(['status', 'assignedTo', 'client', 'model', 'items']);

            return response()->json([
                'success' => true,
                'message' => 'Proposal converted to invoice successfully',
                'data' => new ProposalResource($proposal)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Proposal not found',
                'errors' => ['proposal' => ['Proposal not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to convert proposal',
                'errors' => ['server' => ['An error occurred while converting proposal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get proposal statuses for dropdown
     */
    public function getStatuses(Request $request): JsonResponse
    {
        try {
            $statuses = Status::default([$request->user()->business_id, 0])
                            ->where('model', Proposal::class)
                             ->select('status_id as id', 'name', 'color')
                             ->orderBy('sort')
                             ->get()
                             ->unique('id');

            return response()->json([
                'success' => true,
                'data' => $statuses
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch proposal statuses',
                'errors' => ['server' => ['An error occurred while fetching statuses: ' . $e->getMessage()]]
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
     * Get proposal statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Overview statistics
            $totalProposals = Proposal::where('business_id', $businessId)->count();
            $myProposals = Proposal::where('business_id', $businessId)->where('assigned_to', $staff->staff_id)->count();
            $totalValue = Proposal::where('business_id', $businessId)->sum('total');
            $convertedCount = Proposal::where('business_id', $businessId)->where('converted_to_invoice', true)->count();
            $conversionRate = $totalProposals > 0 ? ($convertedCount / $totalProposals) * 100 : 0;
            
            // Expiry analysis
            $expiredProposals = Proposal::where('business_id', $businessId)
                                       ->whereDate('expiry_date', '<', today())
                                       ->count();
            
            $expiringSoonProposals = Proposal::where('business_id', $businessId)
                                            ->whereDate('expiry_date', '<=', today()->addDays(7))
                                            ->whereDate('expiry_date', '>=', today())
                                            ->count();

            // Client analysis
            $clientBreakdown = Proposal::where('proposals.business_id', $businessId)
                                     ->leftJoin('clients', 'proposals.client_id', '=', 'clients.client_id')
                                     ->selectRaw('clients.name as client_name, clients.client_id, COUNT(*) as count, SUM(proposals.total) as total_value')
                                     ->groupBy('clients.client_id', 'clients.name')
                                     ->orderBy('total_value', 'desc')
                                     ->limit(10)
                                     ->get();

            // Status breakdown
            $statusBreakdown = Proposal::where('proposals.business_id', $businessId)
                                      ->leftJoin('status_list', 'proposals.status_id', '=', 'status_list.status_id')
                                      ->selectRaw('status_list.name as status_name, status_list.color, proposals.status_id, COUNT(*) as count, SUM(proposals.total) as total_value')
                                      ->groupBy('proposals.status_id', 'status_list.name', 'status_list.color')
                                      ->get();

            // Assignment breakdown
            $assignmentBreakdown = Proposal::where('proposals.business_id', $businessId)
                                          ->leftJoin('staff', 'proposals.assigned_to', '=', 'staff.staff_id')
                                          ->selectRaw('staff.first_name, staff.last_name, staff.staff_id, COUNT(*) as count, SUM(proposals.total) as total_value')
                                          ->groupBy('staff.staff_id', 'staff.first_name', 'staff.last_name')
                                          ->get();

            // Monthly trends (last 12 months)
            $monthlyData = Proposal::where('business_id', $businessId)
                                  ->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as month, COUNT(*) as count, SUM(total) as total_value, SUM(CASE WHEN converted_to_invoice = 1 THEN 1 ELSE 0 END) as converted')
                                  ->where('created_at', '>=', now()->subMonths(12))
                                  ->groupBy('month')
                                  ->orderBy('month')
                                  ->get();

            // Value ranges
            $valueRanges = [
                'under_1000' => Proposal::where('business_id', $businessId)->where('total', '<', 1000)->count(),
                '1000_5000' => Proposal::where('business_id', $businessId)->whereBetween('total', [1000, 5000])->count(),
                '5000_10000' => Proposal::where('business_id', $businessId)->whereBetween('total', [5000, 10000])->count(),
                'over_10000' => Proposal::where('business_id', $businessId)->where('total', '>', 10000)->count(),
            ];

            // Performance metrics
            $avgDaysToConvert = Proposal::where('business_id', $businessId)
                                       ->where('converted_to_invoice', true)
                                       ->whereNotNull('converted_at')
                                       ->selectRaw('AVG(DATEDIFF(converted_at, created_at)) as avg_days')
                                       ->value('avg_days');

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_proposals' => $totalProposals,
                        'my_proposals' => $myProposals,
                        'total_value' => round($totalValue, 2),
                        'converted_count' => $convertedCount,
                        'conversion_rate' => round($conversionRate, 2),
                        'average_value' => $totalProposals > 0 ? round($totalValue / $totalProposals, 2) : 0,
                        'expired_proposals' => $expiredProposals,
                        'expiring_soon_proposals' => $expiringSoonProposals,
                        'avg_days_to_convert' => round($avgDaysToConvert ?? 0, 1),
                    ],
                    'client_breakdown' => $clientBreakdown,
                    'status_breakdown' => $statusBreakdown,
                    'assignment_breakdown' => $assignmentBreakdown,
                    'value_ranges' => $valueRanges,
                    'monthly_trends' => $monthlyData,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch proposal statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }

    // ==================== ITEMS MANAGEMENT ====================

    /**
     * Get available items for proposal creation
     */
    public function getAvailableItems(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $query = Item::forBusiness($businessId)->with('group');

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('description', 'like', "%{$search}%");
                });
            }

            // Filter by group
            if ($groupId = $request->get('group_id')) {
                $query->where('group_id', $groupId);
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'name');
            $sortOrder = $request->get('sort', 'asc');
            $query->orderBy($sortBy, $sortOrder);

            $items = $query->paginate($request->get('per_page', 50));

            return response()->json([
                'success' => true,
                'data' => [
                    'items' => $items->items()->map(function($item) {
                        return [
                            'id' => $item->id,
                            'name' => $item->name,
                            'description' => $item->description,
                            'price' => $item->price,
                            'tax' => $item->tax,
                            'group' => [
                                'id' => $item->group->id ?? null,
                                'name' => $item->group->name ?? 'No Group',
                            ],
                        ];
                    }),
                    'pagination' => [
                        'current_page' => $items->currentPage(),
                        'last_page' => $items->lastPage(),
                        'per_page' => $items->perPage(),
                        'total' => $items->total(),
                        'from' => $items->firstItem(),
                        'to' => $items->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch items',
                'errors' => ['server' => ['An error occurred while fetching items: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get item groups for filtering
     */
    public function getItemGroups(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $groups = ItemGroup::forBusiness($businessId)
                             ->withCount('items')
                             ->orderBy('name')
                             ->get();

            return response()->json([
                'success' => true,
                'data' => $groups->map(function($group) {
                    return [
                        'id' => $group->id,
                        'name' => $group->name,
                        'items_count' => $group->items_count,
                    ];
                })
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch item groups',
                'errors' => ['server' => ['An error occurred while fetching item groups: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Add item to proposal
     */
    public function addItem(Request $request, int $proposalId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $proposal = Proposal::where('business_id', $businessId)->findOrFail($proposalId);

            $request->validate([
                'item_id' => 'nullable|exists:items,id',
                'item_name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'quantity' => 'required|numeric|min:0.01',
                'unit_price' => 'required|numeric|min:0',
                'tax' => 'nullable|numeric|min:0|max:100',
            ]);

            $data = $request->all();
            $data['business_id'] = $businessId;
            $data['proposal_id'] = $proposalId;
            $data['tax'] = $data['tax'] ?? 0;
            
            // Calculate item totals
            $data['subtotal'] = $data['quantity'] * $data['unit_price'];
            $data['total'] = $data['subtotal'] + ($data['subtotal'] * ($data['tax'] / 100));

            $item = ProposalItem::create($data);

            // Recalculate proposal totals
            $this->recalculateProposalTotals($proposal);

            return response()->json([
                'success' => true,
                'message' => 'Item added to proposal successfully',
                'data' => [
                    'item' => [
                        'id' => $item->id,
                        'item_name' => $item->item_name,
                        'description' => $item->description,
                        'quantity' => $item->quantity,
                        'unit_price' => $item->unit_price,
                        'tax' => $item->tax,
                        'subtotal' => $item->subtotal,
                        'total' => $item->total,
                    ],
                    'proposal_totals' => [
                        'subtotal' => $proposal->fresh()->subtotal,
                        'tax_amount' => $proposal->fresh()->tax_amount,
                        'total' => $proposal->fresh()->total,
                    ]
                ]
            ], 201);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Proposal not found',
                'errors' => ['proposal' => ['Proposal not found']]
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
                'message' => 'Failed to add item',
                'errors' => ['server' => ['An error occurred while adding item: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update proposal item
     */
    public function updateItem(Request $request, int $proposalId, int $itemId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $proposal = Proposal::where('business_id', $businessId)->findOrFail($proposalId);
            $item = ProposalItem::where('proposal_id', $proposalId)->findOrFail($itemId);

            $request->validate([
                'item_name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'quantity' => 'required|numeric|min:0.01',
                'unit_price' => 'required|numeric|min:0',
                'tax' => 'nullable|numeric|min:0|max:100',
            ]);

            $data = $request->all();
            $data['tax'] = $data['tax'] ?? 0;
            
            // Calculate item totals
            $data['subtotal'] = $data['quantity'] * $data['unit_price'];
            $data['total'] = $data['subtotal'] + ($data['subtotal'] * ($data['tax'] / 100));

            $item->update($data);

            // Recalculate proposal totals
            $this->recalculateProposalTotals($proposal);

            return response()->json([
                'success' => true,
                'message' => 'Item updated successfully',
                'data' => [
                    'item' => [
                        'id' => $item->id,
                        'item_name' => $item->item_name,
                        'description' => $item->description,
                        'quantity' => $item->quantity,
                        'unit_price' => $item->unit_price,
                        'tax' => $item->tax,
                        'subtotal' => $item->subtotal,
                        'total' => $item->total,
                    ],
                    'proposal_totals' => [
                        'subtotal' => $proposal->fresh()->subtotal,
                        'tax_amount' => $proposal->fresh()->tax_amount,
                        'total' => $proposal->fresh()->total,
                    ]
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Proposal or item not found',
                'errors' => ['item' => ['Proposal or item not found']]
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
                'message' => 'Failed to update item',
                'errors' => ['server' => ['An error occurred while updating item: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete proposal item
     */
    public function deleteItem(Request $request, int $proposalId, int $itemId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $proposal = Proposal::where('business_id', $businessId)->findOrFail($proposalId);
            $item = ProposalItem::where('proposal_id', $proposalId)->findOrFail($itemId);
            
            $item->delete();

            // Recalculate proposal totals
            $this->recalculateProposalTotals($proposal);

            return response()->json([
                'success' => true,
                'message' => 'Item deleted successfully',
                'data' => [
                    'proposal_totals' => [
                        'subtotal' => $proposal->fresh()->subtotal,
                        'tax_amount' => $proposal->fresh()->tax_amount,
                        'total' => $proposal->fresh()->total,
                    ]
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Proposal or item not found',
                'errors' => ['item' => ['Proposal or item not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete item',
                'errors' => ['server' => ['An error occurred while deleting item: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get proposal items
     */
    public function getItems(Request $request, int $proposalId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $proposal = Proposal::where('business_id', $businessId)->findOrFail($proposalId);
            $items = ProposalItem::where('proposal_id', $proposalId)->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'items' => $items->map(function($item) {
                        return [
                            'id' => $item->id,
                            'item_name' => $item->item_name,
                            'description' => $item->description,
                            'quantity' => $item->quantity,
                            'unit_price' => $item->unit_price,
                            'tax' => $item->tax,
                            'subtotal' => $item->subtotal,
                            'total' => $item->total,
                            'item_id' => $item->item_id,
                            'item_type' => $item->item_type,
                        ];
                    }),
                    'totals' => [
                        'subtotal' => $proposal->subtotal,
                        'tax_amount' => $proposal->tax_amount,
                        'discount_amount' => $proposal->discount_amount,
                        'total' => $proposal->total,
                    ]
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Proposal not found',
                'errors' => ['proposal' => ['Proposal not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch proposal items',
                'errors' => ['server' => ['An error occurred while fetching items: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Recalculate proposal totals based on items
     */
    private function recalculateProposalTotals(Proposal $proposal): void
    {
        $items = ProposalItem::where('proposal_id', $proposal->id)->get();
        
        $subtotal = $items->sum('subtotal');
        $taxAmount = $items->sum(function($item) {
            return $item->subtotal * ($item->tax / 100);
        });
        
        $proposal->update([
            'subtotal' => $subtotal,
            'tax_amount' => $taxAmount,
            'total' => $subtotal + $taxAmount - ($proposal->discount_amount ?? 0),
        ]);
    }
}
