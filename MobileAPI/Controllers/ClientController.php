<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Customers\Models\Client;
use App\Modules\MobileAPI\Requests\ClientRequest;
use App\Modules\MobileAPI\Resources\ClientResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClientController extends Controller
{
    /**
     * Get paginated clients list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Client::where('business_id', $businessId);

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
            if ($request->get('status') > -1) {
                $query->where('status', $request->get('status'));
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

            $clients = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'clients' => ClientResource::collection($clients->items()),
                    'pagination' => [
                        'current_page' => $clients->currentPage(),
                        'last_page' => $clients->lastPage(),
                        'per_page' => $clients->perPage(),
                        'total' => $clients->total(),
                        'from' => $clients->firstItem(),
                        'to' => $clients->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            \Log::info('Failed to fetch clients', ['error' => $e->getMessage(), 'file' => $e->getFile(), 'line' => $e->getLine()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch clients',
                'errors' => ['server' => ['An error occurred while fetching clients']]
            ], 500);
        }
    }

    /**
     * Get single client details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $client = Client::where('business_id', $businessId)
                           ->with(['projects', 'invoices'])
                           ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new ClientResource($client)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found',
                'errors' => ['client' => ['Client not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch client',
                'errors' => ['server' => ['An error occurred while fetching client']]
            ], 500);
        }
    }

    /**
     * Create new client
     */
    public function store(ClientRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['created_by'] = $staff->id;

            $client = Client::create($data);
            $client->load(['status']);

            return response()->json([
                'success' => true,
                'message' => 'Client created successfully',
                'data' => new ClientResource($client)
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
                'message' => 'Failed to create client',
                'errors' => ['server' => ['An error occurred while creating client']]
            ], 500);
        }
    }

    /**
     * Update client
     */
    public function update(ClientRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $client = Client::where('business_id', $businessId)->findOrFail($id);
            
            $data = $request->validated();
            $client->update($data);
            $client->load(['status']);

            return response()->json([
                'success' => true,
                'message' => 'Client updated successfully',
                'data' => new ClientResource($client)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found',
                'errors' => ['client' => ['Client not found']]
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
                'message' => 'Failed to update client',
                'errors' => ['server' => ['An error occurred while updating client']]
            ], 500);
        }
    }

    /**
     * Delete client
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $client = Client::where('business_id', $businessId)->findOrFail($id);
            $client->delete();

            return response()->json([
                'success' => true,
                'message' => 'Client deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found',
                'errors' => ['client' => ['Client not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete client',
                'errors' => ['server' => ['An error occurred while deleting client']]
            ], 500);
        }
    }

    /**
     * Get client projects
     */
    public function getProjects(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $client = Client::where('business_id', $businessId)->findOrFail($id);
            $projects = $client->projects()->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'projects' => $projects->items(),
                    'pagination' => [
                        'current_page' => $projects->currentPage(),
                        'last_page' => $projects->lastPage(),
                        'per_page' => $projects->perPage(),
                        'total' => $projects->total(),
                    ]
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found',
                'errors' => ['client' => ['Client not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch client projects',
                'errors' => ['server' => ['An error occurred while fetching projects']]
            ], 500);
        }
    }

    /**
     * Get client invoices
     */
    public function getInvoices(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $client = Client::where('business_id', $businessId)->findOrFail($id);
            $invoices = $client->invoices()->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'invoices' => $invoices->items(),
                    'pagination' => [
                        'current_page' => $invoices->currentPage(),
                        'last_page' => $invoices->lastPage(),
                        'per_page' => $invoices->perPage(),
                        'total' => $invoices->total(),
                    ]
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found',
                'errors' => ['client' => ['Client not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch client invoices',
                'errors' => ['server' => ['An error occurred while fetching invoices']]
            ], 500);
        }
    }
}
