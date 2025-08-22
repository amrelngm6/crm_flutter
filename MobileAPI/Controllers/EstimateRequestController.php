<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Estimates\Models\EstimateRequest as EstimateRequestModel;
use App\Modules\Estimates\Services\EstimateRequestService;
use App\Modules\Core\Models\Status;
use App\Modules\Customers\Models\Staff;
use App\Modules\Customers\Models\Client;
use App\Modules\MobileAPI\Requests\EstimateRequestRequest;
use App\Modules\MobileAPI\Resources\EstimateRequestResource;
use App\Modules\Estimates\Helpers\EstimateSettingsHelper;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EstimateRequestController extends Controller
{
    protected $estimateRequestService;

    public function __construct(EstimateRequestService $estimateRequestService)
    {
        $this->estimateRequestService = $estimateRequestService;
    }

    /**
     * Get paginated estimate requests list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = EstimateRequestModel::forBusiness($businessId)
                                        ->with(['estimate', 'status', 'assignedStaff', 'user']);

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('message', 'like', "%{$search}%");
                });
            }

            // Filter by status
            if ($statusId = $request->get('status_id')) {
                $query->where('status_id', $statusId);
            }

            // Filter by assigned staff
            if ($assignedTo = $request->get('assigned_to')) {
                $query->where('assigned_to', $assignedTo);
            }

            // Filter by user type (client requests vs staff requests)
            if ($userType = $request->get('user_type')) {
                $query->where('user_type', $userType);
            }

            // Filter by user ID
            if ($userId = $request->get('user_id')) {
                $query->where('user_id', $userId);
            }

            // Filter by date range
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('date', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('date', '<=', $endDate);
            }

            // Filter by creation date
            if ($createdStartDate = $request->get('created_start_date')) {
                $query->whereDate('created_at', '>=', $createdStartDate);
            }
            if ($createdEndDate = $request->get('created_end_date')) {
                $query->whereDate('created_at', '<=', $createdEndDate);
            }

            // Filter unassigned requests
            if ($request->get('unassigned')) {
                $query->whereNull('assigned_to');
            }

            // Filter requests with estimates assigned
            if ($request->has('has_estimate')) {
                if ($request->get('has_estimate')) {
                    $query->whereNotNull('estimate_id');
                } else {
                    $query->whereNull('estimate_id');
                }
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $estimateRequests = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'estimate_requests' => EstimateRequestResource::collection($estimateRequests->items()),
                    'pagination' => [
                        'current_page' => $estimateRequests->currentPage(),
                        'last_page' => $estimateRequests->lastPage(),
                        'per_page' => $estimateRequests->perPage(),
                        'total' => $estimateRequests->total(),
                        'from' => $estimateRequests->firstItem(),
                        'to' => $estimateRequests->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch estimate requests',
                'errors' => ['server' => ['An error occurred while fetching estimate requests: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single estimate request details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimateRequest = EstimateRequestModel::forBusiness($businessId)
                                                 ->with(['estimate', 'status', 'assignedStaff', 'user'])
                                                 ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new EstimateRequestResource($estimateRequest)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate request not found',
                'errors' => ['estimate_request' => ['Estimate request not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch estimate request',
                'errors' => ['server' => ['An error occurred while fetching estimate request: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new estimate request
     */
    public function store(EstimateRequestRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['user_id'] = $staff->staff_id;
            $data['user_type'] = Staff::class;
            $data['date'] = $data['date'] ?? now();

            $estimateRequest = $this->estimateRequestService->createEstimateRequest($data);
            $estimateRequest->load(['estimate', 'status', 'assignedStaff', 'user']);

            return response()->json([
                'success' => true,
                'message' => 'Estimate request created successfully',
                'data' => new EstimateRequestResource($estimateRequest)
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
                'message' => 'Failed to create estimate request',
                'errors' => ['server' => ['An error occurred while creating estimate request: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update estimate request
     */
    public function update(EstimateRequestRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimateRequest = EstimateRequestModel::forBusiness($businessId)->findOrFail($id);
            
            $data = $request->validated();
            $updatedEstimateRequest = $this->estimateRequestService->updateEstimateRequest($id, $data);
            
            if ($updatedEstimateRequest) {
                $updatedEstimateRequest->load(['estimate', 'status', 'assignedStaff', 'user']);
                
                return response()->json([
                    'success' => true,
                    'message' => 'Estimate request updated successfully',
                    'data' => new EstimateRequestResource($updatedEstimateRequest)
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to update estimate request',
                'errors' => ['estimate_request' => ['Estimate request could not be updated']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate request not found',
                'errors' => ['estimate_request' => ['Estimate request not found']]
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
                'message' => 'Failed to update estimate request',
                'errors' => ['server' => ['An error occurred while updating estimate request: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete estimate request
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimateRequest = EstimateRequestModel::forBusiness($businessId)->findOrFail($id);
            $deleted = $this->estimateRequestService->delete($id);

            if ($deleted) {
                return response()->json([
                    'success' => true,
                    'message' => 'Estimate request deleted successfully'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete estimate request',
                'errors' => ['estimate_request' => ['Estimate request could not be deleted']]
            ], 500);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate request not found',
                'errors' => ['estimate_request' => ['Estimate request not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete estimate request',
                'errors' => ['server' => ['An error occurred while deleting estimate request: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Assign estimate to request
     */
    public function assignEstimate(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimateRequest = EstimateRequestModel::forBusiness($businessId)->findOrFail($id);

            $request->validate([
                'estimate_id' => 'required|exists:estimates,id',
            ]);

            $updatedRequest = $this->estimateRequestService->assignEstimate($id, $request->estimate_id);
            $updatedRequest->load(['estimate', 'status', 'assignedStaff', 'user']);

            return response()->json([
                'success' => true,
                'message' => 'Estimate assigned successfully',
                'data' => new EstimateRequestResource($updatedRequest)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate request not found',
                'errors' => ['estimate_request' => ['Estimate request not found']]
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
                'message' => 'Failed to assign estimate',
                'errors' => ['server' => ['An error occurred while assigning estimate: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Assign staff to request
     */
    public function assignStaff(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimateRequest = EstimateRequestModel::forBusiness($businessId)->findOrFail($id);

            $request->validate([
                'assigned_to' => 'required|exists:staff,staff_id',
            ]);

            $estimateRequest->update(['assigned_to' => $request->assigned_to]);
            $estimateRequest->load(['estimate', 'status', 'assignedStaff', 'user']);

            return response()->json([
                'success' => true,
                'message' => 'Staff assigned successfully',
                'data' => new EstimateRequestResource($estimateRequest)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate request not found',
                'errors' => ['estimate_request' => ['Estimate request not found']]
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
     * Change request status
     */
    public function changeStatus(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $estimateRequest = EstimateRequestModel::forBusiness($businessId)->findOrFail($id);

            $request->validate([
                'status_id' => 'required|exists:status_list,status_id',
            ]);

            $updatedRequest = $this->estimateRequestService->changeStatus($id, $request->status_id);
            $updatedRequest->load(['estimate', 'status', 'assignedStaff', 'user']);

            return response()->json([
                'success' => true,
                'message' => 'Status changed successfully',
                'data' => new EstimateRequestResource($updatedRequest)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Estimate request not found',
                'errors' => ['estimate_request' => ['Estimate request not found']]
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
                'message' => 'Failed to change status',
                'errors' => ['server' => ['An error occurred while changing status: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get form data for estimate request creation/editing
     */
    public function getFormData(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $statuses = $this->estimateRequestService->loadStatusList();
            $staffMembers = $this->getStaffMembers($request);
            $clients = $this->getClients($request);

            return response()->json([
                'success' => true,
                'data' => [
                    'statuses' => $statuses->map(function($status) {
                        return [
                            'id' => $status->status_id,
                            'name' => $status->name,
                            'color' => $status->color ?? '#6c757d',
                        ];
                    }),
                    'staff' => $staffMembers,
                    'clients' => $clients,
                    'settings' => [
                        'requests_enabled' => EstimateSettingsHelper::areEstimateRequestsEnabled(),
                        'clients_can_create' => EstimateSettingsHelper::canClientsCreateRequests(),
                        'max_daily_requests' => EstimateSettingsHelper::getMaxRequestsPerClientPerDay(),
                        'approval_required' => EstimateSettingsHelper::isRequestApprovalRequired(),
                        'auto_response_time' => EstimateSettingsHelper::getRequestAutoResponseTime(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch form data',
                'errors' => ['server' => ['An error occurred while fetching form data: ' . $e->getMessage()]]
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
     * Get clients for estimate request creation dropdown
     */
    public function getClients(Request $request)
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $clients = Client::where('business_id', $businessId)
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
     * Get estimate request statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $totalRequests = EstimateRequestModel::forBusiness($businessId)->count();
            $pendingRequests = EstimateRequestModel::forBusiness($businessId)
                                                  ->whereHas('status', function($q) {
                                                      $q->where('name', 'Pending');
                                                  })
                                                  ->count();
            $assignedRequests = EstimateRequestModel::forBusiness($businessId)
                                                   ->whereNotNull('estimate_id')
                                                   ->count();
            $unassignedRequests = EstimateRequestModel::forBusiness($businessId)
                                                     ->whereNull('assigned_to')
                                                     ->count();

            // Status breakdown
            $statusBreakdown = EstimateRequestModel::where('estimate_requests.business_id', $businessId)
                                                  ->join('status_list', 'estimate_requests.status_id', '=', 'status_list.status_id')
                                                  ->selectRaw('status_list.name as status_name, status_list.color, COUNT(*) as count')
                                                  ->groupBy('estimate_requests.status_id', 'status_list.name', 'status_list.color')
                                                  ->get();

            // User type breakdown
            $userTypeBreakdown = EstimateRequestModel::forBusiness($businessId)
                                                    ->selectRaw('user_type, COUNT(*) as count')
                                                    ->groupBy('user_type')
                                                    ->get()
                                                    ->map(function($item) {
                                                        $userTypeName = class_basename($item->user_type);
                                                        return [
                                                            'user_type' => $userTypeName,
                                                            'count' => $item->count
                                                        ];
                                                    });

            // Assignment breakdown
            $assignmentBreakdown = EstimateRequestModel::where('estimate_requests.business_id', $businessId)
                                                      ->leftJoin('staff', 'estimate_requests.assigned_to', '=', 'staff.staff_id')
                                                      ->selectRaw('staff.first_name, staff.last_name, staff.staff_id, COUNT(*) as count')
                                                      ->groupBy('staff.staff_id', 'staff.first_name', 'staff.last_name')
                                                      ->get();

            // Monthly trends (last 12 months)
            $monthlyData = EstimateRequestModel::forBusiness($businessId)
                                              ->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as month, COUNT(*) as count')
                                              ->where('created_at', '>=', now()->subMonths(12))
                                              ->groupBy('month')
                                              ->orderBy('month')
                                              ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_requests' => $totalRequests,
                        'pending_requests' => $pendingRequests,
                        'assigned_requests' => $assignedRequests,
                        'unassigned_requests' => $unassignedRequests,
                        'completion_rate' => $totalRequests > 0 ? round(($assignedRequests / $totalRequests) * 100, 2) : 0,
                    ],
                    'status_breakdown' => $statusBreakdown,
                    'user_type_breakdown' => $userTypeBreakdown,
                    'assignment_breakdown' => $assignmentBreakdown,
                    'monthly_trends' => $monthlyData,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch estimate request statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Check if user can create estimate requests (daily limit check)
     */
    public function checkDailyLimit(Request $request): JsonResponse
    {
        try {
            $userId = $request->get('user_id');
            $canCreateRequest = EstimateSettingsHelper::checkDailyRequestLimit($userId);
            $maxDaily = EstimateSettingsHelper::getMaxRequestsPerClientPerDay();

            return response()->json([
                'success' => true,
                'data' => [
                    'can_create_request' => $canCreateRequest,
                    'max_daily_requests' => $maxDaily,
                    'message' => $canCreateRequest ? 'Request can be created' : 'Daily request limit exceeded'
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to check daily limit',
                'errors' => ['server' => ['An error occurred while checking daily limit: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get request settings
     */
    public function getRequestSettings(Request $request): JsonResponse
    {
        try {
            $settings = [
                'requests_enabled' => EstimateSettingsHelper::areEstimateRequestsEnabled(),
                'clients_can_create' => EstimateSettingsHelper::canClientsCreateRequests(),
                'max_daily_requests' => EstimateSettingsHelper::getMaxRequestsPerClientPerDay(),
                'approval_required' => EstimateSettingsHelper::isRequestApprovalRequired(),
                'auto_response_time' => EstimateSettingsHelper::getRequestAutoResponseTime(),
                'attachments_allowed' => EstimateSettingsHelper::areRequestAttachmentsAllowed() ?? false,
                'max_attachment_size' => EstimateSettingsHelper::getMaxRequestAttachmentSize() ?? 0,
                'max_attachments' => EstimateSettingsHelper::getMaxAttachmentsPerRequest() ?? 0
            ];

            return response()->json([
                'success' => true,
                'data' => $settings
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch request settings',
                'errors' => ['server' => ['An error occurred while fetching request settings: ' . $e->getMessage()]]
            ], 500);
        }
    }
}
