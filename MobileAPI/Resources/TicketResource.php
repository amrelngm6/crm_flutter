<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Modules\Customers\Models\Staff;

class TicketResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'subject' => $this->subject,
            'message' => $this->message,
            'due_date' => $this->due_date,
            'is_overdue' => $this->due_date ? $this->due_date < today() : false,
            'days_until_due' => $this->due_date ? 
                max(0, (strtotime($this->due_date) - time()) / (60 * 60 * 24)) : null,
            'status' => [
                'id' => $this->status_id,
                'name' => $this->status->name ?? 'Unknown',
                'color' => $this->status->color ?? '#6c757d',
            ],
            'priority' => [
                'id' => $this->priority_id,
                'name' => $this->priority->name ?? 'Unknown',
                'color' => $this->priority->color ?? '#6c757d',
                'level' => $this->priority->level ?? 1,
            ],
            'category' => $this->when($this->category, [
                'id' => $this->category->id ?? null,
                'name' => $this->category->name ?? null,
                'description' => $this->category->description ?? null,
            ]),
            'client' => $this->when($this->client, [
                'id' => $this->client->client_id ?? null,
                'name' => $this->client->name ?? null,
                'email' => $this->client->email ?? null,
                'phone' => $this->client->phone ?? null,
                'company_name' => $this->client->company_name ?? null,
                'avatar' => $this->client ? $this->client->avatar() : null,
            ]),
            'model' => [
                'id' => $this->model_id,
                'type' => $this->model_type,
                'name' => $this->modelName(),
                'details' => $this->when($this->model, [
                    'name' => $this->model->name ?? null,
                    'title' => $this->model->title ?? null,
                ]),
            ],
            'assigned_staff' => $this->whenLoaded('staffMembers', function() {
                return $this->staffMembers->map(function($member) {
                    $staffMember = Staff::find($member->user_id);
                    return [
                        'id' => $staffMember->id(),
                        'name' => $staffMember ? $staffMember->name : 'Unknown',
                        'email' => $staffMember->email ?? null,
                        'avatar' => $staffMember ? $staffMember->avatar() : null,
                    ];
                });
            }),
            'creator' => [
                'id' => $this->creator_id,
                'type' => $this->creator_type,
                'name' => $this->creatorName(),
            ],
            'comments' => $this->whenLoaded('comments', function() {
                return [
                    'count' => $this->comments->count(),
                    'data' => $this->comments->map(function($comment) {
                        return [
                            'id' => $comment->id,
                            'message' => $comment->message,
                            'created_at' => $comment->created_at,
                            'author' => $comment->user->name ?? 'Unknown',
                            'avatar' => $comment->user->avatar() ?? null,
                        ];
                    }),
                    'latest' => $this->comments->first() ? [
                        'id' => $this->comments->first()->id,
                        'message' => $this->comments->first()->message,
                        'created_at' => $this->comments->first()->created_at,
                        'author' => $this->comments->first()->user->name ?? 'Unknown',
                        'avatar' => $this->comments->first()->user->avatar() ?? null,
                    ] : null,
                ];
            }),
            'tasks' => $this->whenLoaded('tasks', function() {
                return [
                    'count' => $this->tasks->count(),
                    'completed_count' => $this->tasks->where('status', 'completed')->count(),
                    'pending_count' => $this->tasks->where('status', '!=', 'completed')->count(),
                ];
            }),
            'business_id' => $this->business_id,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }

    /**
     * Get model name for display
     */
    private function modelName(): string
    {
        if (!$this->model_type || !$this->model_id) {
            return 'No Model';
        }

        $modelClass = $this->model_type;
        
        // Extract class name from namespace
        $className = class_basename($modelClass);
        
        return $className . ' #' . $this->model_id;
    }

    /**
     * Get creator name for display
     */
    private function creatorName(): string
    {
        if (!$this->creator_type || !$this->creator_id) {
            return 'Unknown';
        }

        try {
            $creatorClass = $this->creator_type;
            
            if (class_exists($creatorClass)) {
                $creator = $creatorClass::find($this->creator_id);
                
                if ($creator) {
                    // Try different name patterns
                    if (method_exists($creator, 'getName')) {
                        return $creator->getName();
                    } elseif (isset($creator->name)) {
                        return $creator->name;
                    } elseif (isset($creator->first_name)) {
                        return $creator->first_name . ' ' . ($creator->last_name ?? '');
                    }
                }
            }
        } catch (\Exception $e) {
            // Silently handle any exceptions
        }

        return 'Unknown';
    }
}
