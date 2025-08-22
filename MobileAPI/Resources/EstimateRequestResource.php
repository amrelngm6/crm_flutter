<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Resources\Json\JsonResource;
use App\Modules\Customers\Models\Staff;
use App\Modules\Customers\Models\Client;

class EstimateRequestResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'message' => $this->message,
            'date' => $this->date,
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString(),
            
            // User information (who created the request)
            'user' => [
                'id' => $this->user_id,
                'type' => class_basename($this->user_type),
                'name' => $this->getUserName(),
                'email' => $this->getUserEmail(),
                'avatar' => $this->getUserAvatar(),
            ],
            
            // Status information
            'status' => [
                'id' => $this->status_id,
                'name' => $this->status->name ?? 'Unknown',
                'color' => $this->status->color ?? '#6c757d',
            ],
            
            // Assigned staff information
            'assigned_staff' => $this->when($this->assigned_to, function() {
                return [
                    'id' => $this->assignedStaff->id() ?? null,
                    'name' => $this->assignedStaff->name ?? null,
                    'email' => $this->assignedStaff->email ?? null,
                    'avatar' => $this->assignedStaff->avatar() ?? '/data/images/default-avatar.png',
                ];
            }),
            
            // Associated estimate information
            'estimate' => $this->when($this->estimate_id, function() {
                return [
                    'id' => $this->estimate->id ?? null,
                    'title' => $this->estimate->title ?? null,
                    'estimate_number' => $this->estimate->estimate_number ?? null,
                    'total' => $this->estimate->total ?? 0,
                    'status' => [
                        'id' => $this->estimate->status_id ?? null,
                        'name' => $this->estimate->status->name ?? null,
                        'color' => $this->estimate->status->color ?? '#6c757d',
                    ],
                    'date' => $this->estimate->date ?? null,
                    'expiry_date' => $this->estimate->expiry_date ?? null,
                ];
            }),
            
            // Meta information
            'has_estimate' => !is_null($this->estimate_id),
            'is_assigned' => !is_null($this->assigned_to),
            'days_since_created' => $this->created_at->diffInDays(now()),
            'is_overdue' => $this->isOverdue(),
        ];
    }

    /**
     * Get the user name based on user type
     */
    protected function getUserName()
    {
        if ($this->user_type === Staff::class) {
            $staff = Staff::find($this->user_id);
            return $staff ? $staff->name : 'Unknown Staff';
        } elseif ($this->user_type === Client::class) {
            $client = Client::find($this->user_id);
            return $client ? $client->name : 'Unknown Client';
        }
        
        return 'Unknown User';
    }

    /**
     * Get the user email based on user type
     */
    protected function getUserEmail()
    {
        if ($this->user_type === Staff::class) {
            $staff = Staff::find($this->user_id);
            return $staff ? $staff->email : null;
        } elseif ($this->user_type === Client::class) {
            $client = Client::find($this->user_id);
            return $client ? $client->email : null;
        }
        
        return null;
    }

    /**
     * Get the user avatar based on user type
     */
    protected function getUserAvatar()
    {
        if ($this->user_type === Staff::class) {
            $staff = Staff::find($this->user_id);
            return $staff ? $staff->avatar() : '/data/images/default-avatar.png';
        } elseif ($this->user_type === Client::class) {
            $client = Client::find($this->user_id);
            return $client ? $client->avatar() : '/data/images/default-avatar.png';
        }
        
        return '/data/images/default-avatar.png';
    }

    /**
     * Check if the request is overdue (no response within expected time)
     */
    protected function isOverdue()
    {
        // If estimate is already assigned, it's not overdue
        if ($this->estimate_id) {
            return false;
        }

        // Check if status indicates completion
        $completedStatuses = ['Completed', 'Closed', 'Resolved'];
        if (in_array($this->status->name ?? '', $completedStatuses)) {
            return false;
        }

        // Get auto response time from settings (default 24 hours)
        $autoResponseHours = 24; // Default fallback
        try {
            $autoResponseHours = \App\Modules\Estimates\Helpers\EstimateSettingsHelper::getRequestAutoResponseTime() ?? 24;
        } catch (\Exception $e) {
            // Use default if settings helper fails
        }

        return $this->created_at->addHours($autoResponseHours)->isPast();
    }
}
