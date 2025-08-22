<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DealResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'code' => $this->code,
            'description' => $this->description,
            'amount' => [
                'value' => $this->amount,
                'currency_code' => $this->currency_code,
                'formatted' => $this->formatCurrency($this->amount, $this->currency_code),
            ],
            'probability' => $this->probability,
            'expected_due_date' => $this->expected_due_date,
            'status' => $this->status,
            'contact_info' => [
                'email' => $this->email,
                'phone' => $this->phone,
            ],
            'client' => $this->when($this->client, [
                'id' => $this->client->client_id ?? null,
                'name' => $this->client->name ?? null,
                'email' => $this->client->email ?? null,
                'phone' => $this->client->phone ?? null,
                'company_name' => $this->client->company_name ?? null,
                'avatar' => $this->client ?  $this->client->avatar() : null,
            ]),
            'lead' => $this->when($this->lead, [
                'id' => $this->lead->lead_id ?? null,
                'name' => $this->lead ? ($this->lead->first_name . ' ' . $this->lead->last_name) : null,
                'email' => $this->lead->email ?? null,
                'phone' => $this->lead->phone ?? null,
                'company_name' => $this->lead->company_name ?? null,
                'source' => $this->lead->source ?? null,
            ]),
            'stage' => $this->when($this->stage, [
                'id' => $this->stage->pipeline_stage_id ?? null,
                'name' => $this->stage->stage->name ?? null,
                'color' => $this->stage->stage->color ?? '#6c757d',
                'probability' => $this->stage->stage->probability ?? null,
                'pipeline' => [
                    'id' => $this->stage->pipeline_id ?? null,
                    'name' => $this->stage->pipeline->name ?? null,
                ]
            ]),
            'team' => $this->whenLoaded('team', function() {
                return $this->team->map(function($member) {
                    return [
                        'id' => $member->user_id,
                        'user_type' => $member->user_type,
                        'name' => $member->user->name ?? 'Unknown',
                        'email' => $member->user->email ?? null,
                        'avatar' => $member->user ? $member->user->avatar() : null,
                    ];
                });
            }),
            'author' => $this->when($this->author, [
                'id' => $this->author->staff_id ?? null,
                'name' => $this->author->name ?? 'Unknown',
                'email' => $this->author->email ?? null,
            ]),
            'tasks' => $this->whenLoaded('tasks', function() {
                return [
                    'count' => $this->tasks->count(),
                    'completed' => $this->tasks->where('finished_date', '!=', null)->count(),
                    'pending' => $this->tasks->where('finished_date', null)->count(),
                ];
            }),
            'location_info' => $this->when($this->location_info, [
                'address' => $this->location_info->address ?? null,
                'city' => $this->location_info->city ?? null,
                'state' => $this->location_info->state ?? null,
                'country' => $this->location_info->country ?? null,
                'postal_code' => $this->location_info->postal_code ?? null,
                'latitude' => $this->location_info->latitude ?? null,
                'longitude' => $this->location_info->longitude ?? null,
            ]),
            'digital_activity' => [
                'has_activity' => $this->hasDigitalActivity(),
                'recent_visits_count' => $this->recentVisits(30)->count(),
                'recent_submissions_count' => $this->recentFormSubmissions(30)->count(),
            ],
            'business_id' => $this->business_id,
            'created_by' => $this->created_by,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }

    /**
     * Format currency amount
     */
    private function formatCurrency($amount, $currencyCode): string
    {
        if (!$amount) return '0.00';
        
        $formattedAmount = number_format($amount, 2);
        
        return match(strtoupper($currencyCode)) {
            'USD' => '$' . $formattedAmount,
            'EUR' => '€' . $formattedAmount,
            'GBP' => '£' . $formattedAmount,
            'JPY' => '¥' . number_format($amount, 0),
            default => $currencyCode . ' ' . $formattedAmount
        };
    }
}
