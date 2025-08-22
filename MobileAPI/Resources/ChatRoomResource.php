<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChatRoomResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        $lastMessage = $this->messages()->latest()->first();
        $unreadCount = $this->messages()
            ->whereNull('seen_at')
            ->where(function($q) use ($request) {
                $staff = $request->user();
                $q->where('user_id', '!=', $staff->staff_id)
                  ->orWhere('user_type', '!=', get_class($staff));
            })
            ->count();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'business_id' => $this->business_id,
            'created_by' => $this->created_by,
            'has_video_meeting' => $this->has_video_meeting,
            'meeting_id' => $this->meeting_id,
            'last_message' => $lastMessage ? new MessageResource($lastMessage) : null,
            'unread_count' => $unreadCount,
            'participants' => $this->whenLoaded('participants', function() {
                return ParticipantResource::collection($this->participants);
            }),
            'participants_count' => $this->participants()->count(),
            'is_moderator' => $this->when($request->user(), function() use ($request) {
                $staff = $request->user();
                return $this->participants()
                    ->where('user_id', $staff->staff_id)
                    ->where('user_type', get_class($staff))
                    ->where('is_moderator', true)
                    ->exists();
            }),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
