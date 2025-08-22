<?php

use Illuminate\Support\Facades\Route;
use App\Modules\MobileAPI\Controllers\AuthController;
use App\Modules\MobileAPI\Controllers\DashboardController;
use App\Modules\MobileAPI\Controllers\LeadController;
use App\Modules\MobileAPI\Controllers\TaskController;
use App\Modules\MobileAPI\Controllers\ClientController;
use App\Modules\MobileAPI\Controllers\MeetingController;
use App\Modules\MobileAPI\Controllers\NotificationController;
use App\Modules\MobileAPI\Controllers\DealController;
use App\Modules\MobileAPI\Controllers\ProposalController;
use App\Modules\MobileAPI\Controllers\EstimateController;
use App\Modules\MobileAPI\Controllers\TicketController;
use App\Modules\MobileAPI\Controllers\TodoController;
use App\Modules\MobileAPI\Controllers\TimesheetController;
use App\Modules\MobileAPI\Controllers\NoteController;
use App\Modules\MobileAPI\Controllers\CommentController;
use App\Modules\MobileAPI\Controllers\GoalController;
use App\Modules\MobileAPI\Controllers\ReminderController;
use App\Modules\MobileAPI\Controllers\EstimateRequestController;
use App\Modules\MobileAPI\Controllers\ChatController;
use App\Modules\MobileAPI\Controllers\EmailAccountController;
use App\Modules\MobileAPI\Controllers\EmailMessageController;
use App\Modules\MobileAPI\Controllers\EmailAttachmentController;
use App\Modules\MobileAPI\Controllers\EmailSignatureController;

/*
|--------------------------------------------------------------------------
| Mobile API Routes
|--------------------------------------------------------------------------
|
| Professional Mobile API routes for MediansCRM Flutter application.
| All routes are prefixed with 'api/mobile' and return JSON responses.
|
*/

// Public authentication routes
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/refresh', [AuthController::class, 'refresh']);
});

// Protected mobile API routes
Route::middleware(['auth:sanctum'])->group(function () {
    
    // Authentication & Profile
    Route::prefix('auth')->group(function () {
        Route::get('/profile', [AuthController::class, 'profile']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/change-password', [AuthController::class, 'changePassword']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::post('/logout-all', [AuthController::class, 'logoutAll']);
    });

    // Dashboard
    Route::prefix('dashboard')->group(function () {
        Route::get('/', [DashboardController::class, 'index']);
        Route::get('/statistics', [DashboardController::class, 'getStatistics']);
    });

    // Leads Management
    Route::prefix('leads')->group(function () {
        Route::get('/', [LeadController::class, 'index']);
        Route::post('/', [LeadController::class, 'store']);
        Route::get('/statistics', [LeadController::class, 'getStatistics']);
        Route::get('/sources', [LeadController::class, 'getSources']);
        Route::get('/statuses', [LeadController::class, 'getStatuses']);
        Route::get('/staff-members', [LeadController::class, 'getStaffMembers']);
        Route::get('/{id}', [LeadController::class, 'show']);
        Route::put('/{id}', [LeadController::class, 'update']);
        Route::delete('/{id}', [LeadController::class, 'destroy']);
        Route::post('/{id}/convert-to-client', [LeadController::class, 'convertToClient']);
    });

    // Tasks Management
    Route::prefix('tasks')->group(function () {
        Route::get('/', [TaskController::class, 'index']);
        Route::post('/', [TaskController::class, 'store']);
        Route::get('/statistics', [TaskController::class, 'getStatistics']);
        Route::get('/statuses', [TaskController::class, 'getStatuses']);
        Route::get('/priorities', [TaskController::class, 'getPriorities']);
        Route::get('/staff-members', [TaskController::class, 'getStaffMembers']);
        Route::get('/{id}', [TaskController::class, 'show']);
        Route::put('/{id}', [TaskController::class, 'update']);
        Route::delete('/{id}', [TaskController::class, 'destroy']);
        Route::post('/{id}/mark-completed', [TaskController::class, 'markCompleted']);
        Route::post('/{id}/add-checklist-item', [TaskController::class, 'addChecklistItem']);
        Route::put('/{taskId}/checklist/{checklistId}', [TaskController::class, 'updateChecklistItem']);
    });

    // Clients Management
    Route::prefix('clients')->group(function () {
        Route::get('/', [ClientController::class, 'index']);
        Route::post('/', [ClientController::class, 'store']);
        Route::get('/{id}', [ClientController::class, 'show']);
        Route::put('/{id}', [ClientController::class, 'update']);
        Route::delete('/{id}', [ClientController::class, 'destroy']);
        Route::get('/{id}/projects', [ClientController::class, 'getProjects']);
        Route::get('/{id}/invoices', [ClientController::class, 'getInvoices']);
    });

    // Meetings Management
    Route::prefix('meetings')->group(function () {
        Route::get('/', [MeetingController::class, 'index']);
        Route::post('/', [MeetingController::class, 'store']);
        Route::get('/statistics', [MeetingController::class, 'getStatistics']);
        Route::get('/statuses', [MeetingController::class, 'getStatuses']);
        Route::get('/priorities', [MeetingController::class, 'getPriorities']);
        Route::get('/staff-members', [MeetingController::class, 'getStaffMembers']);
        Route::get('/clients', [MeetingController::class, 'getClients']);
        Route::get('/{id}', [MeetingController::class, 'show']);
        Route::put('/{id}', [MeetingController::class, 'update']);
        Route::delete('/{id}', [MeetingController::class, 'destroy']);
        Route::get('/calendar/{date}', [MeetingController::class, 'getCalendarEvents']);
    });

    // Notifications
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::get('/{id}', [NotificationController::class, 'show']);
        Route::post('/{id}/mark-read', [NotificationController::class, 'markAsRead']);
        Route::post('/mark-all-read', [NotificationController::class, 'markAllAsRead']);
        Route::delete('/{id}', [NotificationController::class, 'destroy']);
        Route::delete('/bulk-delete', [NotificationController::class, 'bulkDestroy']);
        Route::get('/unread-count', [NotificationController::class, 'getUnreadCount']);
        Route::get('/statistics', [NotificationController::class, 'getStatistics']);
    });

    // Deals Management
    Route::prefix('deals')->group(function () {
        Route::get('/', [DealController::class, 'index']);
        Route::post('/', [DealController::class, 'store']);
        Route::get('/pipelines', [DealController::class, 'getPipelines']);
        Route::get('/stages', [DealController::class, 'getPipelineStages']);
        Route::get('/clients', [DealController::class, 'getClients']);
        Route::get('/leads', [DealController::class, 'getLeads']);
        Route::get('/statistics', [DealController::class, 'getStatistics']);
        Route::get('/{id}', [DealController::class, 'show']);
        Route::put('/{id}', [DealController::class, 'update']);
        Route::delete('/{id}', [DealController::class, 'destroy']);
        Route::post('/{id}/move-to-stage', [DealController::class, 'moveToStage']);
    });

    // Proposals Management
    Route::prefix('proposals')->group(function () {
        Route::get('/', [ProposalController::class, 'index']);
        Route::post('/', [ProposalController::class, 'store']);
        Route::get('/statuses', [ProposalController::class, 'getStatuses']);
        Route::get('/staff-members', [ProposalController::class, 'getStaffMembers']);
        Route::get('/statistics', [ProposalController::class, 'getStatistics']);
        Route::get('/{id}', [ProposalController::class, 'show']);
        Route::put('/{id}', [ProposalController::class, 'update']);
        Route::delete('/{id}', [ProposalController::class, 'destroy']);
        Route::post('/{id}/convert-to-invoice', [ProposalController::class, 'convertToInvoice']);
        
        // Item management for proposals
        Route::get('/items/available', [ProposalController::class, 'getAvailableItems']);
        Route::get('/items/groups', [ProposalController::class, 'getItemGroups']);
        Route::get('/{id}/items', [ProposalController::class, 'getItems']);
        Route::post('/{id}/items', [ProposalController::class, 'addItem']);
        Route::put('/{proposalId}/items/{itemId}', [ProposalController::class, 'updateItem']);
        Route::delete('/{proposalId}/items/{itemId}', [ProposalController::class, 'deleteItem']);
    });

    // Estimates Management
    Route::prefix('estimates')->group(function () {
        Route::get('/', [EstimateController::class, 'index']);
        Route::post('/', [EstimateController::class, 'store']);
        Route::get('/statuses', [EstimateController::class, 'getStatuses']);
        Route::get('/statistics', [EstimateController::class, 'getStatistics']);
        Route::get('/{id}', [EstimateController::class, 'show']);
        Route::put('/{id}', [EstimateController::class, 'update']);
        Route::delete('/{id}', [EstimateController::class, 'destroy']);
        Route::post('/{id}/convert-to-invoice', [EstimateController::class, 'convertToInvoice']);
        Route::post('/{id}/approve', [EstimateController::class, 'approve']);
        Route::post('/{id}/reject', [EstimateController::class, 'reject']);
        
        // Item management for estimates
        Route::get('/items/available', [EstimateController::class, 'getAvailableItems']);
        Route::get('/items/groups', [EstimateController::class, 'getItemGroups']);
        Route::get('/{id}/items', [EstimateController::class, 'getItems']);
        Route::post('/{id}/items', [EstimateController::class, 'addItem']);
        Route::put('/{estimateId}/items/{itemId}', [EstimateController::class, 'updateItem']);
        Route::delete('/{estimateId}/items/{itemId}', [EstimateController::class, 'deleteItem']);
    });

    // Estimate Requests Management
    Route::prefix('estimate-requests')->group(function () {
        Route::get('/', [EstimateRequestController::class, 'index']);
        Route::post('/', [EstimateRequestController::class, 'store']);
        Route::get('/form-data', [EstimateRequestController::class, 'getFormData']);
        Route::get('/statistics', [EstimateRequestController::class, 'getStatistics']);
        Route::get('/settings', [EstimateRequestController::class, 'getRequestSettings']);
        Route::get('/check-daily-limit', [EstimateRequestController::class, 'checkDailyLimit']);
        Route::get('/{id}', [EstimateRequestController::class, 'show']);
        Route::put('/{id}', [EstimateRequestController::class, 'update']);
        Route::delete('/{id}', [EstimateRequestController::class, 'destroy']);
        Route::post('/{id}/assign-estimate', [EstimateRequestController::class, 'assignEstimate']);
        Route::post('/{id}/assign-staff', [EstimateRequestController::class, 'assignStaff']);
        Route::post('/{id}/change-status', [EstimateRequestController::class, 'changeStatus']);
    });

    // Tickets Management
    Route::prefix('tickets')->group(function () {
        Route::get('/', [TicketController::class, 'index']);
        Route::post('/', [TicketController::class, 'store']);
        Route::get('/form-data', [TicketController::class, 'getFormData']);
        Route::get('/categories', [TicketController::class, 'getCategories']);
        Route::get('/staff-members', [TicketController::class, 'getStaffMembers']);
        Route::get('/clients', [TicketController::class, 'getClients']);
        Route::get('/statistics', [TicketController::class, 'getStatistics']);
        Route::get('/{id}', [TicketController::class, 'show']);
        Route::put('/{id}', [TicketController::class, 'update']);
        Route::delete('/{id}', [TicketController::class, 'destroy']);
        Route::post('/{id}/assign-staff', [TicketController::class, 'assignStaff']);
        Route::post('/{id}/remove-staff', [TicketController::class, 'removeStaff']);
        Route::post('/{id}/reply', [TicketController::class, 'reply']);
    });

    // Todos Management
    Route::prefix('todos')->group(function () {
        Route::get('/', [TodoController::class, 'index']);
        Route::post('/', [TodoController::class, 'store']);
        Route::get('/priorities', [TodoController::class, 'getPriorities']);
        Route::get('/statistics', [TodoController::class, 'getStatistics']);
        Route::get('/{id}', [TodoController::class, 'show']);
        Route::put('/{id}', [TodoController::class, 'update']);
        Route::delete('/{id}', [TodoController::class, 'destroy']);
        Route::post('/{id}/mark-completed', [TodoController::class, 'markCompleted']);
        Route::post('/{id}/mark-incomplete', [TodoController::class, 'markIncomplete']);
        Route::post('/reorder', [TodoController::class, 'reorder']);
    });

    // Timesheets Management
    Route::prefix('timesheets')->group(function () {
        Route::get('/', [TimesheetController::class, 'index']);
        Route::post('/', [TimesheetController::class, 'store']);
        Route::get('/statuses', [TimesheetController::class, 'getStatuses']);
        Route::get('/staff-members', [TimesheetController::class, 'getStaffMembers']);
        Route::get('/statistics', [TimesheetController::class, 'getStatistics']);
        Route::get('/active', [TimesheetController::class, 'getActive']);
        Route::get('/{id}', [TimesheetController::class, 'show']);
        Route::put('/{id}', [TimesheetController::class, 'update']);
        Route::delete('/{id}', [TimesheetController::class, 'destroy']);
        Route::post('/start', [TimesheetController::class, 'start']);
        Route::post('/{id}/stop', [TimesheetController::class, 'stop']);
    });

    // Notes Management
    Route::prefix('notes')->group(function () {
        Route::get('/', [NoteController::class, 'index']);
        Route::post('/', [NoteController::class, 'store']);
        Route::get('/model-types', [NoteController::class, 'getModelTypes']);
        Route::get('/staff-members', [NoteController::class, 'getStaffMembers']);
        Route::get('/statistics', [NoteController::class, 'getStatistics']);
        Route::get('/{id}', [NoteController::class, 'show']);
        Route::put('/{id}', [NoteController::class, 'update']);
        Route::delete('/{id}', [NoteController::class, 'destroy']);
        Route::get('/model/{modelType}/{modelId}', [NoteController::class, 'getModelNotes']);
    });

    // Comments Management
    Route::prefix('comments')->group(function () {
        Route::get('/', [CommentController::class, 'index']);
        Route::post('/', [CommentController::class, 'store']);
        Route::get('/model-types', [CommentController::class, 'getModelTypes']);
        Route::get('/statuses', [CommentController::class, 'getStatuses']);
        Route::get('/staff-members', [CommentController::class, 'getStaffMembers']);
        Route::get('/statistics', [CommentController::class, 'getStatistics']);
        Route::get('/{id}', [CommentController::class, 'show']);
        Route::put('/{id}', [CommentController::class, 'update']);
        Route::delete('/{id}', [CommentController::class, 'destroy']);
        Route::get('/model/{modelType}/{modelId}', [CommentController::class, 'getModelComments']);
    });

    // Goals Management
    Route::prefix('goals')->group(function () {
        Route::get('/', [GoalController::class, 'index']);
        Route::post('/', [GoalController::class, 'store']);
        Route::get('/statuses', [GoalController::class, 'getStatuses']);
        Route::get('/statistics', [GoalController::class, 'getStatistics']);
        Route::get('/staff-members', [GoalController::class, 'getStaffMembers']);
        Route::get('/{id}', [GoalController::class, 'show']);
        Route::put('/{id}', [GoalController::class, 'update']);
        Route::delete('/{id}', [GoalController::class, 'destroy']);
        Route::post('/{id}/mark-completed', [GoalController::class, 'markCompleted']);
        Route::post('/{id}/reopen', [GoalController::class, 'reopen']);
        Route::post('/{id}/archive', [GoalController::class, 'archive']);
    });

    // Reminders Management
    Route::prefix('reminders')->group(function () {
        Route::get('/', [ReminderController::class, 'index']);
        Route::post('/', [ReminderController::class, 'store']);
        Route::get('/model-types', [ReminderController::class, 'getModelTypes']);
        Route::get('/staff-members', [ReminderController::class, 'getStaffMembers']);
        Route::get('/statistics', [ReminderController::class, 'getStatistics']);
        Route::get('/{id}', [ReminderController::class, 'show']);
        Route::put('/{id}', [ReminderController::class, 'update']);
        Route::delete('/{id}', [ReminderController::class, 'destroy']);
        Route::post('/{id}/mark-notified', [ReminderController::class, 'markNotified']);
        Route::post('/{id}/snooze', [ReminderController::class, 'snooze']);
        Route::get('/model/{modelType}/{modelId}', [ReminderController::class, 'getModelReminders']);
    });

    // Chat Management
    Route::prefix('chat')->group(function () {
        Route::get('/rooms', [ChatController::class, 'index']);
        Route::post('/rooms', [ChatController::class, 'store']);
        Route::get('/rooms/{id}', [ChatController::class, 'show']);
        Route::get('/rooms/{roomId}/messages', [ChatController::class, 'messages']);
        Route::post('/rooms/{roomId}/messages', [ChatController::class, 'sendMessage']);
        Route::post('/rooms/{roomId}/mark-read', [ChatController::class, 'markAsRead']);
        Route::get('/unread-count', [ChatController::class, 'getUnreadCount']);
        Route::get('/staff-members', [ChatController::class, 'getStaffMembers']);
    });

    // Email Accounts Management
    Route::prefix('email-accounts')->group(function () {
        Route::get('/', [EmailAccountController::class, 'index']);
        Route::post('/', [EmailAccountController::class, 'store']);
        Route::get('/form-data', [EmailAccountController::class, 'getFormData']);
        Route::get('/statistics', [EmailAccountController::class, 'getStatistics']);
        Route::get('/{id}', [EmailAccountController::class, 'show']);
        Route::put('/{id}', [EmailAccountController::class, 'update']);
        Route::delete('/{id}', [EmailAccountController::class, 'destroy']);
        Route::post('/{id}/test-connection', [EmailAccountController::class, 'testConnection']);
        Route::post('/{id}/sync', [EmailAccountController::class, 'syncEmails']);
        Route::post('/{id}/set-default', [EmailAccountController::class, 'setDefault']);
        Route::get('/{id}/folders', [EmailAccountController::class, 'getFolders']);
    });

    // Email Messages Management
    Route::prefix('email-messages')->group(function () {
        Route::get('/', [EmailMessageController::class, 'index']);
        Route::post('/', [EmailMessageController::class, 'store']);
        Route::get('/search', [EmailMessageController::class, 'search']);
        Route::get('/statistics', [EmailMessageController::class, 'getStatistics']);
        Route::get('/{id}', [EmailMessageController::class, 'show']);
        Route::put('/{id}', [EmailMessageController::class, 'update']);
        Route::delete('/{id}', [EmailMessageController::class, 'destroy']);
        Route::post('/{id}/mark-read', [EmailMessageController::class, 'markAsRead']);
        Route::post('/{id}/mark-unread', [EmailMessageController::class, 'markAsUnread']);
        Route::post('/{id}/star', [EmailMessageController::class, 'star']);
        Route::post('/{id}/unstar', [EmailMessageController::class, 'unstar']);
        Route::post('/{id}/archive', [EmailMessageController::class, 'archive']);
        Route::post('/{id}/unarchive', [EmailMessageController::class, 'unarchive']);
        Route::post('/{id}/move-to-folder', [EmailMessageController::class, 'moveToFolder']);
        Route::post('/{id}/reply', [EmailMessageController::class, 'reply']);
        Route::post('/{id}/reply-all', [EmailMessageController::class, 'replyAll']);
        Route::post('/{id}/forward', [EmailMessageController::class, 'forward']);
        Route::get('/{id}/thread', [EmailMessageController::class, 'getThread']);
        Route::post('/send', [EmailMessageController::class, 'sendEmail']);
        Route::post('/bulk-actions', [EmailMessageController::class, 'bulkActions']);
    });

    // Email Attachments Management
    Route::prefix('email-attachments')->group(function () {
        Route::post('/upload', [EmailAttachmentController::class, 'upload']);
        Route::get('/statistics', [EmailAttachmentController::class, 'getStatistics']);
        Route::get('/messages/{messageId}', [EmailAttachmentController::class, 'index']);
        Route::get('/messages/{messageId}/attachments/{attachmentId}', [EmailAttachmentController::class, 'show']);
        Route::get('/messages/{messageId}/attachments/{attachmentId}/download', [EmailAttachmentController::class, 'download'])->name('mobile-api.email-attachments.download');
        Route::get('/messages/{messageId}/attachments/{attachmentId}/preview', [EmailAttachmentController::class, 'preview'])->name('mobile-api.email-attachments.preview');
        Route::delete('/messages/{messageId}/attachments/{attachmentId}', [EmailAttachmentController::class, 'destroy']);
    });

    // Email Signatures Management
    Route::prefix('email-signatures')->group(function () {
        Route::get('/', [EmailSignatureController::class, 'index']);
        Route::post('/', [EmailSignatureController::class, 'store']);
        Route::get('/templates', [EmailSignatureController::class, 'getTemplates']);
        Route::get('/placeholders', [EmailSignatureController::class, 'getPlaceholders']);
        Route::get('/default', [EmailSignatureController::class, 'getDefault']);
        Route::get('/{id}', [EmailSignatureController::class, 'show']);
        Route::put('/{id}', [EmailSignatureController::class, 'update']);
        Route::delete('/{id}', [EmailSignatureController::class, 'destroy']);
        Route::post('/{id}/set-default', [EmailSignatureController::class, 'setDefault']);
        Route::post('/{id}/duplicate', [EmailSignatureController::class, 'duplicate']);
        Route::get('/{id}/preview', [EmailSignatureController::class, 'preview']);
    });

    // Common endpoints
    Route::prefix('common')->group(function () {
        Route::get('/business-info', function () {
            $staff = request()->user();
            return response()->json([
                'success' => true,
                'data' => [
                    'business' => [
                        'id' => $staff->business_id,
                        'name' => $staff->business->name ?? null,
                        'logo' => $staff->business->logo ?? null,
                        'address' => $staff->business->address ?? null,
                        'phone' => $staff->business->phone ?? null,
                        'email' => $staff->business->email ?? null,
                        'website' => $staff->business->website ?? null,
                    ]
                ]
            ]);
        });

        Route::get('/app-settings', function () {
            return response()->json([
                'success' => true,
                'data' => [
                    'app_version' => config('app.version', '1.0.0'),
                    'api_version' => 'v1',
                    'features' => [
                        'leads_management' => true,
                        'tasks_management' => true,
                        'clients_management' => true,
                        'meetings_management' => true,
                        'deals_management' => true,
                        'proposals_management' => true,
                        'estimates_management' => true,
                        'estimate_requests_management' => true,
                        'tickets_management' => true,
                        'todos_management' => true,
                        'timesheets_management' => true,
                        'time_tracking' => true,
                        'notes_management' => true,
                        'comments_management' => true,
                        'goals_management' => true,
                        'reminders_management' => true,
                        'email_management' => true,
                        'email_accounts' => true,
                        'email_messages' => true,
                        'email_attachments' => true,
                        'email_signatures' => true,
                        'email_sending' => true,
                        'collaboration' => true,
                        'notifications' => true,
                        'dashboard_analytics' => true,
                    ],
                    'limits' => [
                        'max_file_upload_size' => 10 * 1024 * 1024, // 10MB
                        'pagination_per_page' => 20,
                        'max_search_results' => 100,
                    ]
                ]
            ]);
        });
    });

});

// Health check endpoint
Route::get('/mobile/health', function () {
    return response()->json([
        'success' => true,
        'message' => 'MediansCRM Mobile API is running',
        'timestamp' => now()->toISOString(),
        'version' => 'v1.0.0'
    ]);
});
