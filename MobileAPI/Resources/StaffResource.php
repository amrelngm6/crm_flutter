<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StaffResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->staff_id,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'position' => $this->position,
            'about' => $this->about,
            'avatar' => $this->avatar(),
            'business_id' => $this->business_id,
            'role' => [
                'id' => $this->role_id,
                'name' => $this->role->name ?? null,
            ],
            'status' => [
                'id' => $this->status,
                'name' => $this->status_model->name ?? null,
            ],
            'permissions' => $this->getAllPermissions()->pluck('name'),
            'last_activity' => $this->last_activity,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
