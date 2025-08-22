<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TaskResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->task_id,
            'name' => $this->name,
            'description' => $this->description,
            'priority' => [
                'id' => $this->priority_id,
                'name' => $this->priority->name ?? 'Normal',
                'color' => $this->priority->color ?? '#6c757d',
                'sort' => $this->priority->sort ?? 0,
            ],
            'status' => [
                'id' => $this->status_id,
                'name' => $this->status->name ?? 'Unknown',
                'color' => $this->status->color ?? '#6c757d',
            ],
            'progress' => $this->progress(),
            'dates' => [
                'start_date' => $this->start_date,
                'due_date' => $this->due_date,
                'finished_date' => $this->finished_date,
                'is_overdue' => $this->due_date && $this->due_date < now() && !$this->finished_date,
                'days_until_due' => $this->due_date ? now()->diffInDays($this->due_date, false) : null,
            ],
            'model' => [
                'id' => $this->model_id,
                'type' => $this->model_type,
                'name' => $this->model?->name ?? null,
            ],
            'project' => $this->when($this->model_type === 'App\Modules\Projects\Models\Project', [
                'id' => $this->model_id,
                'name' => $this->project->name ?? null,
            ]),
            'team' => $this->whenLoaded('team', function() {
                return $this->team->map(function($member) {
                    return [
                        'id' => $member->user_id,
                        'user_type' => $member->user_type,
                        'name' => $member->user->name ?? 'Unknown',
                        'email' => $member->user->email ?? null,
                        'avatar' => method_exists($member->user, 'avatar') ? $member->user->avatar() : null,
                    ];
                });
            }),
            'checklist' => $this->whenLoaded('checklist', function() {
                return [
                    'items' => $this->checklist->map(function($item) {
                        return [
                            'id' => $item->id,
                            'description' => $item->description,
                            'finished' => $item->finished,
                            'finished_date' => $item->finished_date,
                            'points' => $item->points,
                            'sort' => $item->sort,
                            'visible_to_client' => $item->visible_to_client,
                            'status' => $item->status,
                            'user_id' => $item->user_id,
                        ];
                    }),
                    'total_items' => $this->checklist->count(),
                    'completed_items' => $this->checklist->where('status', '1')->count(),
                    'progress_percentage' => $this->progress(),
                ];
            }),
            'comments_count' => $this->whenLoaded('comments', function() {
                return $this->comments->count();
            }),
            'timesheets' => $this->whenLoaded('timesheets', function() {
                return [
                    'count' => $this->timesheets->count(),
                    'total_hours' => $this->timesheets->sum('hours'),
                ];
            }),
            'settings' => [
                'is_public' => $this->is_public,
                'is_paid' => $this->is_paid,
                'visible_to_client' => $this->visible_to_client,
                'points' => $this->points,
                'sort' => $this->sort,
            ],
            'business_id' => $this->business_id,
            'created_by' => $this->created_by,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
