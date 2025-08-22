<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Emails\Models\EmailAccount;
use App\Modules\Emails\Models\EmailFolder;
use App\Modules\Emails\Services\EmailAccountService;
use App\Modules\Emails\Services\EmailMessageService;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Requests\EmailAccountRequest;
use App\Modules\MobileAPI\Resources\EmailAccountResource;
use App\Modules\MobileAPI\Resources\EmailFolderResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;

class EmailAccountController extends Controller
{
    protected $emailAccountService;
    protected $emailMessageService;

    public function __construct(EmailAccountService $emailAccountService, EmailMessageService $emailMessageService)
    {
        $this->emailAccountService = $emailAccountService;
        $this->emailMessageService = $emailMessageService;
    }

    /**
     * Get paginated email accounts list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = EmailAccount::forBusiness($businessId)
                                ->with(['folder']);

            // Filter by user (only show accounts for current user)
            $query->forUser($staff);

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('email', 'like', "%{$search}%")
                      ->orWhere('imap_host', 'like', "%{$search}%")
                      ->orWhere('smtp_host', 'like', "%{$search}%");
                });
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $emailAccounts = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'email_accounts' => EmailAccountResource::collection($emailAccounts->items()),
                    'pagination' => [
                        'current_page' => $emailAccounts->currentPage(),
                        'last_page' => $emailAccounts->lastPage(),
                        'per_page' => $emailAccounts->perPage(),
                        'total' => $emailAccounts->total(),
                        'from' => $emailAccounts->firstItem(),
                        'to' => $emailAccounts->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch email accounts',
                'errors' => ['server' => ['An error occurred while fetching email accounts: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single email account details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $emailAccount = EmailAccount::forBusiness($businessId)
                                       ->forUser($staff)
                                       ->with(['folder', 'messages'])
                                       ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new EmailAccountResource($emailAccount)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email account not found',
                'errors' => ['email_account' => ['Email account not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch email account',
                'errors' => ['server' => ['An error occurred while fetching email account: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new email account
     */
    public function store(EmailAccountRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['user_id'] = $staff->staff_id;
            $data['user_type'] = Staff::class;

            // Encrypt passwords
            if (isset($data['imap_password'])) {
                $data['imap_password'] = Crypt::encryptString($data['imap_password']);
            }
            if (isset($data['smtp_password'])) {
                $data['smtp_password'] = Crypt::encryptString($data['smtp_password']);
            }

            $emailAccount = EmailAccount::create($data);
            $emailAccount->load(['folder', 'messages']);

            // Test connection and fetch folders
            try {
                $this->emailAccountService->connect($emailAccount);
                $this->emailAccountService->fetchFolders($emailAccount);
            } catch (\Exception $e) {
                // Log connection error but don't fail account creation
                logger()->warning('Failed to connect to email account after creation: ' . $e->getMessage());
            }

            return response()->json([
                'success' => true,
                'message' => 'Email account created successfully',
                'data' => new EmailAccountResource($emailAccount)
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
                'message' => 'Failed to create email account',
                'errors' => ['server' => ['An error occurred while creating email account: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update email account
     */
    public function update(EmailAccountRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $emailAccount = EmailAccount::forBusiness($businessId)
                                       ->forUser($staff)
                                       ->findOrFail($id);
            
            $data = $request->validated();

            // Encrypt passwords if provided
            if (isset($data['imap_password'])) {
                $data['imap_password'] = Crypt::encryptString($data['imap_password']);
            }
            if (isset($data['smtp_password'])) {
                $data['smtp_password'] = Crypt::encryptString($data['smtp_password']);
            }

            $emailAccount->update($data);
            $emailAccount->load(['folder', 'messages']);

            return response()->json([
                'success' => true,
                'message' => 'Email account updated successfully',
                'data' => new EmailAccountResource($emailAccount)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email account not found',
                'errors' => ['email_account' => ['Email account not found']]
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
                'message' => 'Failed to update email account',
                'errors' => ['server' => ['An error occurred while updating email account: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete email account
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $emailAccount = EmailAccount::forBusiness($businessId)
                                       ->forUser($staff)
                                       ->findOrFail($id);
            
            $emailAccount->delete();

            return response()->json([
                'success' => true,
                'message' => 'Email account deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email account not found',
                'errors' => ['email_account' => ['Email account not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete email account',
                'errors' => ['server' => ['An error occurred while deleting email account: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Test email account connection
     */
    public function testConnection(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $emailAccount = EmailAccount::forBusiness($businessId)
                                       ->forUser($staff)
                                       ->findOrFail($id);

            // Test IMAP connection
            $imapConnected = false;
            $imapError = null;
            try {
                $this->emailAccountService->connect($emailAccount);
                $imapConnected = true;
            } catch (\Exception $e) {
                $imapError = $e->getMessage();
            }

            // Test SMTP connection (basic validation)
            $smtpValid = !empty($emailAccount->smtp_host) && !empty($emailAccount->smtp_port);

            return response()->json([
                'success' => true,
                'data' => [
                    'imap' => [
                        'connected' => $imapConnected,
                        'error' => $imapError,
                        'host' => $emailAccount->imap_host,
                        'port' => $emailAccount->imap_port,
                    ],
                    'smtp' => [
                        'valid' => $smtpValid,
                        'host' => $emailAccount->smtp_host,
                        'port' => $emailAccount->smtp_port,
                    ]
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email account not found',
                'errors' => ['email_account' => ['Email account not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to test connection',
                'errors' => ['server' => ['An error occurred while testing connection: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Fetch emails from server
     */
    public function fetchEmails(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $emailAccount = EmailAccount::forBusiness($businessId)
                                       ->forUser($staff)
                                       ->findOrFail($id);

            $fetchedCount = $this->emailAccountService->fetchEmails($emailAccount);

            return response()->json([
                'success' => true,
                'message' => 'Emails fetched successfully',
                'data' => [
                    'fetched_count' => $fetchedCount,
                    'account_id' => $emailAccount->id,
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email account not found',
                'errors' => ['email_account' => ['Email account not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch emails',
                'errors' => ['server' => ['An error occurred while fetching emails: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get folders for an email account
     */
    public function getFolders(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $emailAccount = EmailAccount::forBusiness($businessId)
                                       ->forUser($staff)
                                       ->findOrFail($id);

            $folders = EmailFolder::where('account_id', $emailAccount->id)
                                 ->orderBy('name')
                                 ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'folders' => EmailFolderResource::collection($folders),
                    'account_id' => $emailAccount->id,
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email account not found',
                'errors' => ['email_account' => ['Email account not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch folders',
                'errors' => ['server' => ['An error occurred while fetching folders: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create a new folder
     */
    public function createFolder(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $emailAccount = EmailAccount::forBusiness($businessId)
                                       ->forUser($staff)
                                       ->findOrFail($id);

            $request->validate([
                'name' => 'required|string|max:255',
            ]);

            $folder = EmailFolder::create([
                'account_id' => $emailAccount->id,
                'name' => $request->name,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Folder created successfully',
                'data' => new EmailFolderResource($folder)
            ], 201);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email account not found',
                'errors' => ['email_account' => ['Email account not found']]
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
                'message' => 'Failed to create folder',
                'errors' => ['server' => ['An error occurred while creating folder: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete a folder
     */
    public function deleteFolder(Request $request, int $id, int $folderId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $emailAccount = EmailAccount::forBusiness($businessId)
                                       ->forUser($staff)
                                       ->findOrFail($id);

            $folder = EmailFolder::where('account_id', $emailAccount->id)
                                ->where('id', $folderId)
                                ->firstOrFail();

            $folder->delete();

            return response()->json([
                'success' => true,
                'message' => 'Folder deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email account or folder not found',
                'errors' => ['folder' => ['Email account or folder not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete folder',
                'errors' => ['server' => ['An error occurred while deleting folder: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get email account statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $totalAccounts = EmailAccount::forBusiness($businessId)->forUser($staff)->count();
            $totalMessages = EmailAccount::forBusiness($businessId)
                                        ->forUser($staff)
                                        ->withCount('messages')
                                        ->get()
                                        ->sum('messages_count');

            $unreadMessages = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->join('email_messages', 'email_accounts.id', '=', 'email_messages.account_id')
                                         ->where('email_messages.read', 0)
                                         ->count();

            $favouriteMessages = EmailAccount::forBusiness($businessId)
                                            ->forUser($staff)
                                            ->join('email_messages', 'email_accounts.id', '=', 'email_messages.account_id')
                                            ->where('email_messages.favourite', 1)
                                            ->count();

            // Account breakdown
            $accountBreakdown = EmailAccount::forBusiness($businessId)
                                           ->forUser($staff)
                                           ->withCount('messages')
                                           ->get()
                                           ->map(function($account) {
                                               return [
                                                   'email' => $account->email,
                                                   'messages_count' => $account->messages_count,
                                               ];
                                           });

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_accounts' => $totalAccounts,
                        'total_messages' => $totalMessages,
                        'unread_messages' => $unreadMessages,
                        'favourite_messages' => $favouriteMessages,
                    ],
                    'account_breakdown' => $accountBreakdown,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch email statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }
}
