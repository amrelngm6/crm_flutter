<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Resources\Json\JsonResource;
use Carbon\Carbon;

class TimesheetResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray($request): array
    {
        return [
            'id' => $this->timesheet_id,
            'business_id' => $this->business_id,
            'user' => [
                'id' => $this->user_id,
                'type' => $this->user_type,
                'name' => $this->whenLoaded('user', function () {
                    if ($this->user_type === 'App\Modules\Customers\Models\Staff') {
                        return $this->user->first_name . ' ' . $this->user->last_name;
                    }
                    return $this->user->name ?? 'Unknown User';
                }),
                'email' => $this->whenLoaded('user', function () {
                    return $this->user->email ?? null;
                }),
                'avatar' => $this->whenLoaded('user', function () {
                    if (method_exists($this->user, 'avatar')) {
                        return $this->user->avatar();
                    }
                    return null;
                }),
            ],
            'model' => [
                'id' => $this->model_id,
                'type' => $this->model_type,
                'display_name' => $this->whenLoaded('model', function () {
                    if (!$this->model) return null;
                    
                    // Different display names for different model types
                    switch ($this->model_type) {
                        case 'App\Modules\Tasks\Models\Task':
                            return $this->model->title ?? 'Task #' . $this->model_id;
                        case 'App\Modules\Projects\Models\Project':
                            return $this->model->title ?? 'Project #' . $this->model_id;
                        case 'App\Modules\Deals\Models\Deal':
                            return $this->model->title ?? 'Deal #' . $this->model_id;
                        case 'App\Modules\Tickets\Models\Ticket':
                            return $this->model->subject ?? 'Ticket #' . $this->model_id;
                        default:
                            return 'Item #' . $this->model_id;
                    }
                }),
                'reference' => $this->whenLoaded('model', function () {
                    if (!$this->model) return null;
                    
                    // Get reference number if available
                    if (isset($this->model->reference)) {
                        return $this->model->reference;
                    }
                    
                    return null;
                }),
            ],
            'timing' => [
                'start' => $this->start,
                'start_formatted' => $this->start ? Carbon::parse($this->start)->format('M j, Y g:i A') : null,
                'start_time' => $this->start ? Carbon::parse($this->start)->format('g:i A') : null,
                'start_date' => $this->start ? Carbon::parse($this->start)->format('M j, Y') : null,
                'end' => $this->end,
                'end_formatted' => $this->end ? Carbon::parse($this->end)->format('M j, Y g:i A') : null,
                'end_time' => $this->end ? Carbon::parse($this->end)->format('g:i A') : null,
                'end_date' => $this->end ? Carbon::parse($this->end)->format('M j, Y') : null,
                'duration' => $this->getDuration(),
                'duration_formatted' => $this->getDurationFormatted(),
                'duration_hours' => $this->getDurationInHours(),
                'duration_minutes' => $this->getDurationInMinutes(),
                'is_active' => !$this->end,
                'is_completed' => (bool) $this->end,
            ],
            'status' => [
                'id' => $this->status_id,
                'name' => $this->status->name ?? 'Unknown',
                'color' => $this->status->color ?? '#6c757d',
            ],
            'notes' => $this->notes,
            'notes_preview' => $this->notes ? (strlen($this->notes) > 100 ? substr($this->notes, 0, 100) . '...' : $this->notes) : null,
            'created_by' => $this->created_by,
            'created_at' => $this->created_at,
            'created_at_formatted' => $this->created_at ? Carbon::parse($this->created_at)->format('M j, Y g:i A') : null,
            'created_at_human' => $this->created_at ? Carbon::parse($this->created_at)->diffForHumans() : null,
            'updated_at' => $this->updated_at,
            'updated_at_formatted' => $this->updated_at ? Carbon::parse($this->updated_at)->format('M j, Y g:i A') : null,
            'updated_at_human' => $this->updated_at ? Carbon::parse($this->updated_at)->diffForHumans() : null,
            
            // Additional computed fields for mobile UI
            'display_info' => [
                'title' => $this->getDisplayTitle(),
                'subtitle' => $this->getDisplaySubtitle(),
                'time_info' => $this->getTimeInfo(),
                'status_badge' => [
                    'text' => $this->getStatusText(),
                    'color' => $this->getStatusColor(),
                    'variant' => $this->getStatusVariant(),
                ],
            ],
            
            // Summary for list views
            'summary' => [
                'user_name' => $this->whenLoaded('user', function () {
                    if ($this->user_type === 'App\Modules\Customers\Models\Staff') {
                        return $this->user->first_name . ' ' . $this->user->last_name;
                    }
                    return $this->user->name ?? 'Unknown User';
                }),
                'model_name' => $this->whenLoaded('model', function () {
                    if (!$this->model) return 'General Time';
                    
                    switch ($this->model_type) {
                        case 'App\Modules\Tasks\Models\Task':
                            return $this->model->title ?? 'Task';
                        case 'App\Modules\Projects\Models\Project':
                            return $this->model->title ?? 'Project';
                        case 'App\Modules\Deals\Models\Deal':
                            return $this->model->title ?? 'Deal';
                        case 'App\Modules\Tickets\Models\Ticket':
                            return $this->model->subject ?? 'Ticket';
                        default:
                            return 'Item';
                    }
                }) ?? 'General Time',
                'duration_display' => $this->getDurationFormatted(),
                'status_display' => $this->getStatusText(),
                'date_display' => $this->start ? Carbon::parse($this->start)->format('M j') : null,
                'time_display' => $this->getTimeDisplay(),
            ],
        ];
    }

    /**
     * Get duration in seconds
     */
    private function getDuration(): ?int
    {
        if (!$this->start) return null;
        
        $endTime = $this->end ? Carbon::parse($this->end) : now();
        return Carbon::parse($this->start)->diffInSeconds($endTime);
    }

    /**
     * Get formatted duration (e.g., "2h 30m")
     */
    private function getDurationFormatted(): ?string
    {
        $duration = $this->getDuration();
        if (!$duration) return null;

        $hours = floor($duration / 3600);
        $minutes = floor(($duration % 3600) / 60);

        if ($hours > 0) {
            return $minutes > 0 ? "{$hours}h {$minutes}m" : "{$hours}h";
        }

        return "{$minutes}m";
    }

    /**
     * Get duration in hours (decimal)
     */
    private function getDurationInHours(): ?float
    {
        $duration = $this->getDuration();
        if (!$duration) return null;

        return round($duration / 3600, 2);
    }

    /**
     * Get duration in minutes
     */
    private function getDurationInMinutes(): ?int
    {
        $duration = $this->getDuration();
        if (!$duration) return null;

        return floor($duration / 60);
    }

    /**
     * Get display title for the timesheet
     */
    private function getDisplayTitle(): string
    {
        if ($this->relationLoaded('model') && $this->model) {
            switch ($this->model_type) {
                case 'App\Modules\Tasks\Models\Task':
                    return $this->model->title ?? 'Task #' . $this->model_id;
                case 'App\Modules\Projects\Models\Project':
                    return $this->model->title ?? 'Project #' . $this->model_id;
                case 'App\Modules\Deals\Models\Deal':
                    return $this->model->title ?? 'Deal #' . $this->model_id;
                case 'App\Modules\Tickets\Models\Ticket':
                    return $this->model->subject ?? 'Ticket #' . $this->model_id;
                default:
                    return 'Work Entry #' . $this->model_id;
            }
        }

        return 'General Time Entry';
    }

    /**
     * Get display subtitle for the timesheet
     */
    private function getDisplaySubtitle(): string
    {
        $parts = [];

        if ($this->start) {
            $parts[] = Carbon::parse($this->start)->format('M j, Y');
        }

        if ($this->notes && strlen($this->notes) > 0) {
            $preview = strlen($this->notes) > 50 ? substr($this->notes, 0, 50) . '...' : $this->notes;
            $parts[] = $preview;
        }

        return implode(' • ', $parts);
    }

    /**
     * Get time information for display
     */
    private function getTimeInfo(): string
    {
        if (!$this->start) return 'No start time';

        $startTime = Carbon::parse($this->start)->format('g:i A');
        
        if ($this->end) {
            $endTime = Carbon::parse($this->end)->format('g:i A');
            $duration = $this->getDurationFormatted();
            return "{$startTime} - {$endTime} ({$duration})";
        }

        // Active timesheet
        $duration = $this->getDurationFormatted();
        return "Started at {$startTime} ({$duration} elapsed)";
    }

    /**
     * Get status text
     */
    private function getStatusText(): string
    {
        if (!$this->end) {
            return 'Active';
        }

        return 'Completed';
    }

    /**
     * Get status color
     */
    private function getStatusColor(): string
    {
        if (!$this->end) {
            return '#28a745'; // Green for active
        }

        return '#6c757d'; // Gray for completed
    }

    /**
     * Get status variant for UI
     */
    private function getStatusVariant(): string
    {
        if (!$this->end) {
            return 'success'; // Active
        }

        return 'secondary'; // Completed
    }

    /**
     * Get time display for list views
     */
    private function getTimeDisplay(): string
    {
        if (!$this->start) return '';

        if ($this->end) {
            return Carbon::parse($this->start)->format('g:i A') . ' - ' . Carbon::parse($this->end)->format('g:i A');
        }

        return 'Started ' . Carbon::parse($this->start)->format('g:i A');
    }
}
