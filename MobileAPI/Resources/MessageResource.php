<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'room_id' => $this->room_id,
            'message' => $this->message,
            'type' => $this->type,
            'user' => [
                'id' => $this->user_id,
                'type' => $this->user_type,
                'name' => $this->whenLoaded('user', function() {
                    return method_exists($this->user, 'name') 
                        ? $this->user->name 
                        : ($this->user->first_name . ' ' . $this->user->last_name);
                }),
                'email' => $this->whenLoaded('user', function() {
                    return $this->user->email;
                }),
                'avatar' => $this->whenLoaded('user', function() {
                    return method_exists($this->user, 'avatar') ? $this->user->avatar() : null;
                }),
            ],
            'files' => $this->whenLoaded('files', function() {
                return $this->files->map(function($file) {
                    return [
                        'id' => $file->id,
                        'name' => $file->file_name,
                        'url' => $file->file_url,
                        'type' => $file->file_type,
                        'size' => $file->file_size,
                    ];
                });
            }),
            'is_own_message' => $this->when($request->user(), function() use ($request) {
                $staff = $request->user();
                return $this->user_id == $staff->staff_id && $this->user_type == get_class($staff);
            }),
            'timestamps' => [
                'sent_at' => $this->sent_at,
                'seen_at' => $this->seen_at,
                'created_at' => $this->created_at,
                'is_recent' => $this->created_at && $this->created_at->isAfter(now()->subHours(24)),
            ],
        ];
    }
}
