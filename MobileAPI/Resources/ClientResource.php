<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ClientResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id(),
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'company' => $this->company,
            'position' => $this->position,
            'address' => $this->address,
            'city' => $this->location_info->city ?? '',
            'state' => $this->location_info->state ?? '',
            'country' => $this->location_info->country ?? '',
            'postal_code' => $this->location_info->postal_code ?? '',
            'website' => $this->website,
            'notes' => $this->notes,
            'avatar' => $this->avatar(),
            'status' => $this->status,
            'business_id' => $this->business_id,
            'created_by' => $this->created_by,
            'projects'=> $this->projects,
            'invoices'=> $this->invoices,
            'projects_count' => $this->whenLoaded('projects', function() {
                return $this->projects->count();
            }),
            'invoices_count' => $this->whenLoaded('invoices', function() {
                return $this->invoices->count();
            }),
            'total_invoiced' => $this->whenLoaded('invoices', function() {
                return $this->invoices->sum('total');
            }),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
