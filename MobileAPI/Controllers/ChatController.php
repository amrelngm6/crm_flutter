<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Chat\Models\ChatRoom;
use App\Modules\Chat\Models\Message;
use App\Modules\Chat\Models\Participant;
use App\Modules\Chat\Services\RoomService;
use App\Modules\Chat\Services\MessageService;
use App\Modules\Chat\Services\ParticipantService;
use App\Modules\MobileAPI\Requests\ChatRoomRequest;
use App\Modules\MobileAPI\Requests\ChatMessageRequest;
use App\Modules\MobileAPI\Resources\ChatRoomResource;
use App\Modules\MobileAPI\Resources\MessageResource;
use App\Modules\MobileAPI\Resources\ParticipantResource;
use App\Modules\Customers\Models\Staff;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    protected $roomService;
    protected $messageService;
    protected $participantService;

    public function __construct(
        RoomService $roomService,
        MessageService $messageService,
        ParticipantService $participantService
    ) {
        $this->roomService = $roomService;
        $this->messageService = $messageService;
        $this->participantService = $participantService;
    }

    /**
     * Get paginated chat rooms list for the authenticated user
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $query = ChatRoom::where('business_id', $businessId)
                            ->whereHas('participants', function($q) use ($staff) {
                                $q->where('user_id', $staff->staff_id)
                                  ->where('user_type', Staff::class);
                            })
                            ->with(['participants.user', 'messages' => function($q) {
                                $q->latest()->limit(1);
                            }]);

            // Search functionality
            if ($search = $request->get('search')) {
                $query->where('name', 'like', "%{$search}%");
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'updated_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $rooms = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => [
                    'rooms' => ChatRoomResource::collection($rooms->items()),
                    'pagination' => [
                        'current_page' => $rooms->currentPage(),
                        'last_page' => $rooms->lastPage(),
                        'per_page' => $rooms->perPage(),
                        'total' => $rooms->total(),
                        'from' => $rooms->firstItem(),
                        'to' => $rooms->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch chat rooms',
                'errors' => ['server' => ['An error occurred while fetching chat rooms: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single chat room details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $room = ChatRoom::where('business_id', $businessId)
                           ->whereHas('participants', function($q) use ($staff) {
                               $q->where('user_id', $staff->staff_id)
                                 ->where('user_type', Staff::class);
                           })
                           ->with(['participants.user', 'messages.user'])
                           ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new ChatRoomResource($room)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Chat room not found',
                'errors' => ['room' => ['Chat room not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch chat room',
                'errors' => ['server' => ['An error occurred while fetching chat room: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get messages for a specific room
     */
    public function messages(Request $request, int $roomId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Verify user has access to the room
            $room = ChatRoom::where('business_id', $businessId)
                           ->whereHas('participants', function($q) use ($staff) {
                               $q->where('user_id', $staff->staff_id)
                                 ->where('user_type', Staff::class);
                           })
                           ->findOrFail($roomId);

            $perPage = $request->get('per_page', 50);
            $page = $request->get('page', 1);

            $messages = Message::where('room_id', $roomId)
                              ->with(['user', 'files'])
                              ->orderBy('created_at', 'desc')
                              ->paginate($perPage);

            // Reverse the order for display (newest at bottom)
            $messagesArray = array_reverse($messages->items());

            return response()->json([
                'success' => true,
                'data' => [
                    'messages' => MessageResource::collection($messagesArray),
                    'room' => [
                        'id' => $room->id,
                        'name' => $room->name,
                    ],
                    'pagination' => [
                        'current_page' => $messages->currentPage(),
                        'last_page' => $messages->lastPage(),
                        'per_page' => $messages->perPage(),
                        'total' => $messages->total(),
                        'has_more' => $messages->hasMorePages(),
                    ]
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Chat room not found',
                'errors' => ['room' => ['Chat room not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch messages',
                'errors' => ['server' => ['An error occurred while fetching messages: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Send a message to a room
     */
    public function sendMessage(ChatMessageRequest $request, int $roomId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Verify user has access to the room
            $room = ChatRoom::where('business_id', $businessId)
                           ->whereHas('participants', function($q) use ($staff) {
                               $q->where('user_id', $staff->staff_id)
                                 ->where('user_type', Staff::class);
                           })
                           ->findOrFail($roomId);

            $message = Message::create([
                'business_id' => $businessId,
                'room_id' => $roomId,
                'message' => $request->input('message'),
                'type' => $request->input('type', 'text'),
                'user_id' => $staff->staff_id,
                'user_type' => Staff::class,
                'sent_at' => now(),
            ]);

            $message->load('user');

            return response()->json([
                'success' => true,
                'message' => 'Message sent successfully',
                'data' => new MessageResource($message)
            ], 201);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Chat room not found',
                'errors' => ['room' => ['Chat room not found']]
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
                'message' => 'Failed to send message',
                'errors' => ['server' => ['An error occurred while sending message: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Mark messages as read in a room
     */
    public function markAsRead(Request $request, int $roomId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Verify user has access to the room
            $room = ChatRoom::where('business_id', $businessId)
                           ->whereHas('participants', function($q) use ($staff) {
                               $q->where('user_id', $staff->staff_id)
                                 ->where('user_type', Staff::class);
                           })
                           ->findOrFail($roomId);

            // Mark all messages in room as seen for this user (except their own messages)
            $updatedCount = Message::where('room_id', $roomId)
                                  ->where(function($q) use ($staff) {
                                      $q->where('user_id', '!=', $staff->staff_id)
                                        ->orWhere('user_type', '!=', Staff::class);
                                  })
                                  ->whereNull('seen_at')
                                  ->update(['seen_at' => now()]);

            return response()->json([
                'success' => true,
                'message' => 'Messages marked as read',
                'data' => [
                    'updated_count' => $updatedCount,
                    'room_id' => $roomId,
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Chat room not found',
                'errors' => ['room' => ['Chat room not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to mark messages as read',
                'errors' => ['server' => ['An error occurred while marking messages as read: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get unread messages count across all rooms
     */
    public function getUnreadCount(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $unreadCount = Message::whereHas('room', function($q) use ($businessId, $staff) {
                                $q->where('business_id', $businessId)
                                  ->whereHas('participants', function($sq) use ($staff) {
                                      $sq->where('user_id', $staff->staff_id)
                                         ->where('user_type', Staff::class);
                                  });
                            })
                            ->where(function($q) use ($staff) {
                                $q->where('user_id', '!=', $staff->staff_id)
                                  ->orWhere('user_type', '!=', Staff::class);
                            })
                            ->whereNull('seen_at')
                            ->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'unread_count' => $unreadCount
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch unread count',
                'errors' => ['server' => ['An error occurred while fetching unread count: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create a new chat room
     */
    public function store(ChatRoomRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $room = ChatRoom::create([
                'business_id' => $businessId,
                'name' => $request->input('name'),
                'created_by' => $staff->staff_id,
            ]);

            // Add creator as participant and moderator
            Participant::create([
                'business_id' => $businessId,
                'room_id' => $room->id,
                'user_id' => $staff->staff_id,
                'user_type' => Staff::class,
                'is_moderator' => true,
            ]);

            // Add other participants
            foreach ($request->input('participants') as $participantId) {
                if ($participantId != $staff->staff_id) {
                    Participant::create([
                        'business_id' => $businessId,
                        'room_id' => $room->id,
                        'user_id' => $participantId,
                        'user_type' => Staff::class,
                        'is_moderator' => false,
                    ]);
                }
            }

            $room->load(['participants.user']);

            return response()->json([
                'success' => true,
                'message' => 'Chat room created successfully',
                'data' => new ChatRoomResource($room)
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
                'message' => 'Failed to create chat room',
                'errors' => ['server' => ['An error occurred while creating chat room: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get staff members for chat participants
     */
    public function getStaffMembers(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $staffMembers = Staff::where('business_id', $businessId)
                                ->where('status', 1)
                                ->where('staff_id', '!=', $staff->staff_id) // Exclude current user
                                ->select('staff_id as id', 'first_name', 'last_name', 'email', 'picture')
                                ->orderBy('first_name')
                                ->get()
                                ->map(function ($member) {
                                    return [
                                        'id' => $member->id(),
                                        'name' => $member->name,
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
}
