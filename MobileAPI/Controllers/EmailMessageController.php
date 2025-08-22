<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Emails\Models\EmailAccount;
use App\Modules\Emails\Models\EmailMessage;
use App\Modules\Emails\Models\EmailFolder;
use App\Modules\Emails\Services\EmailMessageService;
use App\Modules\Emails\Services\SendMail;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Requests\EmailMessageRequest;
use App\Modules\MobileAPI\Resources\EmailMessageResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EmailMessageController extends Controller
{
    protected $emailMessageService;

    public function __construct(EmailMessageService $emailMessageService)
    {
        $this->emailMessageService = $emailMessageService;
    }

    /**
     * Get paginated email messages list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = EmailMessage::forBusiness($businessId)
                                ->with(['attachments']);

            // Filter by account
            if ($accountId = $request->get('account_id')) {
                $account = EmailAccount::forBusiness($businessId)
                                      ->forUser($staff)
                                      ->findOrFail($accountId);
                $query->forAccount($account);
            } else {
                // Only show messages from user's accounts
                $userAccountIds = EmailAccount::forBusiness($businessId)
                                             ->forUser($staff)
                                             ->pluck('id');
                $query->whereIn('account_id', $userAccountIds);
            }

            // Filter by folder
            if ($folderName = $request->get('folder_name')) {
                $query->where('folder_name', $folderName);
            }

            // Filter by read status
            if ($request->has('read')) {
                $query->where('read', $request->get('read') ? 1 : 0);
            }

            // Filter by favourite status
            if ($request->has('favourite')) {
                $query->where('favourite', $request->get('favourite') ? 1 : 0);
            }

            // Filter by archived status
            if ($request->has('archived')) {
                $query->where('archived', $request->get('archived') ? 1 : 0);
            }

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('subject', 'like', "%{$search}%")
                      ->orWhere('sender_name', 'like', "%{$search}%")
                      ->orWhere('sender_email', 'like', "%{$search}%")
                      ->orWhere('message_text', 'like', "%{$search}%");
                });
            }

            // Filter by date range
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('delivery_date', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('delivery_date', '<=', $endDate);
            }

            // Filter by sender
            if ($senderEmail = $request->get('sender_email')) {
                $query->where('sender_email', $senderEmail);
            }

            // Filter messages with attachments
            if ($request->get('has_attachments')) {
                $query->has('attachments');
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'delivery_date');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $emailMessages = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'email_messages' => EmailMessageResource::collection($emailMessages->items()),
                    'pagination' => [
                        'current_page' => $emailMessages->currentPage(),
                        'last_page' => $emailMessages->lastPage(),
                        'per_page' => $emailMessages->perPage(),
                        'total' => $emailMessages->total(),
                        'from' => $emailMessages->firstItem(),
                        'to' => $emailMessages->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch email messages',
                'errors' => ['server' => ['An error occurred while fetching email messages: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single email message details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $emailMessage = EmailMessage::forBusiness($businessId)
                                       ->whereIn('account_id', $userAccountIds)
                                       ->with(['attachments'])
                                       ->findOrFail($id);

            // Mark as read if not already read
            if (!$emailMessage->read) {
                $emailMessage->update(['read' => 1]);
            }

            return response()->json([
                'success' => true,
                'data' => new EmailMessageResource($emailMessage)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email message not found',
                'errors' => ['email_message' => ['Email message not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch email message',
                'errors' => ['server' => ['An error occurred while fetching email message: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Send new email message
     */
    public function send(EmailMessageRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();

            // Verify account belongs to user
            $account = EmailAccount::forBusiness($businessId)
                                  ->forUser($staff)
                                  ->findOrFail($data['account_id']);

            // Send email using SendMail service
            $sendMail = new SendMail();
            $result = $sendMail->sendEmail([
                'account_id' => $account->id,
                'to' => $data['to'],
                'cc' => $data['cc'] ?? null,
                'bcc' => $data['bcc'] ?? null,
                'subject' => $data['subject'],
                'message' => $data['message'],
                'attachments' => $data['attachments'] ?? [],
                'signature_id' => $data['signature_id'] ?? null,
            ]);

            if ($result['success']) {
                return response()->json([
                    'success' => true,
                    'message' => 'Email sent successfully',
                    'data' => [
                        'message_id' => $result['message_id'] ?? null,
                    ]
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to send email',
                    'errors' => ['email' => [$result['message'] ?? 'Unknown error occurred']]
                ], 422);
            }

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email account not found',
                'errors' => ['account' => ['Email account not found']]
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
                'message' => 'Failed to send email',
                'errors' => ['server' => ['An error occurred while sending email: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Reply to email message
     */
    public function reply(EmailMessageRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $originalMessage = EmailMessage::forBusiness($businessId)
                                          ->whereIn('account_id', $userAccountIds)
                                          ->findOrFail($id);

            $data = $request->validated();

            // Get the account for sending
            $account = EmailAccount::forBusiness($businessId)
                                  ->forUser($staff)
                                  ->findOrFail($originalMessage->account_id);

            // Prepare reply data
            $replyData = [
                'account_id' => $account->id,
                'to' => $originalMessage->sender_email,
                'subject' => 'Re: ' . $originalMessage->subject,
                'message' => $data['message'],
                'cc' => $data['cc'] ?? null,
                'bcc' => $data['bcc'] ?? null,
                'attachments' => $data['attachments'] ?? [],
                'signature_id' => $data['signature_id'] ?? null,
                'in_reply_to' => $originalMessage->message_id,
            ];

            // Send reply using SendMail service
            $sendMail = new SendMail();
            $result = $sendMail->sendEmail($replyData);

            if ($result['success']) {
                return response()->json([
                    'success' => true,
                    'message' => 'Reply sent successfully',
                    'data' => [
                        'message_id' => $result['message_id'] ?? null,
                        'original_message_id' => $originalMessage->id,
                    ]
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to send reply',
                    'errors' => ['email' => [$result['message'] ?? 'Unknown error occurred']]
                ], 422);
            }

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email message not found',
                'errors' => ['email_message' => ['Email message not found']]
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
                'message' => 'Failed to send reply',
                'errors' => ['server' => ['An error occurred while sending reply: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Forward email message
     */
    public function forward(EmailMessageRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $originalMessage = EmailMessage::forBusiness($businessId)
                                          ->whereIn('account_id', $userAccountIds)
                                          ->with(['attachments'])
                                          ->findOrFail($id);

            $data = $request->validated();

            // Get the account for sending
            $account = EmailAccount::forBusiness($businessId)
                                  ->forUser($staff)
                                  ->findOrFail($originalMessage->account_id);

            // Prepare forward data
            $forwardData = [
                'account_id' => $account->id,
                'to' => $data['to'],
                'subject' => 'Fwd: ' . $originalMessage->subject,
                'message' => $data['message'] . "\n\n--- Forwarded Message ---\n" . $originalMessage->message_text,
                'cc' => $data['cc'] ?? null,
                'bcc' => $data['bcc'] ?? null,
                'attachments' => $data['attachments'] ?? [],
                'signature_id' => $data['signature_id'] ?? null,
            ];

            // Send forward using SendMail service
            $sendMail = new SendMail();
            $result = $sendMail->sendEmail($forwardData);

            if ($result['success']) {
                return response()->json([
                    'success' => true,
                    'message' => 'Email forwarded successfully',
                    'data' => [
                        'message_id' => $result['message_id'] ?? null,
                        'original_message_id' => $originalMessage->id,
                    ]
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to forward email',
                    'errors' => ['email' => [$result['message'] ?? 'Unknown error occurred']]
                ], 422);
            }

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email message not found',
                'errors' => ['email_message' => ['Email message not found']]
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
                'message' => 'Failed to forward email',
                'errors' => ['server' => ['An error occurred while forwarding email: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Mark message as read/unread
     */
    public function markAsRead(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $request->validate([
                'read' => 'required|boolean',
            ]);

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $emailMessage = EmailMessage::forBusiness($businessId)
                                       ->whereIn('account_id', $userAccountIds)
                                       ->findOrFail($id);

            $emailMessage->update(['read' => $request->read ? 1 : 0]);

            return response()->json([
                'success' => true,
                'message' => 'Message marked as ' . ($request->read ? 'read' : 'unread'),
                'data' => [
                    'id' => $emailMessage->id,
                    'read' => (bool) $emailMessage->read,
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email message not found',
                'errors' => ['email_message' => ['Email message not found']]
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
                'message' => 'Failed to update message',
                'errors' => ['server' => ['An error occurred while updating message: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Mark message as favourite/unfavourite
     */
    public function markAsFavourite(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $request->validate([
                'favourite' => 'required|boolean',
            ]);

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $emailMessage = EmailMessage::forBusiness($businessId)
                                       ->whereIn('account_id', $userAccountIds)
                                       ->findOrFail($id);

            $emailMessage->update(['favourite' => $request->favourite ? 1 : 0]);

            return response()->json([
                'success' => true,
                'message' => 'Message marked as ' . ($request->favourite ? 'favourite' : 'not favourite'),
                'data' => [
                    'id' => $emailMessage->id,
                    'favourite' => (bool) $emailMessage->favourite,
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email message not found',
                'errors' => ['email_message' => ['Email message not found']]
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
                'message' => 'Failed to update message',
                'errors' => ['server' => ['An error occurred while updating message: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Archive/unarchive message
     */
    public function archive(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $request->validate([
                'archived' => 'required|boolean',
            ]);

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $emailMessage = EmailMessage::forBusiness($businessId)
                                       ->whereIn('account_id', $userAccountIds)
                                       ->findOrFail($id);

            $emailMessage->update(['archived' => $request->archived ? 1 : 0]);

            return response()->json([
                'success' => true,
                'message' => 'Message ' . ($request->archived ? 'archived' : 'unarchived'),
                'data' => [
                    'id' => $emailMessage->id,
                    'archived' => (bool) $emailMessage->archived,
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email message not found',
                'errors' => ['email_message' => ['Email message not found']]
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
                'message' => 'Failed to update message',
                'errors' => ['server' => ['An error occurred while updating message: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Move message to folder
     */
    public function moveToFolder(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $request->validate([
                'folder_name' => 'required|string|max:255',
            ]);

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $emailMessage = EmailMessage::forBusiness($businessId)
                                       ->whereIn('account_id', $userAccountIds)
                                       ->findOrFail($id);

            $emailMessage->update(['folder_name' => $request->folder_name]);

            return response()->json([
                'success' => true,
                'message' => 'Message moved to folder successfully',
                'data' => [
                    'id' => $emailMessage->id,
                    'folder_name' => $emailMessage->folder_name,
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email message not found',
                'errors' => ['email_message' => ['Email message not found']]
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
                'message' => 'Failed to move message',
                'errors' => ['server' => ['An error occurred while moving message: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete email message
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $emailMessage = EmailMessage::forBusiness($businessId)
                                       ->whereIn('account_id', $userAccountIds)
                                       ->findOrFail($id);

            $emailMessage->delete();

            return response()->json([
                'success' => true,
                'message' => 'Email message deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email message not found',
                'errors' => ['email_message' => ['Email message not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete message',
                'errors' => ['server' => ['An error occurred while deleting message: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Search email messages
     */
    public function search(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $request->validate([
                'query' => 'required|string|min:3|max:255',
                'account_id' => 'nullable|exists:email_accounts,id',
                'folder_name' => 'nullable|string|max:255',
            ]);

            $query = EmailMessage::forBusiness($businessId);

            // Filter by user accounts
            if ($accountId = $request->account_id) {
                $account = EmailAccount::forBusiness($businessId)
                                      ->forUser($staff)
                                      ->findOrFail($accountId);
                $query->forAccount($account);
            } else {
                $userAccountIds = EmailAccount::forBusiness($businessId)
                                             ->forUser($staff)
                                             ->pluck('id');
                $query->whereIn('account_id', $userAccountIds);
            }

            // Filter by folder
            if ($folderName = $request->folder_name) {
                $query->where('folder_name', $folderName);
            }

            // Search functionality
            $searchTerm = $request->query;
            $query->where(function($q) use ($searchTerm) {
                $q->where('subject', 'like', "%{$searchTerm}%")
                  ->orWhere('sender_name', 'like', "%{$searchTerm}%")
                  ->orWhere('sender_email', 'like', "%{$searchTerm}%")
                  ->orWhere('message_text', 'like', "%{$searchTerm}%");
            });

            $messages = $query->with(['attachments'])
                             ->orderBy('delivery_date', 'desc')
                             ->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'messages' => EmailMessageResource::collection($messages->items()),
                    'search_query' => $searchTerm,
                    'total_results' => $messages->total(),
                    'pagination' => [
                        'current_page' => $messages->currentPage(),
                        'last_page' => $messages->lastPage(),
                        'per_page' => $messages->perPage(),
                        'total' => $messages->total(),
                        'from' => $messages->firstItem(),
                        'to' => $messages->lastItem(),
                    ]
                ]
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to search messages',
                'errors' => ['server' => ['An error occurred while searching messages: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get email message statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Get user's account IDs
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $totalMessages = EmailMessage::forBusiness($businessId)
                                        ->whereIn('account_id', $userAccountIds)
                                        ->count();

            $unreadMessages = EmailMessage::forBusiness($businessId)
                                         ->whereIn('account_id', $userAccountIds)
                                         ->where('read', 0)
                                         ->count();

            $favouriteMessages = EmailMessage::forBusiness($businessId)
                                            ->whereIn('account_id', $userAccountIds)
                                            ->where('favourite', 1)
                                            ->count();

            $archivedMessages = EmailMessage::forBusiness($businessId)
                                           ->whereIn('account_id', $userAccountIds)
                                           ->where('archived', 1)
                                           ->count();

            $todayMessages = EmailMessage::forBusiness($businessId)
                                        ->whereIn('account_id', $userAccountIds)
                                        ->whereDate('delivery_date', today())
                                        ->count();

            // Folder breakdown
            $folderBreakdown = EmailMessage::forBusiness($businessId)
                                          ->whereIn('account_id', $userAccountIds)
                                          ->selectRaw('folder_name, COUNT(*) as count')
                                          ->groupBy('folder_name')
                                          ->get();

            // Sender breakdown (top 10)
            $senderBreakdown = EmailMessage::forBusiness($businessId)
                                          ->whereIn('account_id', $userAccountIds)
                                          ->selectRaw('sender_email, sender_name, COUNT(*) as count')
                                          ->groupBy('sender_email', 'sender_name')
                                          ->orderByDesc('count')
                                          ->limit(10)
                                          ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_messages' => $totalMessages,
                        'unread_messages' => $unreadMessages,
                        'favourite_messages' => $favouriteMessages,
                        'archived_messages' => $archivedMessages,
                        'today_messages' => $todayMessages,
                        'read_rate' => $totalMessages > 0 ? round((($totalMessages - $unreadMessages) / $totalMessages) * 100, 2) : 0,
                    ],
                    'folder_breakdown' => $folderBreakdown,
                    'sender_breakdown' => $senderBreakdown,
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
