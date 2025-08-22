<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Carbon\Carbon;

class GoalResource extends JsonResource
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
            'title' => $this->title,
            'description' => $this->description,
            'status' => $this->status,
            'due_date' => $this->due_date ? Carbon::parse($this->due_date)->toISOString() : null,
            'created_at' => $this->created_at ? Carbon::parse($this->created_at)->toISOString() : null,
            'updated_at' => $this->updated_at ? Carbon::parse($this->updated_at)->toISOString() : null,

            // Date formatting for mobile UI
            'formatted_due_date' => $this->due_date ? Carbon::parse($this->due_date)->format('Y-m-d') : null,
            'formatted_due_date_short' => $this->due_date ? Carbon::parse($this->due_date)->format('M j, Y') : null,
            'formatted_due_datetime' => $this->due_date ? Carbon::parse($this->due_date)->format('M j, Y \a\t H:i') : null,

            // Relative time for mobile display
            'due_date_relative' => $this->due_date ? Carbon::parse($this->due_date)->diffForHumans() : null,
            'time_until_due' => $this->due_date && Carbon::parse($this->due_date)->isFuture() 
                ? Carbon::parse($this->due_date)->diffForHumans() 
                : null,
            'time_overdue' => $this->due_date && Carbon::parse($this->due_date)->isPast() && $this->status !== 'completed'
                ? Carbon::parse($this->due_date)->diffForHumans() 
                : null,

            // Status indicators
            'status_display' => $this->getStatusDisplayName(),
            'is_completed' => $this->status === 'completed',
            'is_active' => $this->status === 'active',
            'is_overdue' => $this->due_date && Carbon::parse($this->due_date)->isPast() && $this->status !== 'completed',
            'is_due_today' => $this->due_date ? Carbon::parse($this->due_date)->isToday() : false,
            'is_due_tomorrow' => $this->due_date ? Carbon::parse($this->due_date)->isTomorrow() : false,
            'is_due_this_week' => $this->due_date ? Carbon::parse($this->due_date)->isCurrentWeek() : false,

            // Progress indicators
            'progress_percentage' => $this->getProgressPercentage(),
            'completion_date' => $this->status === 'completed' ? $this->updated_at : null,
            'days_remaining' => $this->due_date && Carbon::parse($this->due_date)->isFuture() 
                ? Carbon::parse($this->due_date)->diffInDays() 
                : null,
            'days_overdue' => $this->due_date && Carbon::parse($this->due_date)->isPast() && $this->status !== 'completed'
                ? Carbon::parse($this->due_date)->diffInDays() * -1
                : null,

            // Calendar information
            'calendar_info' => [
                'due_date' => $this->due_date ? Carbon::parse($this->due_date)->format('Y-m-d') : null,
                'due_time' => $this->due_date ? Carbon::parse($this->due_date)->format('H:i:s') : null,
                'day_of_week' => $this->due_date ? Carbon::parse($this->due_date)->format('l') : null,
                'month' => $this->due_date ? Carbon::parse($this->due_date)->format('F') : null,
                'year' => $this->due_date ? Carbon::parse($this->due_date)->format('Y') : null,
                'is_weekend' => $this->due_date ? Carbon::parse($this->due_date)->isWeekend() : false,
            ],

            // Creator information
            'creator' => $this->when($this->relationLoaded('staff'), function () {
                return [
                    'id' => $this->staff->staff_id ?? null,
                    'name' => $this->staff ? $this->staff->first_name . ' ' . $this->staff->last_name : null,
                    'email' => $this->staff->email ?? null,
                    'avatar' => $this->staff && method_exists($this->staff, 'avatar') ? $this->staff->avatar() : null,
                ];
            }),

            // Related model information (Project, Deal, Task, etc.)
            'related_project' => $this->when($this->relationLoaded('project') && $this->project, function () {
                return [
                    'id' => $this->project->id,
                    'title' => $this->project->title,
                    'status' => $this->project->status ?? null,
                    'progress' => $this->project->progress ?? null,
                ];
            }),

            'related_deal' => $this->when($this->relationLoaded('deal') && $this->deal, function () {
                return [
                    'id' => $this->deal->id,
                    'title' => $this->deal->title,
                    'value' => $this->deal->value ?? null,
                    'currency' => $this->deal->currency ?? null,
                    'status' => $this->deal->status ?? null,
                ];
            }),

            'related_task' => $this->when($this->relationLoaded('task') && $this->task, function () {
                return [
                    'id' => $this->task->id,
                    'title' => $this->task->title,
                    'status' => $this->task->status ?? null,
                    'priority' => $this->task->priority ?? null,
                ];
            }),

            // Mobile UI helpers
            'ui' => [
                'icon' => $this->getIconForGoal(),
                'color' => $this->getColorForStatus(),
                'badge' => $this->getBadgeText(),
                'priority_color' => $this->getPriorityColor(),
                'progress_color' => $this->getProgressColor(),
                'can_complete' => $this->status === 'active',
                'can_reopen' => $this->status === 'completed',
                'time_display' => $this->getTimeDisplayText(),
            ],

            // Quick actions
            'actions' => [
                'can_edit' => true, // Handled in controller based on permissions
                'can_delete' => true, // Handled in controller based on permissions
                'can_complete' => $this->status === 'active',
                'can_reopen' => $this->status === 'completed',
                'can_archive' => $this->status !== 'archived',
            ],

            // Statistics for progress tracking
            'statistics' => [
                'days_since_created' => $this->created_at ? Carbon::parse($this->created_at)->diffInDays() : 0,
                'completion_rate' => $this->getCompletionRate(),
                'urgency_score' => $this->getUrgencyScore(),
            ],

            // Related entities count (if loaded)
            'related_counts' => [
                'tasks_count' => $this->when($this->relationLoaded('tasks'), function () {
                    return $this->tasks->count();
                }),
                'completed_tasks_count' => $this->when($this->relationLoaded('tasks'), function () {
                    return $this->tasks->where('status', 'completed')->count();
                }),
                'reminders_count' => $this->when($this->relationLoaded('reminders'), function () {
                    return $this->reminders->count();
                }),
                'comments_count' => $this->when($this->relationLoaded('comments'), function () {
                    return $this->comments->count();
                }),
            ],
        ];
    }

    /**
     * Get status display name
     */
    private function getStatusDisplayName(): string
    {
        return match ($this->status) {
            'active' => 'Active',
            'completed' => 'Completed',
            'on_hold' => 'On Hold',
            'cancelled' => 'Cancelled',
            'archived' => 'Archived',
            default => 'Unknown',
        };
    }

    /**
     * Get progress percentage based on status
     */
    private function getProgressPercentage(): int
    {
        return match ($this->status) {
            'completed' => 100,
            'active' => $this->calculateDynamicProgress(),
            'on_hold' => 50,
            'cancelled' => 0,
            'archived' => 100,
            default => 0,
        };
    }

    /**
     * Calculate dynamic progress based on time and tasks
     */
    private function calculateDynamicProgress(): int
    {
        // If we have related tasks loaded, use task completion rate
        if ($this->relationLoaded('tasks') && $this->tasks->count() > 0) {
            $completedTasks = $this->tasks->where('status', 'completed')->count();
            $totalTasks = $this->tasks->count();
            return (int) round(($completedTasks / $totalTasks) * 100);
        }

        // Otherwise, calculate based on time progress
        if ($this->due_date && $this->created_at) {
            $totalDuration = Carbon::parse($this->created_at)->diffInDays(Carbon::parse($this->due_date));
            $elapsedDuration = Carbon::parse($this->created_at)->diffInDays(now());
            
            if ($totalDuration > 0) {
                $timeProgress = ($elapsedDuration / $totalDuration) * 100;
                return min(90, max(10, (int) round($timeProgress))); // Cap between 10-90%
            }
        }

        return 25; // Default progress for active goals
    }

    /**
     * Get completion rate for statistics
     */
    private function getCompletionRate(): float
    {
        if ($this->status === 'completed') {
            return 100.0;
        }

        return (float) $this->getProgressPercentage();
    }

    /**
     * Get urgency score (0-100)
     */
    private function getUrgencyScore(): int
    {
        if ($this->status === 'completed' || !$this->due_date) {
            return 0;
        }

        $dueDate = Carbon::parse($this->due_date);
        
        if ($dueDate->isPast()) {
            return 100; // Overdue = maximum urgency
        }

        $daysUntilDue = $dueDate->diffInDays();
        
        if ($daysUntilDue <= 1) {
            return 90; // Due today/tomorrow
        } elseif ($daysUntilDue <= 3) {
            return 75; // Due within 3 days
        } elseif ($daysUntilDue <= 7) {
            return 60; // Due within a week
        } elseif ($daysUntilDue <= 30) {
            return 40; // Due within a month
        } else {
            return 20; // Due in the future
        }
    }

    /**
     * Get icon for goal based on status
     */
    private function getIconForGoal(): string
    {
        return match ($this->status) {
            'completed' => 'check-circle',
            'active' => 'target',
            'on_hold' => 'pause-circle',
            'cancelled' => 'x-circle',
            'archived' => 'archive',
            default => 'circle',
        };
    }

    /**
     * Get color for status
     */
    private function getColorForStatus(): string
    {
        return match ($this->status) {
            'completed' => 'success',
            'active' => $this->is_overdue ? 'danger' : 'primary',
            'on_hold' => 'warning',
            'cancelled' => 'secondary',
            'archived' => 'secondary',
            default => 'secondary',
        };
    }

    /**
     * Get badge text for goal
     */
    private function getBadgeText(): ?string
    {
        if ($this->status === 'completed') {
            return 'Completed';
        }

        if ($this->is_overdue) {
            return 'Overdue';
        }

        if ($this->is_due_today) {
            return 'Due Today';
        }

        if ($this->is_due_tomorrow) {
            return 'Due Tomorrow';
        }

        return null;
    }

    /**
     * Get priority color based on urgency
     */
    private function getPriorityColor(): string
    {
        $urgency = $this->getUrgencyScore();

        if ($urgency >= 90) {
            return 'danger';
        } elseif ($urgency >= 75) {
            return 'warning';
        } elseif ($urgency >= 60) {
            return 'info';
        } else {
            return 'success';
        }
    }

    /**
     * Get progress color based on completion
     */
    private function getProgressColor(): string
    {
        $progress = $this->getProgressPercentage();

        if ($progress >= 100) {
            return 'success';
        } elseif ($progress >= 75) {
            return 'info';
        } elseif ($progress >= 50) {
            return 'warning';
        } elseif ($progress >= 25) {
            return 'primary';
        } else {
            return 'secondary';
        }
    }

    /**
     * Get time display text for mobile
     */
    private function getTimeDisplayText(): string
    {
        if (!$this->due_date) {
            return 'No due date';
        }

        $dueDate = Carbon::parse($this->due_date);

        if ($this->status === 'completed') {
            return 'Completed';
        }

        if ($dueDate->isPast()) {
            return 'Overdue by ' . $dueDate->diffForHumans();
        }

        if ($dueDate->isToday()) {
            return 'Due today';
        }

        if ($dueDate->isTomorrow()) {
            return 'Due tomorrow';
        }

        if ($dueDate->isCurrentWeek()) {
            return 'Due ' . $dueDate->format('l');
        }

        if ($dueDate->isCurrentYear()) {
            return 'Due ' . $dueDate->format('M j');
        }

        return 'Due ' . $dueDate->format('M j, Y');
    }
}
