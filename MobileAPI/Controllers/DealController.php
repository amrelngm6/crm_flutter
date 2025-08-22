<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Deals\Models\Deal;
use App\Modules\Pipelines\Models\PipelineSelected;
use App\Modules\Pipelines\Models\Pipeline;
use App\Modules\Pipelines\Models\PipelineStage;
use App\Modules\Core\Models\ModelMember;
use App\Modules\Customers\Models\Staff;
use App\Modules\Customers\Models\Client;
use App\Modules\Leads\Models\Lead;
use App\Modules\MobileAPI\Requests\DealRequest;
use App\Modules\MobileAPI\Resources\DealResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DealController extends Controller
{
    /**
     * Get paginated deals list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Deal::where('business_id', $businessId)
                        ->with(['client', 'lead', 'stage.stage', 'stage.pipeline', 'team', 'author']);

            // Filter by assigned deals only if requested
            if ($request->get('my_deals_only', false)) {
                $query->whereHas('team', function($q) use ($staff) {
                    $q->where('user_id', $staff->staff_id);
                });
            }

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('description', 'like', "%{$search}%")
                      ->orWhere('code', 'like', "%{$search}%");
                });
            }

            // Filter by status
            if ($status = $request->get('status')) {
                $query->where('status', $status);
            }

            // Filter by pipeline stage
            if ($stageId = $request->get('stage_id')) {
                $query->whereHas('stage', function($q) use ($stageId) {
                    $q->where('pipeline_stage_id', $stageId);
                });
            }

            // Filter by pipeline
            if ($pipelineId = $request->get('pipeline_id')) {
                $query->whereHas('stage', function($q) use ($pipelineId) {
                    $q->where('pipeline_id', $pipelineId);
                });
            }

            // Filter by amount range
            if ($minAmount = $request->get('min_amount')) {
                $query->where('amount', '>=', $minAmount);
            }
            if ($maxAmount = $request->get('max_amount')) {
                $query->where('amount', '<=', $maxAmount);
            }

            // Filter by probability range
            if ($minProbability = $request->get('min_probability')) {
                $query->where('probability', '>=', $minProbability);
            }
            if ($maxProbability = $request->get('max_probability')) {
                $query->where('probability', '<=', $maxProbability);
            }

            // Filter by expected due date
            if ($startDate = $request->get('expected_start_date')) {
                $query->whereDate('expected_due_date', '>=', $startDate);
            }
            if ($endDate = $request->get('expected_end_date')) {
                $query->whereDate('expected_due_date', '<=', $endDate);
            }

            // Filter by client
            if ($clientId = $request->get('client_id')) {
                $query->where('client_id', $clientId);
            }

            // Filter by lead
            if ($leadId = $request->get('lead_id')) {
                $query->where('lead_id', $leadId);
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $deals = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'deals' => DealResource::collection($deals->items()),
                    'pagination' => [
                        'current_page' => $deals->currentPage(),
                        'last_page' => $deals->lastPage(),
                        'per_page' => $deals->perPage(),
                        'total' => $deals->total(),
                        'from' => $deals->firstItem(),
                        'to' => $deals->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch deals',
                'errors' => ['server' => ['An error occurred while fetching deals: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single deal details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $deal = Deal::where('business_id', $businessId)
                       ->with([
                           'client', 'lead', 'stage.stage', 'stage.pipeline', 
                           'team', 'author', 'tasks', 'location_info'
                       ])
                       ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new DealResource($deal)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Deal not found',
                'errors' => ['deal' => ['Deal not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch deal',
                'errors' => ['server' => ['An error occurred while fetching deal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new deal
     */
    public function store(DealRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['created_by'] = $staff->staff_id;

            $deal = Deal::create($data);

            // Assign team members to deal
            if (isset($data['team']) && is_array($data['team'])) {
                foreach ($data['team'] as $memberId) {
                    ModelMember::create([
                        'model_type' => Deal::class,
                        'model_id' => $deal->id,
                        'user_type' => Staff::class,
                        'user_id' => $memberId,
                    ]);
                }
            } else {
                // Assign to creator by default
                ModelMember::create([
                    'model_type' => Deal::class,
                    'model_id' => $deal->id,
                    'user_type' => Staff::class,
                    'user_id' => $staff->staff_id,
                ]);
            }

            // Set pipeline stage if provided
            if (isset($data['pipeline_stage_id'])) {
                $pipelineStage = PipelineStage::find($data['pipeline_stage_id']);
                if ($pipelineStage) {
                    PipelineSelected::create([
                        'business_id' => $businessId,
                        'pipeline_id' => $pipelineStage->pipeline_id,
                        'pipeline_stage_id' => $data['pipeline_stage_id'],
                        'model_type' => Deal::class,
                        'model_id' => $deal->id,
                        'created_by' => $staff->staff_id,
                    ]);
                }
            }

            $deal->load(['client', 'lead', 'stage.stage', 'stage.pipeline', 'team', 'author']);

            return response()->json([
                'success' => true,
                'message' => 'Deal created successfully',
                'data' => new DealResource($deal)
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
                'message' => 'Failed to create deal',
                'errors' => ['server' => ['An error occurred while creating deal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update deal
     */
    public function update(DealRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $deal = Deal::where('business_id', $businessId)->findOrFail($id);
            
            $data = $request->validated();
            $deal->update($data);

            // Update team members if provided
            if (isset($data['team']) && is_array($data['team'])) {
                // Remove existing team members
                ModelMember::where('model_type', Deal::class)
                          ->where('model_id', $deal->id)
                          ->delete();

                // Add new team members
                foreach ($data['team'] as $memberId) {
                    ModelMember::create([
                        'model_type' => Deal::class,
                        'model_id' => $deal->id,
                        'user_type' => Staff::class,
                        'user_id' => $memberId,
                    ]);
                }
            }

            // Update pipeline stage if provided
            if (isset($data['pipeline_stage_id'])) {
                $existingStage = PipelineSelected::where('model_type', Deal::class)
                                                ->where('model_id', $deal->id)
                                                ->first();

                $pipelineStage = PipelineStage::find($data['pipeline_stage_id']);
                if ($pipelineStage) {
                    if ($existingStage) {
                        $existingStage->update([
                            'pipeline_id' => $pipelineStage->pipeline_id,
                            'pipeline_stage_id' => $data['pipeline_stage_id'],
                        ]);
                    } else {
                        PipelineSelected::create([
                            'business_id' => $businessId,
                            'pipeline_id' => $pipelineStage->pipeline_id,
                            'pipeline_stage_id' => $data['pipeline_stage_id'],
                            'model_type' => Deal::class,
                            'model_id' => $deal->id,
                            'created_by' => $staff->staff_id,
                        ]);
                    }
                }
            }

            $deal->load(['client', 'lead', 'stage.stage', 'stage.pipeline', 'team', 'author']);

            return response()->json([
                'success' => true,
                'message' => 'Deal updated successfully',
                'data' => new DealResource($deal)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Deal not found',
                'errors' => ['deal' => ['Deal not found']]
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
                'message' => 'Failed to update deal',
                'errors' => ['server' => ['An error occurred while updating deal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete deal
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $deal = Deal::where('business_id', $businessId)->findOrFail($id);
            $deal->delete();

            return response()->json([
                'success' => true,
                'message' => 'Deal deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Deal not found',
                'errors' => ['deal' => ['Deal not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete deal',
                'errors' => ['server' => ['An error occurred while deleting deal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Move deal to different pipeline stage
     */
    public function moveToStage(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $deal = Deal::where('business_id', $businessId)->findOrFail($id);
            
            $request->validate([
                'pipeline_stage_id' => 'required|exists:pipeline_stages,id'
            ]);

            $pipelineStage = PipelineStage::findOrFail($request->pipeline_stage_id);
            
            $existingStage = PipelineSelected::where('model_type', Deal::class)
                                            ->where('model_id', $deal->id)
                                            ->first();

            if ($existingStage) {
                $existingStage->update([
                    'pipeline_id' => $pipelineStage->pipeline_id,
                    'pipeline_stage_id' => $request->pipeline_stage_id,
                ]);
            } else {
                PipelineSelected::create([
                    'business_id' => $businessId,
                    'pipeline_id' => $pipelineStage->pipeline_id,
                    'pipeline_stage_id' => $request->pipeline_stage_id,
                    'model_type' => Deal::class,
                    'model_id' => $deal->id,
                    'created_by' => $staff->staff_id,
                ]);
            }

            $deal->load(['stage.stage', 'stage.pipeline']);

            return response()->json([
                'success' => true,
                'message' => 'Deal moved to new stage successfully',
                'data' => [
                    'stage' => [
                        'id' => $deal->stage->pipeline_stage_id ?? null,
                        'name' => $deal->stage->stage->name ?? null,
                        'color' => $deal->stage->stage->color ?? null,
                        'pipeline' => [
                            'id' => $deal->stage->pipeline_id ?? null,
                            'name' => $deal->stage->pipeline->name ?? null,
                        ]
                    ]
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Deal not found',
                'errors' => ['deal' => ['Deal not found']]
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
                'message' => 'Failed to move deal to stage',
                'errors' => ['server' => ['An error occurred while moving deal: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get pipelines for dropdown
     */
    public function getPipelines(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $pipelines = Pipeline::where('business_id', $businessId)
                                ->where('model', Deal::class)
                                ->with('stages')
                                ->orderBy('name')
                                ->get()
                                ->map(function($pipeline) {
                                    return [
                                        'id' => $pipeline->id,
                                        'name' => $pipeline->name,
                                        'description' => $pipeline->description,
                                        'stages' => $pipeline->stages->map(function($stage) {
                                            return [
                                                'id' => $stage->id,
                                                'name' => $stage->name,
                                                'color' => $stage->color,
                                                'probability' => $stage->probability,
                                                'sort_order' => $stage->sort,
                                            ];
                                        }),
                                    ];
                                });

            return response()->json([
                'success' => true,
                'data' => $pipelines
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch pipelines',
                'errors' => ['server' => ['An error occurred while fetching pipelines: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get pipeline stages for dropdown
     */
    public function getPipelineStages(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $query = PipelineStage::whereHas('pipeline', function($q) use ($businessId) {
                $q->where('business_id', $businessId)
                  ->where('model', Deal::class);
            });

            if ($pipelineId = $request->get('pipeline_id')) {
                $query->where('pipeline_id', $pipelineId);
            }

            $stages = $query->with('pipeline:id,name')
                           ->orderBy('sort')
                           ->get()
                           ->map(function($stage) {
                               return [
                                   'id' => $stage->id,
                                   'name' => $stage->name,
                                   'color' => $stage->color,
                                   'probability' => $stage->probability,
                                   'sort_order' => $stage->sort,
                                   'pipeline' => [
                                       'id' => $stage->pipeline->id,
                                       'name' => $stage->pipeline->name,
                                   ]
                               ];
                           });

            return response()->json([
                'success' => true,
                'data' => $stages
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch pipeline stages',
                'errors' => ['server' => ['An error occurred while fetching stages: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get clients for dropdown
     */
    public function getClients(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $clients = Client::where('business_id', $businessId)
                            ->select('client_id as id', 'name', 'email', 'phone', 'company_name')
                            ->orderBy('name')
                            ->get()
                            ->map(function($client) {
                                return [
                                    'id' => $client->id,
                                    'name' => $client->name,
                                    'email' => $client->email,
                                    'phone' => $client->phone,
                                    'company_name' => $client->company_name,
                                    'display_name' => $client->company_name ? 
                                        "{$client->name} ({$client->company_name})" : 
                                        $client->name,
                                ];
                            });

            return response()->json([
                'success' => true,
                'data' => $clients
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch clients',
                'errors' => ['server' => ['An error occurred while fetching clients: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get leads for dropdown
     */
    public function getLeads(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $leads = Lead::where('business_id', $businessId)
                        ->whereNull('converted_to_client_at') // Only unconverted leads
                        ->select('lead_id as id', 'first_name', 'last_name', 'email', 'phone', 'company_name')
                        ->orderBy('first_name')
                        ->get()
                        ->map(function($lead) {
                            return [
                                'id' => $lead->id,
                                'name' => $lead->first_name . ' ' . $lead->last_name,
                                'email' => $lead->email,
                                'phone' => $lead->phone,
                                'company_name' => $lead->company_name,
                                'display_name' => $lead->company_name ? 
                                    "{$lead->first_name} {$lead->last_name} ({$lead->company_name})" : 
                                    "{$lead->first_name} {$lead->last_name}",
                            ];
                        });

            return response()->json([
                'success' => true,
                'data' => $leads
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch leads',
                'errors' => ['server' => ['An error occurred while fetching leads: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get deal statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $totalDeals = Deal::where('business_id', $businessId)->count();
            $totalValue = Deal::where('business_id', $businessId)->sum('amount');
            $avgDealValue = $totalDeals > 0 ? $totalValue / $totalDeals : 0;
            $avgProbability = Deal::where('business_id', $businessId)->avg('probability') ?? 0;

            // Status breakdown
            $statusBreakdown = Deal::where('business_id', $businessId)
                                  ->selectRaw('status, COUNT(*) as count, SUM(amount) as total_value')
                                  ->groupBy('status')
                                  ->get()
                                  ->keyBy('status');

            // Monthly trends (last 12 months)
            $monthlyData = Deal::where('business_id', $businessId)
                              ->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as month, COUNT(*) as count, SUM(amount) as total_value')
                              ->where('created_at', '>=', now()->subMonths(12))
                              ->groupBy('month')
                              ->orderBy('month')
                              ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_deals' => $totalDeals,
                        'total_value' => $totalValue,
                        'average_deal_value' => round($avgDealValue, 2),
                        'average_probability' => round($avgProbability, 2),
                    ],
                    'status_breakdown' => $statusBreakdown,
                    'monthly_trends' => $monthlyData,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch deal statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }
}
