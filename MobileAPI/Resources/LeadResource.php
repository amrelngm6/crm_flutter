<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LeadResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id(),
            'web_visits' => $this->webpageVisits,
            'form_submissions' => $this->formSubmissions,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'company' => $this->company,
            'position' => $this->position,
            'address' => $this->address,
            'city' => $this->city,
            'state' => $this->state,
            'country' => $this->country,
            'postal_code' => $this->postal_code,
            'website' => $this->website,
            'budget' => $this->budget,
            'expected_close_date' => $this->expected_close_date,
            'notes' => $this->notes,
            'status' => [
                'id' => $this->status_id,
                'name' => $this->status->name ?? ucfirst('Pending'),
                'color' => $this->status->color ?? '#6c757d',
            ],
            'source' => [
                'id' => $this->source_id,
                'name' => $this->source->name ?? null,
                'color' => $this->source->color ?? '#6c757d',
            ],
            'assignee' => [
                'id' => $this->assigned_to,
                'name' => $this->assignedTo->name ?? null,
                'avatar' => $this->assignedTo ? $this->assignedTo->avatar() : null,
            ],
            'business_id' => $this->business_id,
            'created_by' => $this->created_by,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
