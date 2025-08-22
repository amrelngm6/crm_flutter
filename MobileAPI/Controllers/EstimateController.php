<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Estimates\Models\Estimate;
use App\Modules\Estimates\Models\EstimateItem;
use App\Modules\Estimates\Models\EstimateRequest as EstimateRequestModel;
use App\Modules\Core\Models\Status;
use App\Modules\Customers\Models\Staff;
use App\Modules\Customers\Models\Client;
use App\Modules\MobileAPI\Requests\EstimateRequest;
use App\Modules\MobileAPI\Resources\EstimateResource;
use App\Modules\Items\Models\Item;
use App\Modules\Items\Models\ItemGroup;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EstimateController extends Controller
{
    /**
     * Get paginated estimates list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Estimate::where('business_id', $businessId)
                            ->with(['status', 'assignedTo', 'client', 'model']);

            // Filter by assigned estimates only if requested
            $query->where('assigned_to', $staff->staff_id);

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('title', 'like', "%{$search}%")
                      ->orWhere('content', 'like', "%{$search}%")
                      ->orWhere('estimate_number', 'like', "%{$search}%");
                });
            }

            // Filter by status
            if ($statusId = $request->get('status_id')) {
                $query->where('status_id', $statusId);
            }

            // Filter by approval status
            if ($approvalStatus = $request->get('approval_status')) {
                $query->where('approval_status', $approvalStatus);
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
            $sortOrder = $request->get('sort_order', 'desc');
            $query->with('items')->orderBy($sortBy, $sortOrder);

            $estimates = $query->paginate($request->get('per_page', 20));

            
            $statuses = Status::where('model', Estimate::class)
                             ->select('status_id as id', 'name', 'color')
                             ->orderBy('sort')
                             ->get();
                             
            return response()->json([
                'success' => true,
                'data' => [
                    'estimates' => EstimateResource::collection($estimates->items()),
                    'statuses' => $statuses,
                    'pagination' => [
                        'current_page' => $estimates->currentPage(),
                        'last_page' => $estimates->lastPage(),
                        'per_page' => $estimates->perPage(),
                        'total' => $estimates->total(),
                        'from' => $estimates->firstItem(),
                        'to' => $estimates->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch estimates',
                'errors' => ['server' => ['An error occurred while fetching estimates: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single estimate details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimate = Estimate::where('business_id', $businessId)
                               ->with(['status', 'assignedTo', 'client', 'model', 'items', 'invoice', 'requests'])
                               ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new EstimateResource($estimate)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate not found',
                'errors' => ['estimate' => ['Estimate not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch estimate',
                'errors' => ['server' => ['An error occurred while fetching estimate: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new estimate
     */
    public function store(EstimateRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['created_by'] = $staff->staff_id;
            $data['assigned_to'] = $data['assigned_to'] ?? $staff->staff_id;

            // Generate estimate number if not provided
            if (!isset($data['estimate_number'])) {
                $lastEstimate = Estimate::where('business_id', $businessId)
                                       ->orderBy('id', 'desc')
                                       ->first();
                $nextNumber = $lastEstimate ? (intval(substr($lastEstimate->estimate_number, -4)) + 1) : 1;
                $data['estimate_number'] = 'EST-' . str_pad($nextNumber, 4, '0', STR_PAD_LEFT);
            }

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

            $estimate = Estimate::create($data);

            // Add estimate items if provided
            if (isset($data['items']) && is_array($data['items'])) {
                foreach ($data['items'] as $itemData) {
                    $itemData['business_id'] = $businessId;
                    $itemData['estimate_id'] = $estimate->id;
                    $itemData['subtotal'] = $itemData['quantity'] * $itemData['unit_price'];
                    $itemData['total'] = $itemData['subtotal'] + ($itemData['subtotal'] * ($itemData['tax'] / 100));
                    
                    EstimateItem::create($itemData);
                }
            }

            $estimate->load(['status', 'assignedTo', 'client', 'model', 'items']);

            return response()->json([
                'success' => true,
                'message' => 'Estimate created successfully',
                'data' => new EstimateResource($estimate)
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
                'message' => 'Failed to create estimate',
                'errors' => ['server' => ['An error occurred while creating estimate: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update estimate
     */
    public function update(EstimateRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimate = Estimate::where('business_id', $businessId)->findOrFail($id);
            
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

                // Update estimate items
                EstimateItem::where('estimate_id', $estimate->id)->delete();
                
                foreach ($data['items'] as $itemData) {
                    $itemData['business_id'] = $businessId;
                    $itemData['estimate_id'] = $estimate->id;
                    $itemData['subtotal'] = $itemData['quantity'] * $itemData['unit_price'];
                    $itemData['total'] = $itemData['subtotal'] + ($itemData['subtotal'] * ($itemData['tax'] / 100));
                    
                    EstimateItem::create($itemData);
                }
            }

            $estimate->update($data);
            $estimate->load(['status', 'assignedTo', 'client', 'model', 'items']);

            return response()->json([
                'success' => true,
                'message' => 'Estimate updated successfully',
                'data' => new EstimateResource($estimate)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate not found',
                'errors' => ['estimate' => ['Estimate not found']]
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
                'message' => 'Failed to update estimate',
                'errors' => ['server' => ['An error occurred while updating estimate: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete estimate
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimate = Estimate::where('business_id', $businessId)->findOrFail($id);
            $estimate->delete();

            return response()->json([
                'success' => true,
                'message' => 'Estimate deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate not found',
                'errors' => ['estimate' => ['Estimate not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete estimate',
                'errors' => ['server' => ['An error occurred while deleting estimate: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Convert estimate to invoice
     */
    public function convertToInvoice(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimate = Estimate::where('business_id', $businessId)->findOrFail($id);

            if ($estimate->converted_to_invoice) {
                return response()->json([
                    'success' => false,
                    'message' => 'Estimate already converted to invoice',
                    'errors' => ['estimate' => ['This estimate has already been converted']]
                ], 400);
            }

            // Here you would typically create an invoice
            // For now, just mark as converted
            $estimate->update([
                'converted_to_invoice' => true,
                'converted_at' => now(),
            ]);

            $estimate->load(['status', 'assignedTo', 'client', 'model', 'items']);

            return response()->json([
                'success' => true,
                'message' => 'Estimate converted to invoice successfully',
                'data' => new EstimateResource($estimate)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate not found',
                'errors' => ['estimate' => ['Estimate not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to convert estimate',
                'errors' => ['server' => ['An error occurred while converting estimate: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Approve estimate
     */
    public function approve(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimate = Estimate::where('business_id', $businessId)->findOrFail($id);

            $estimate->update([
                'approval_status' => 'approved',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Estimate approved successfully',
                'data' => [
                    'approval_status' => $estimate->approval_status,
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate not found',
                'errors' => ['estimate' => ['Estimate not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to approve estimate',
                'errors' => ['server' => ['An error occurred while approving estimate: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Reject estimate
     */
    public function reject(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimate = Estimate::where('business_id', $businessId)->findOrFail($id);

            $estimate->update([
                'approval_status' => 'rejected',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Estimate rejected successfully',
                'data' => [
                    'approval_status' => $estimate->approval_status,
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate not found',
                'errors' => ['estimate' => ['Estimate not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to reject estimate',
                'errors' => ['server' => ['An error occurred while rejecting estimate: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get estimate statuses for dropdown
     */
    public function getStatuses(Request $request): JsonResponse
    {
        try {
            $statuses = Status::where('model', Estimate::class)
                             ->select('status_id as id', 'name', 'color')
                             ->orderBy('sort')
                             ->get();

            return response()->json([
                'success' => true,
                'data' => $statuses
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch estimate statuses',
                'errors' => ['server' => ['An error occurred while fetching statuses: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get estimate statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Overview statistics
            $totalEstimates = Estimate::where('business_id', $businessId)->count();
            $myEstimates = Estimate::where('business_id', $businessId)->where('assigned_to', $staff->staff_id)->count();
            $totalValue = Estimate::where('business_id', $businessId)->sum('total');
            $convertedCount = Estimate::where('business_id', $businessId)->where('converted_to_invoice', true)->count();
            $conversionRate = $totalEstimates > 0 ? ($convertedCount / $totalEstimates) * 100 : 0;
            
            // Expiry analysis
            $expiredEstimates = Estimate::where('business_id', $businessId)
                                       ->whereDate('expiry_date', '<', today())
                                       ->count();
            
            $expiringSoonEstimates = Estimate::where('business_id', $businessId)
                                            ->whereDate('expiry_date', '<=', today()->addDays(7))
                                            ->whereDate('expiry_date', '>=', today())
                                            ->count();

            // Approval status breakdown
            $approvalBreakdown = Estimate::where('business_id', $businessId)
                                        ->selectRaw('approval_status, COUNT(*) as count, SUM(total) as total_value')
                                        ->groupBy('approval_status')
                                        ->get()
                                        ->keyBy('approval_status');

            // Status breakdown
            $statusBreakdown = Estimate::where('estimates.business_id', $businessId)
                                      ->leftJoin('status_list', 'estimates.status_id', '=', 'status_list.status_id')
                                      ->selectRaw('status_list.name as status_name, status_list.color, estimates.status_id, COUNT(*) as count, SUM(estimates.total) as total_value')
                                      ->groupBy('estimates.status_id', 'status_list.name', 'status_list.color')
                                      ->get();

            // Assignment breakdown
            $assignmentBreakdown = Estimate::where('estimates.business_id', $businessId)
                                          ->leftJoin('staff', 'estimates.assigned_to', '=', 'staff.staff_id')
                                          ->selectRaw('staff.first_name, staff.last_name, staff.staff_id, COUNT(*) as count, SUM(estimates.total) as total_value')
                                          ->groupBy('staff.staff_id', 'staff.first_name', 'staff.last_name')
                                          ->get();

            // Monthly trends (last 12 months)
            $monthlyData = Estimate::where('business_id', $businessId)
                                  ->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as month, COUNT(*) as count, SUM(total) as total_value, SUM(CASE WHEN converted_to_invoice = 1 THEN 1 ELSE 0 END) as converted')
                                  ->where('created_at', '>=', now()->subMonths(12))
                                  ->groupBy('month')
                                  ->orderBy('month')
                                  ->get();

            // Value ranges
            $valueRanges = [
                'under_1000' => Estimate::where('business_id', $businessId)->where('total', '<', 1000)->count(),
                '1000_5000' => Estimate::where('business_id', $businessId)->whereBetween('total', [1000, 5000])->count(),
                '5000_10000' => Estimate::where('business_id', $businessId)->whereBetween('total', [5000, 10000])->count(),
                'over_10000' => Estimate::where('business_id', $businessId)->where('total', '>', 10000)->count(),
            ];

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_estimates' => $totalEstimates,
                        'my_estimates' => $myEstimates,
                        'total_value' => round($totalValue, 2),
                        'converted_count' => $convertedCount,
                        'conversion_rate' => round($conversionRate, 2),
                        'average_value' => $totalEstimates > 0 ? round($totalValue / $totalEstimates, 2) : 0,
                        'expired_estimates' => $expiredEstimates,
                        'expiring_soon_estimates' => $expiringSoonEstimates,
                    ],
                    'monthly_trends' => $monthlyData,
                    'approval_breakdown' => array_values($approvalBreakdown->toArray()),
                    'status_breakdown' => $statusBreakdown,
                    'assignment_breakdown' => $assignmentBreakdown,
                    'value_ranges' => $valueRanges,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch estimate statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }

    // ==================== ITEMS MANAGEMENT ====================

    /**
     * Get available items for estimate creation
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
            $sortOrder = $request->get('sort_order', 'asc');
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
     * Add item to estimate
     */
    public function addItem(Request $request, int $estimateId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimate = Estimate::where('business_id', $businessId)->findOrFail($estimateId);

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
            $data['estimate_id'] = $estimateId;
            $data['tax'] = $data['tax'] ?? 0;
            
            // Calculate item totals
            $data['subtotal'] = $data['quantity'] * $data['unit_price'];
            $data['total'] = $data['subtotal'] + ($data['subtotal'] * ($data['tax'] / 100));

            $item = EstimateItem::create($data);

            // Recalculate estimate totals
            $this->recalculateEstimateTotals($estimate);

            return response()->json([
                'success' => true,
                'message' => 'Item added to estimate successfully',
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
                    'estimate_totals' => [
                        'subtotal' => $estimate->fresh()->subtotal,
                        'tax_amount' => $estimate->fresh()->tax_amount,
                        'total' => $estimate->fresh()->total,
                    ]
                ]
            ], 201);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate not found',
                'errors' => ['estimate' => ['Estimate not found']]
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
     * Update estimate item
     */
    public function updateItem(Request $request, int $estimateId, int $itemId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimate = Estimate::where('business_id', $businessId)->findOrFail($estimateId);
            $item = EstimateItem::where('estimate_id', $estimateId)->findOrFail($itemId);

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

            // Recalculate estimate totals
            $this->recalculateEstimateTotals($estimate);

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
                    'estimate_totals' => [
                        'subtotal' => $estimate->fresh()->subtotal,
                        'tax_amount' => $estimate->fresh()->tax_amount,
                        'total' => $estimate->fresh()->total,
                    ]
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate or item not found',
                'errors' => ['item' => ['Estimate or item not found']]
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
     * Delete estimate item
     */
    public function deleteItem(Request $request, int $estimateId, int $itemId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimate = Estimate::where('business_id', $businessId)->findOrFail($estimateId);
            $item = EstimateItem::where('estimate_id', $estimateId)->findOrFail($itemId);
            
            $item->delete();

            // Recalculate estimate totals
            $this->recalculateEstimateTotals($estimate);

            return response()->json([
                'success' => true,
                'message' => 'Item deleted successfully',
                'data' => [
                    'estimate_totals' => [
                        'subtotal' => $estimate->fresh()->subtotal,
                        'tax_amount' => $estimate->fresh()->tax_amount,
                        'total' => $estimate->fresh()->total,
                    ]
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate or item not found',
                'errors' => ['item' => ['Estimate or item not found']]
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
     * Get estimate items
     */
    public function getItems(Request $request, int $estimateId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimate = Estimate::where('business_id', $businessId)->findOrFail($estimateId);
            $items = EstimateItem::where('estimate_id', $estimateId)->get();

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
                        'subtotal' => $estimate->subtotal,
                        'tax_amount' => $estimate->tax_amount,
                        'discount_amount' => $estimate->discount_amount,
                        'total' => $estimate->total,
                    ]
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate not found',
                'errors' => ['estimate' => ['Estimate not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch estimate items',
                'errors' => ['server' => ['An error occurred while fetching items: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Recalculate estimate totals based on items
     */
    private function recalculateEstimateTotals(Estimate $estimate): void
    {
        $items = EstimateItem::where('estimate_id', $estimate->id)->get();
        
        $subtotal = $items->sum('subtotal');
        $taxAmount = $items->sum(function($item) {
            return $item->subtotal * ($item->tax / 100);
        });
        
        $estimate->update([
            'subtotal' => $subtotal,
            'tax_amount' => $taxAmount,
            'total' => $subtotal + $taxAmount - ($estimate->discount_amount ?? 0),
        ]);
    }
}
