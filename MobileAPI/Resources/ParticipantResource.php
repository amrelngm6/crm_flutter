<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ParticipantResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'room_id' => $this->room_id,
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
            'is_moderator' => $this->is_moderator,
            'joined_at' => $this->created_at,
        ];
    }
}
