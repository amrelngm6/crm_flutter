<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Notifications\Models\Notification;
use App\Modules\Notifications\Services\NotificationService;
use App\Modules\MobileAPI\Resources\NotificationResource;
use App\Modules\Customers\Models\Staff;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class NotificationController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Get paginated notifications list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $query = Notification::forUser($staff->staff_id, Staff::class)
                                ->forBusiness($businessId)
                                ->with(['template'])
                                ->orderBy('created_at', 'desc');

            // Filter by read/unread status
            if ($request->has('unread_only') && $request->get('unread_only') == 'true') {
                $query->unread();
            }

            // Filter by type
            if ($type = $request->get('type')) {
                $query->where('type', $type);
            }

            // Filter by date range
            if ($startDate = $request->get('start_date')) {
                $query->whereDate('created_at', '>=', $startDate);
            }
            if ($endDate = $request->get('end_date')) {
                $query->whereDate('created_at', '<=', $endDate);
            }

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where(function($q) use ($search) {
                    $q->where('title', 'like', "%{$search}%")
                      ->orWhere('content', 'like', "%{$search}%");
                });
            }

            $notifications = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'notifications' => NotificationResource::collection($notifications->items()),
                    'pagination' => [
                        'current_page' => $notifications->currentPage(),
                        'last_page' => $notifications->lastPage(),
                        'per_page' => $notifications->perPage(),
                        'total' => $notifications->total(),
                        'from' => $notifications->firstItem(),
                        'to' => $notifications->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch notifications',
                'errors' => ['server' => ['An error occurred while fetching notifications: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single notification details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $notification = Notification::forUser($staff->staff_id, Staff::class)
                                       ->forBusiness($businessId)
                                       ->with(['template'])
                                       ->findOrFail($id);

            // Mark as read when viewed
            if (!$notification->is_read) {
                $notification->markAsRead();
            }

            return response()->json([
                'success' => true,
                'data' => new NotificationResource($notification)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Notification not found',
                'errors' => ['notification' => ['Notification not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch notification',
                'errors' => ['server' => ['An error occurred while fetching notification: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Mark notification as read
     */
    public function markAsRead(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $notification = Notification::forUser($staff->staff_id, Staff::class)
                                       ->forBusiness($businessId)
                                       ->findOrFail($id);

            $notification->markAsRead();

            return response()->json([
                'success' => true,
                'message' => 'Notification marked as read',
                'data' => new NotificationResource($notification)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Notification not found',
                'errors' => ['notification' => ['Notification not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to mark notification as read',
                'errors' => ['server' => ['An error occurred while updating notification: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Mark all notifications as read
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $updatedCount = Notification::forUser($staff->staff_id, Staff::class)
                                       ->forBusiness($businessId)
                                       ->unread()
                                       ->update([
                                           'is_read' => true,
                                           'read_at' => now(),
                                       ]);

            return response()->json([
                'success' => true,
                'message' => 'All notifications marked as read',
                'data' => [
                    'updated_count' => $updatedCount
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to mark all notifications as read',
                'errors' => ['server' => ['An error occurred while updating notifications: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete notification
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $notification = Notification::forUser($staff->staff_id, Staff::class)
                                       ->forBusiness($businessId)
                                       ->findOrFail($id);

            $notification->delete();

            return response()->json([
                'success' => true,
                'message' => 'Notification deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Notification not found',
                'errors' => ['notification' => ['Notification not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete notification',
                'errors' => ['server' => ['An error occurred while deleting notification: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete multiple notifications
     */
    public function bulkDestroy(Request $request): JsonResponse
    {
        try {
            $request->validate([
                'notification_ids' => 'required|array',
                'notification_ids.*' => 'integer|exists:notifications,id',
            ]);

            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $deletedCount = Notification::forUser($staff->staff_id, Staff::class)
                                       ->forBusiness($businessId)
                                       ->whereIn('id', $request->notification_ids)
                                       ->delete();

            return response()->json([
                'success' => true,
                'message' => 'Notifications deleted successfully',
                'data' => [
                    'deleted_count' => $deletedCount
                ]
            ]);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete notifications',
                'errors' => ['server' => ['An error occurred while deleting notifications: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get unread notifications count
     */
    public function getUnreadCount(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;
            
            $count = Notification::forUser($staff->staff_id, Staff::class)
                                ->forBusiness($businessId)
                                ->unread()
                                ->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'unread_count' => $count
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to get unread count',
                'errors' => ['server' => ['An error occurred while counting notifications: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get notification statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Base query for user's notifications
            $baseQuery = Notification::forUser($staff->staff_id, Staff::class)
                                    ->forBusiness($businessId);

            // Overview statistics
            $totalNotifications = (clone $baseQuery)->count();
            $unreadNotifications = (clone $baseQuery)->unread()->count();
            $readNotifications = $totalNotifications - $unreadNotifications;

            // Today's notifications
            $todayNotifications = (clone $baseQuery)
                                ->whereDate('created_at', today())
                                ->count();

            $todayUnread = (clone $baseQuery)
                         ->whereDate('created_at', today())
                         ->unread()
                         ->count();

            // This week's notifications
            $thisWeekNotifications = (clone $baseQuery)
                                   ->whereBetween('created_at', [
                                       now()->startOfWeek(),
                                       now()->endOfWeek()
                                   ])
                                   ->count();

            // Type breakdown
            $typeBreakdown = (clone $baseQuery)
                           ->selectRaw('type, COUNT(*) as count, SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread_count')
                           ->groupBy('type')
                           ->get();

            // Daily trends (last 30 days)
            $dailyTrends = (clone $baseQuery)
                         ->selectRaw('DATE(created_at) as date, COUNT(*) as count, SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread_count')
                         ->where('created_at', '>=', now()->subDays(30))
                         ->groupBy('date')
                         ->orderBy('date')
                         ->get();

            // Recent activity (last 7 days)
            $recentActivity = [
                'new_notifications' => (clone $baseQuery)->where('created_at', '>=', now()->subDays(7))->count(),
                'read_notifications' => (clone $baseQuery)->where('read_at', '>=', now()->subDays(7))->count(),
                'avg_read_time' => (clone $baseQuery)
                                 ->whereNotNull('read_at')
                                 ->where('read_at', '>=', now()->subDays(7))
                                 ->selectRaw('AVG(TIMESTAMPDIFF(MINUTE, created_at, read_at)) as avg_minutes')
                                 ->value('avg_minutes'),
            ];

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_notifications' => $totalNotifications,
                        'unread_notifications' => $unreadNotifications,
                        'read_notifications' => $readNotifications,
                        'today_notifications' => $todayNotifications,
                        'today_unread' => $todayUnread,
                        'this_week_notifications' => $thisWeekNotifications,
                        'read_rate' => $totalNotifications > 0 ? round(($readNotifications / $totalNotifications) * 100, 2) : 0,
                    ],
                    'type_breakdown' => $typeBreakdown,
                    'recent_activity' => [
                        'new_notifications' => $recentActivity['new_notifications'],
                        'read_notifications' => $recentActivity['read_notifications'],
                        'avg_read_time_minutes' => round($recentActivity['avg_read_time'] ?? 0, 1),
                    ],
                    'daily_trends' => $dailyTrends,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch notification statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }
}
