<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MeetingResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'start_date' => $this->start_date,
            'end_date' => $this->end_date,
            'duration_minutes' => $this->start_date && $this->end_date 
                ? $this->start_date->diffInMinutes($this->end_date) 
                : null,
            'location' => $this->location,
            'meeting_url' => $this->meeting_url,
            'reminder_minutes' => $this->reminder_minutes,
            'is_recurring' => $this->is_recurring ?? false,
            'recurring_type' => $this->recurring_type,
            'recurring_end_date' => $this->recurring_end_date,
            'status' => [
                'id' => $this->status->status_id,
                'name' => $this->status->name ?? '',
                'color' => $this->getStatusColor(),
            ],
            'client' => [
                'id' => $this->client_id,
                'name' => $this->client->name ?? null,
                'email' => $this->client->email ?? null,
                'company' => $this->client->company ?? null,
            ],
            'attendees' => $this->attendees->map(function($attendee) {
                return [
                    'id' => $attendee->user->staff_id ?? $attendee->user_id,
                    'name' => $attendee->user->name ?? 'Unknown',
                    'email' => $attendee->user->email ?? null,
                    'avatar' => $attendee->user->avatar() ?? null,
                ];
            }),
            'is_past' => $this->end_date ? $this->end_date < now() : false,
            'is_today' => $this->start_date ? $this->start_date->isToday() : false,
            'is_upcoming' => $this->start_date ? $this->start_date > now() : false,
            'time_until_meeting' => $this->start_date && $this->start_date > now() 
                ? now()->diffForHumans($this->start_date, true) 
                : null,
            'business_id' => $this->business_id,
            'created_by' => $this->created_by,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }

    /**
     * Get status color based on meeting status
     */
    private function getStatusColor(): string
    {
        return match(strtolower($this->status->name ?? '')) {
            'scheduled' => '#007bff',
            'in_progress' => '#28a745',
            'completed' => '#6c757d',
            'cancelled' => '#dc3545',
            'postponed' => '#ffc107',
            default => '#007bff'
        };
    }
}
