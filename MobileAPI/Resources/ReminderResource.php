<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Carbon\Carbon;

class ReminderResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'date' => $this->date ? Carbon::parse($this->date)->toISOString() : null,
            'is_notified' => (bool) $this->is_notified,
            'created_at' => $this->created_at ? Carbon::parse($this->created_at)->toISOString() : null,
            'updated_at' => $this->updated_at ? Carbon::parse($this->updated_at)->toISOString() : null,

            // Date formatting for mobile UI
            'formatted_date' => $this->date ? Carbon::parse($this->date)->format('Y-m-d H:i') : null,
            'formatted_date_short' => $this->date ? Carbon::parse($this->date)->format('M j, Y') : null,
            'formatted_time' => $this->date ? Carbon::parse($this->date)->format('H:i') : null,
            'formatted_datetime' => $this->date ? Carbon::parse($this->date)->format('M j, Y \a\t H:i') : null,

            // Relative time for mobile display
            'relative_time' => $this->date ? Carbon::parse($this->date)->diffForHumans() : null,
            'time_until' => $this->date && Carbon::parse($this->date)->isFuture() 
                ? Carbon::parse($this->date)->diffForHumans() 
                : null,
            'time_ago' => $this->date && Carbon::parse($this->date)->isPast() 
                ? Carbon::parse($this->date)->diffForHumans() 
                : null,

            // Status indicators
            'status' => $this->getStatusAttribute(),
            'is_overdue' => $this->date ? Carbon::parse($this->date)->isPast() && !$this->is_notified : false,
            'is_today' => $this->date ? Carbon::parse($this->date)->isToday() : false,
            'is_upcoming' => $this->date ? Carbon::parse($this->date)->between(now(), now()->addDay()) : false,

            // Calendar information
            'calendar_info' => [
                'date' => $this->date ? Carbon::parse($this->date)->format('Y-m-d') : null,
                'time' => $this->date ? Carbon::parse($this->date)->format('H:i:s') : null,
                'day_of_week' => $this->date ? Carbon::parse($this->date)->format('l') : null,
                'month' => $this->date ? Carbon::parse($this->date)->format('F') : null,
                'year' => $this->date ? Carbon::parse($this->date)->format('Y') : null,
                'is_weekend' => $this->date ? Carbon::parse($this->date)->isWeekend() : false,
            ],

            // User information
            'user' => $this->when($this->relationLoaded('user'), function () {
                return [
                    'id' => $this->user->staff_id ?? null,
                    'type' => 'staff',
                    'name' => $this->user ? $this->user->first_name . ' ' . $this->user->last_name : null,
                    'email' => $this->user->email ?? null,
                    'avatar' => $this->user && method_exists($this->user, 'avatar') ? $this->user->avatar() : null,
                ];
            }),

            // Model information (what the reminder is for)
            'model' => $this->when($this->relationLoaded('model') && $this->model, function () {
                $modelData = [
                    'id' => $this->model_id,
                    'type' => $this->model_type,
                    'type_display' => $this->getModelTypeDisplayName(),
                ];

                // Add model-specific data based on type
                if ($this->model) {
                    switch ($this->model_type) {
                        case 'App\Modules\Leads\Models\Lead':
                            $modelData = array_merge($modelData, [
                                'title' => $this->model->title ?? null,
                                'company' => $this->model->company ?? null,
                                'status' => $this->model->status ?? null,
                            ]);
                            break;

                        case 'App\Modules\Projects\Models\Project':
                            $modelData = array_merge($modelData, [
                                'title' => $this->model->title ?? null,
                                'status' => $this->model->status ?? null,
                                'progress' => $this->model->progress ?? null,
                            ]);
                            break;

                        case 'App\Modules\Tasks\Models\Task':
                            $modelData = array_merge($modelData, [
                                'title' => $this->model->title ?? null,
                                'status' => $this->model->status ?? null,
                                'priority' => $this->model->priority ?? null,
                            ]);
                            break;

                        case 'App\Modules\Deals\Models\Deal':
                            $modelData = array_merge($modelData, [
                                'title' => $this->model->title ?? null,
                                'value' => $this->model->value ?? null,
                                'currency' => $this->model->currency ?? null,
                                'status' => $this->model->status ?? null,
                            ]);
                            break;

                        case 'App\Modules\Tickets\Models\Ticket':
                            $modelData = array_merge($modelData, [
                                'title' => $this->model->title ?? null,
                                'subject' => $this->model->subject ?? null,
                                'status' => $this->model->status ?? null,
                                'priority' => $this->model->priority ?? null,
                            ]);
                            break;

                        case 'App\Modules\Customers\Models\Staff':
                            $modelData = array_merge($modelData, [
                                'name' => $this->model ? $this->model->first_name . ' ' . $this->model->last_name : null,
                                'email' => $this->model->email ?? null,
                                'role' => $this->model->role ?? null,
                            ]);
                            break;

                        case 'App\Modules\Proposals\Models\Proposal':
                            $modelData = array_merge($modelData, [
                                'title' => $this->model->title ?? null,
                                'amount' => $this->model->amount ?? null,
                                'currency' => $this->model->currency ?? null,
                                'status' => $this->model->status ?? null,
                            ]);
                            break;

                        case 'App\Modules\Estimates\Models\Estimate':
                            $modelData = array_merge($modelData, [
                                'title' => $this->model->title ?? null,
                                'amount' => $this->model->amount ?? null,
                                'currency' => $this->model->currency ?? null,
                                'status' => $this->model->status ?? null,
                            ]);
                            break;

                        default:
                            // Generic fallback
                            $modelData = array_merge($modelData, [
                                'title' => $this->model->title ?? $this->model->name ?? null,
                            ]);
                            break;
                    }
                }

                return $modelData;
            }),

            // Mobile UI helpers
            'ui' => [
                'icon' => $this->getIconForReminder(),
                'color' => $this->getColorForStatus(),
                'badge' => $this->getBadgeText(),
                'priority_color' => $this->getPriorityColor(),
                'can_snooze' => !$this->is_notified && $this->date && Carbon::parse($this->date)->isFuture(),
                'can_mark_notified' => !$this->is_notified,
                'time_display' => $this->getTimeDisplayText(),
            ],

            // Quick actions
            'actions' => [
                'can_edit' => true, // Only creator can edit (handled in controller)
                'can_delete' => true, // Only creator can delete (handled in controller)
                'can_snooze' => !$this->is_notified,
                'can_mark_notified' => !$this->is_notified,
            ],

            // Snooze options for mobile
            'snooze_options' => [
                ['value' => 15, 'label' => '15 minutes'],
                ['value' => 30, 'label' => '30 minutes'],
                ['value' => 60, 'label' => '1 hour'],
                ['value' => 120, 'label' => '2 hours'],
                ['value' => 240, 'label' => '4 hours'],
                ['value' => 480, 'label' => '8 hours'],
                ['value' => 1440, 'label' => '1 day'],
            ],
        ];
    }

    /**
     * Get status attribute for the reminder
     */
    private function getStatusAttribute(): string
    {
        if ($this->is_notified) {
            return 'notified';
        }

        if ($this->date && Carbon::parse($this->date)->isPast()) {
            return 'overdue';
        }

        if ($this->date && Carbon::parse($this->date)->isToday()) {
            return 'today';
        }

        if ($this->date && Carbon::parse($this->date)->between(now(), now()->addDay())) {
            return 'upcoming';
        }

        return 'pending';
    }

    /**
     * Get model type display name
     */
    private function getModelTypeDisplayName(): string
    {
        $modelNames = [
            'App\Modules\Leads\Models\Lead' => 'Lead',
            'App\Modules\Projects\Models\Project' => 'Project',
            'App\Modules\Tasks\Models\Task' => 'Task',
            'App\Modules\Deals\Models\Deal' => 'Deal',
            'App\Modules\Tickets\Models\Ticket' => 'Ticket',
            'App\Modules\Customers\Models\Staff' => 'Staff',
            'App\Modules\Proposals\Models\Proposal' => 'Proposal',
            'App\Modules\Estimates\Models\Estimate' => 'Estimate',
        ];

        return $modelNames[$this->model_type] ?? 'Unknown';
    }

    /**
     * Get icon for reminder based on type and status
     */
    private function getIconForReminder(): string
    {
        if ($this->is_notified) {
            return 'check-circle';
        }

        if ($this->date && Carbon::parse($this->date)->isPast()) {
            return 'alert-circle';
        }

        if ($this->date && Carbon::parse($this->date)->isToday()) {
            return 'clock';
        }

        return 'bell';
    }

    /**
     * Get color for status
     */
    private function getColorForStatus(): string
    {
        $status = $this->getStatusAttribute();

        return match ($status) {
            'notified' => 'success',
            'overdue' => 'danger',
            'today' => 'warning',
            'upcoming' => 'info',
            'pending' => 'primary',
            default => 'secondary',
        };
    }

    /**
     * Get badge text for reminder
     */
    private function getBadgeText(): ?string
    {
        $status = $this->getStatusAttribute();

        return match ($status) {
            'overdue' => 'Overdue',
            'today' => 'Today',
            'upcoming' => 'Upcoming',
            'notified' => 'Done',
            default => null,
        };
    }

    /**
     * Get priority color based on urgency
     */
    private function getPriorityColor(): string
    {
        if (!$this->date) {
            return 'secondary';
        }

        $date = Carbon::parse($this->date);

        if ($date->isPast() && !$this->is_notified) {
            return 'danger'; // Overdue
        }

        if ($date->isToday()) {
            return 'warning'; // Today
        }

        if ($date->isTomorrow()) {
            return 'info'; // Tomorrow
        }

        if ($date->diffInDays() <= 7) {
            return 'primary'; // This week
        }

        return 'secondary'; // Future
    }

    /**
     * Get time display text for mobile
     */
    private function getTimeDisplayText(): string
    {
        if (!$this->date) {
            return 'No date set';
        }

        $date = Carbon::parse($this->date);

        if ($date->isToday()) {
            return 'Today at ' . $date->format('H:i');
        }

        if ($date->isYesterday()) {
            return 'Yesterday at ' . $date->format('H:i');
        }

        if ($date->isTomorrow()) {
            return 'Tomorrow at ' . $date->format('H:i');
        }

        if ($date->isCurrentWeek()) {
            return $date->format('l \a\t H:i');
        }

        if ($date->isCurrentYear()) {
            return $date->format('M j \a\t H:i');
        }

        return $date->format('M j, Y \a\t H:i');
    }
}
