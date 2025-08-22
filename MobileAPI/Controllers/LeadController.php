<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Leads\Models\Lead;
use App\Modules\Leads\Models\LeadSource; 
use App\Modules\Leads\Services\LeadService; 
use App\Modules\Core\Models\Status;
use App\Modules\MobileAPI\Requests\LeadRequest;
use App\Modules\MobileAPI\Resources\LeadResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LeadController extends Controller
{
    /**
     * Get paginated leads list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Lead::where('business_id', $businessId)
                        ->with(['status', 'source', 'assignedTo']);

            // Filter by assigned leads only if requested
            $query->where('assigned_to', $staff->id());

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('first_name', 'like', "%{$search}%")
                      ->orWhere('last_name', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%")
                      ->orWhere('phone', 'like', "%{$search}%")
                      ->orWhere('company', 'like', "%{$search}%");
                });
            }

            // Filter by status
            if ($request->get('status_id') > -1 && $request->get('status_id') != 'All') {
                $query->where('status_id', $request->get('status_id'));
            }

            // Filter by source
            if ($source = $request->get('source_id')) {
                $query->where('source_id', $source);
            }

            // Filter by date range
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('created_at', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('created_at', '<=', $endDate);
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $leads = $query->paginate($request->get('per_page', 20));


            return response()->json([
                'success' => true,
                'data' => [
                    'leads' => LeadResource::collection($leads->items()),
                    'status_list' => $this->loadStatusList(),
                    'pagination' => [
                        'current_page' => $leads->currentPage(),
                        'last_page' => $leads->lastPage(),
                        'per_page' => $leads->perPage(),
                        'total' => $leads->total(),
                        'from' => $leads->firstItem(),
                        'to' => $leads->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            \Log::info('Failed to fetch leads', ['error' => $e->getMessage(), 'file' => $e->getFile(), 'line' => $e->getLine()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch leads',
                'errors' => ['server' => ['An error occurred while fetching leads']]
            ], 500);
        }
    }

    /**
     * Load status list
     */
    private function loadStatusList(): array
    {
        $array = LeadService::loadStatusList()->map(function ($status) {
            return [
                'id' => $status->status_id,
                'name' => $status->name,
                'color' => $status->color,
                'sort' => $status->sort ?? 0
            ];
        })->toArray();

        // Sort by sort key
        usort($array, fn($a, $b) => $b['name'] <=> $a['name']);
        return $array;
    }

    /**
     * Get single lead details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $lead = Lead::where('business_id', $businessId)
                       ->with(['status', 'source', 'assignedTo', 'notes', 'comments'])
                       ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => [
                    'lead' => new LeadResource($lead),
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Lead not found',
                'errors' => ['lead' => ['Lead not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch lead',
                'errors' => ['server' => ['An error occurred while fetching lead']]
            ], 500);
        }
    }

    /**
     * Create new lead
     */
    public function store(LeadRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['assigned_to'] = $data['assigned_to'] ?? $staff->id();
            $data['created_by'] = $staff->id();

            $lead = Lead::create($data);
            $lead->load(['status', 'source', 'assignedTo']);

            return response()->json([
                'success' => true,
                'message' => 'Lead created successfully',
                'data' => new LeadResource($lead)
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
                'message' => 'Failed to create lead',
                'errors' => ['server' => ['An error occurred while creating lead']]
            ], 500);
        }
    }

    /**
     * Update lead
     */
    public function update(LeadRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $lead = Lead::where('business_id', $businessId)->findOrFail($id);
            
            $data = $request->validated();
            $lead->update($data);
            $lead->load(['status', 'source', 'assignedTo']);

            return response()->json([
                'success' => true,
                'message' => 'Lead updated successfully',
                'data' => new LeadResource($lead)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Lead not found',
                'errors' => ['lead' => ['Lead not found']]
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
                'message' => 'Failed to update lead',
                'errors' => ['server' => ['An error occurred while updating lead']]
            ], 500);
        }
    }

    /**
     * Delete lead
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $lead = Lead::where('business_id', $businessId)->findOrFail($id);
            $lead->delete();

            return response()->json([
                'success' => true,
                'message' => 'Lead deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Lead not found',
                'errors' => ['lead' => ['Lead not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete lead',
                'errors' => ['server' => ['An error occurred while deleting lead']]
            ], 500);
        }
    }

    /**
     * Get lead sources for dropdown
     */
    public function getSources(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $sources = LeadSource::where('business_id', $businessId)
                                ->select('id', 'name', 'color')
                                ->orderBy('name')
                                ->get();

            return response()->json([
                'success' => true,
                'data' => $sources
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch lead sources',
                'errors' => ['server' => ['An error occurred while fetching sources']]
            ], 500);
        }
    }

    /**
     * Get lead statuses for dropdown
     */
    public function getStatuses(Request $request): JsonResponse
    {
        try {
            $statuses = Status::where('model_type', Lead::class)
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
                'message' => 'Failed to fetch lead statuses',
                'errors' => ['server' => ['An error occurred while fetching statuses']]
            ], 500);
        }
    }

    /**
     * Convert lead to client
     */
    public function convertToClient(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $lead = Lead::where('business_id', $businessId)->findOrFail($id);
            
            // Check if lead is already converted
            if ($lead->status === 'converted') {
                return response()->json([
                    'success' => false,
                    'message' => 'Lead is already converted',
                    'errors' => ['lead' => ['Lead is already converted']]
                ], 400);
            }

            // Convert lead to client
            $client = \App\Modules\Customers\Models\Client::create([
                'business_id' => $businessId,
                'first_name' => $lead->first_name,
                'last_name' => $lead->last_name,
                'email' => $lead->email,
                'phone' => $lead->phone,
                'company' => $lead->company,
                'address' => $lead->address,
                'city' => $lead->city,
                'state' => $lead->state,
                'country' => $lead->country,
                'postal_code' => $lead->postal_code,
                'created_by' => $staff->id(),
            ]);

            // Update lead status
            $lead->update(['status' => 'converted']);

            return response()->json([
                'success' => true,
                'message' => 'Lead converted to client successfully',
                'data' => [
                    'client_id' => $client->id(),
                    'lead' => new LeadResource($lead->fresh(['status', 'source', 'assignedTo']))
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Lead not found',
                'errors' => ['lead' => ['Lead not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to convert lead',
                'errors' => ['server' => ['An error occurred while converting lead']]
            ], 500);
        }
    }

    /**
     * Get lead statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Basic statistics
            $totalLeads = $myLeads = Lead::where('business_id', $businessId)
                          ->where('assigned_to', $staff->id())
                          ->count();
            $convertedLeads = Lead::where('business_id', $businessId)
                          ->where('assigned_to', $staff->id())
                                 ->whereHas('deal')
                                 ->count();
            $newLeadsToday = Lead::where('business_id', $businessId)
                          ->where('assigned_to', $staff->id())
                               ->whereDate('created_at', today())
                               ->count();
            $newLeadsThisMonth = Lead::where('business_id', $businessId)
                          ->where('assigned_to', $staff->id())
                                    ->whereMonth('created_at', now()->month)
                                    ->whereYear('created_at', now()->year)
                                    ->count();

            // Status breakdown
            $statusBreakdown = Lead::where('leads.business_id', $businessId)
                          ->where('assigned_to', $staff->id())
                                  ->leftJoin('status_list', 'leads.status_id', '=', 'status_list.status_id')
                                  ->selectRaw('
                                      COALESCE(status_list.name, "No Status") as status_name, 
                                      COALESCE(status_list.color, "#6c757d") as color, 
                                      COUNT(*) as count
                                  ')
                                  ->groupBy('leads.status_id', 'status_list.name', 'status_list.color')
                                  ->get();

            // Source breakdown
            $sourceBreakdown = Lead::where('leads.business_id', $businessId)
                          ->where('assigned_to', $staff->id())
                                  ->leftJoin('leads_sources', 'leads.source_id', '=', 'leads_sources.source_id')
                                  ->selectRaw('
                                      COALESCE(leads_sources.name, "No Source") as source_name, 
                                      COUNT(*) as count
                                  ')
                                  ->groupBy('leads.source_id', 'leads_sources.name')
                                  ->get();

            // Assignment breakdown
            $assignmentBreakdown = Lead::where('leads.business_id', $businessId)
                          ->where('assigned_to', $staff->id())
                                      ->leftJoin('staff', 'leads.assigned_to', '=', 'staff.staff_id')
                                      ->selectRaw('
                                          COALESCE(CONCAT(staff.first_name, " ", staff.last_name), "Unassigned") as staff_name,
                                          COUNT(*) as count
                                      ')
                                      ->groupBy('leads.assigned_to', 'staff.first_name', 'staff.last_name')
                                      ->get();

            // Monthly trends (last 12 months)
            $monthlyData = Lead::where('business_id', $businessId)
                          ->where('assigned_to', $staff->id())
                              ->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as month, COUNT(*) as count')
                              ->where('created_at', '>=', now()->subMonths(12))
                              ->groupBy('month')
                              ->orderBy('month')
                              ->get();

            // Conversion funnel
            $conversionFunnel = Lead::where('leads.business_id', $businessId)
                          ->where('leads.assigned_to', $staff->id())
                                   ->selectRaw('
                                       COUNT(*) as total_leads,
                                       COUNT(CASE WHEN deal.id IS NOT NULL THEN 1 END) as converted_to_deal,
                                       COUNT(CASE WHEN client.client_id IS NOT NULL THEN 1 END) as converted_to_client
                                   ')
                                   ->leftJoin('deals as deal', 'leads.lead_id', '=', 'deal.lead_id')
                                   ->leftJoin('clients as client', 'leads.email', '=', 'client.email')
                                   ->first();

            // Lead activity (recent activity)
            $recentActivity = Lead::where('business_id', $businessId)
                          ->where('assigned_to', $staff->id())
                                 ->selectRaw('
                                     DATE(created_at) as date,
                                     COUNT(*) as leads_created
                                 ')
                                 ->where('created_at', '>=', now()->subDays(30))
                                 ->groupBy('date')
                                 ->orderBy('date', 'desc')
                                 ->limit(30)
                                 ->get();

            // Lead aging analysis (leads by age)
            $leadAging = Lead::where('business_id', $businessId)
                          ->where('assigned_to', $staff->id())
                            ->whereDoesntHave('deal') // Not converted leads
                            ->selectRaw('
                                CASE 
                                    WHEN DATEDIFF(NOW(), created_at) <= 7 THEN "0-7 days"
                                    WHEN DATEDIFF(NOW(), created_at) <= 30 THEN "8-30 days"
                                    WHEN DATEDIFF(NOW(), created_at) <= 90 THEN "31-90 days"
                                    ELSE "90+ days"
                                END as age_group,
                                COUNT(*) as count
                            ')
                            ->groupBy('age_group')
                            ->get();

            // Calculate conversion rate
            $conversionRate = $totalLeads > 0 ? round(($convertedLeads / $totalLeads) * 100, 2) : 0;

            // Calculate average lead age
            $avgLeadAge = Lead::where('business_id', $businessId)
                          ->where('assigned_to', $staff->id())
                             ->selectRaw('AVG(DATEDIFF(NOW(), created_at)) as avg_age')
                             ->value('avg_age');

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_leads' => $totalLeads,
                        'my_leads' => $myLeads,
                        'converted_leads' => $convertedLeads,
                        'new_leads_today' => $newLeadsToday,
                        'new_leads_this_month' => $newLeadsThisMonth,
                        'conversion_rate' => $conversionRate,
                        'avg_lead_age_days' => $avgLeadAge ? round($avgLeadAge, 1) : 0,
                    ],
                    'status_breakdown' => $statusBreakdown,
                    'source_breakdown' => $sourceBreakdown,
                    'assignment_breakdown' => $assignmentBreakdown,
                    'conversion_funnel' => $conversionFunnel,
                    'monthly_trends' => $monthlyData,
                    'recent_activity' => $recentActivity,
                    'lead_aging' => $leadAging,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch lead statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
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

            $staffMembers = \App\Modules\Customers\Models\Staff::where('business_id', $businessId)
                                ->where('status', 1)
                                ->select('staff_id as id', 'first_name', 'last_name', 'email', 'picture')
                                ->orderBy('first_name')
                                ->get()
                                ->map(function ($member) {
                                    return [
                                        'id' => $member->id,
                                        'name' => $member->first_name . ' ' . $member->last_name,
                                        'email' => $member->email,
                                        'avatar' => $member->picture ? asset('storage/' . $member->picture) : null,
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
}