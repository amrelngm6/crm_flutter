<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Modules\Customers\Models\Staff;

class TodoResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'description' => $this->description,
            'date' => $this->date,
            'sort' => $this->sort,
            'is_completed' => $this->status_id == 1,
            'status_id' => $this->status_id,
            'finished_time' => $this->finished_time,
            'completion_status' => [
                'is_completed' => $this->status_id == 1,
                'completed_at' => $this->finished_time,
                'status_text' => $this->status_id == 1 ? 'Completed' : 'Pending',
            ],
            'date_info' => [
                'date' => $this->date,
                'is_today' => $this->date ? $this->date == today()->format('Y-m-d') : false,
                'is_overdue' => $this->date && $this->status_id != 1 ? $this->date < today()->format('Y-m-d') : false,
                'is_this_week' => $this->date ? 
                    ($this->date >= now()->startOfWeek()->format('Y-m-d') && 
                     $this->date <= now()->endOfWeek()->format('Y-m-d')) : false,
                'days_until_due' => $this->date ? 
                    (strtotime($this->date) - strtotime(today()->format('Y-m-d'))) / (60 * 60 * 24) : null,
                'formatted_date' => $this->date ? date('M j, Y', strtotime($this->date)) : null,
            ],
            'priority' => $this->when($this->priority, [
                'id' => $this->priority->priority_id ?? null,
                'name' => $this->priority->name ?? 'Normal',
                'color' => $this->priority->color ?? '#6c757d',
                'level' => $this->priority->level ?? 1,
                'sort' => $this->priority->sort ?? 0,
            ]),
            'user' => [
                'id' => $this->user_id,
                'type' => $this->user_type,
                'name' => $this->getUserName(),
                'details' => $this->when($this->user, [
                    'name' => $this->user->name ?? null,
                    'first_name' => $this->user->first_name ?? null,
                    'last_name' => $this->user->last_name ?? null,
                    'email' => $this->user->email ?? null,
                    'avatar' => $this->user ? $this->user->avatar() : null,
                ]),
            ],
            'business_id' => $this->business_id,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }

    /**
     * Get user name for display
     */
    private function getUserName(): string
    {
        if (!$this->user_type || !$this->user_id) {
            return 'Unknown User';
        }

        try {
            $userClass = $this->user_type;
            
            if (class_exists($userClass)) {
                $user = $userClass::find($this->user_id);
                
                if ($user) {
                    // Try different name patterns
                    if (method_exists($user, 'getName')) {
                        return $user->getName();
                    } elseif (isset($user->name)) {
                        return $user->name;
                    } elseif (isset($user->first_name)) {
                        return $user->first_name . ' ' . ($user->last_name ?? '');
                    }
                }
            }
        } catch (\Exception $e) {
            // Silently handle any exceptions
        }

        return 'Unknown User';
    }
}
