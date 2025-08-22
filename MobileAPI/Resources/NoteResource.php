<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Resources\Json\JsonResource;
use Carbon\Carbon;

class NoteResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
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
                        case 'App\Modules\Leads\Models\Lead':
                            return $this->model->title ?? $this->model->first_name . ' ' . $this->model->last_name ?? 'Lead #' . $this->model_id;
                        case 'App\Modules\Projects\Models\Project':
                            return $this->model->title ?? 'Project #' . $this->model_id;
                        case 'App\Modules\Tasks\Models\Task':
                            return $this->model->title ?? 'Task #' . $this->model_id;
                        case 'App\Modules\Deals\Models\Deal':
                            return $this->model->title ?? 'Deal #' . $this->model_id;
                        case 'App\Modules\Tickets\Models\Ticket':
                            return $this->model->subject ?? 'Ticket #' . $this->model_id;
                        case 'App\Modules\Customers\Models\Staff':
                            return $this->model->first_name . ' ' . $this->model->last_name ?? 'Staff #' . $this->model_id;
                        case 'App\Modules\Proposals\Models\Proposal':
                            return $this->model->title ?? 'Proposal #' . $this->model_id;
                        case 'App\Modules\Estimates\Models\Estimate':
                            return $this->model->title ?? 'Estimate #' . $this->model_id;
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
                'category' => $this->whenLoaded('model', function () {
                    return $this->getModelCategory();
                }),
            ],
            'description' => $this->description,
            'description_preview' => $this->description ? (strlen($this->description) > 150 ? substr($this->description, 0, 150) . '...' : $this->description) : null,
            'word_count' => $this->description ? str_word_count($this->description) : 0,
            'char_count' => $this->description ? strlen($this->description) : 0,
            'created_at' => $this->created_at,
            'created_at_formatted' => $this->created_at ? Carbon::parse($this->created_at)->format('M j, Y g:i A') : null,
            'created_at_human' => $this->created_at ? Carbon::parse($this->created_at)->diffForHumans() : null,
            'created_date' => $this->created_at ? Carbon::parse($this->created_at)->format('M j, Y') : null,
            'created_time' => $this->created_at ? Carbon::parse($this->created_at)->format('g:i A') : null,
            'updated_at' => $this->updated_at,
            'updated_at_formatted' => $this->updated_at ? Carbon::parse($this->updated_at)->format('M j, Y g:i A') : null,
            'updated_at_human' => $this->updated_at ? Carbon::parse($this->updated_at)->diffForHumans() : null,
            'is_recent' => $this->created_at ? Carbon::parse($this->created_at)->gt(now()->subDays(3)) : false,
            'is_today' => $this->created_at ? Carbon::parse($this->created_at)->isToday() : false,
            
            // Additional computed fields for mobile UI
            'display_info' => [
                'title' => $this->getDisplayTitle(),
                'subtitle' => $this->getDisplaySubtitle(),
                'metadata' => $this->getMetadata(),
                'badge' => [
                    'text' => $this->getBadgeText(),
                    'color' => $this->getBadgeColor(),
                    'variant' => $this->getBadgeVariant(),
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
                    return $this->getModelDisplayName();
                }) ?? 'General Note',
                'preview' => $this->description ? (strlen($this->description) > 100 ? substr($this->description, 0, 100) . '...' : $this->description) : '',
                'date_display' => $this->created_at ? Carbon::parse($this->created_at)->format('M j') : null,
                'time_display' => $this->created_at ? Carbon::parse($this->created_at)->format('g:i A') : null,
                'is_mine' => $this->isCurrentUserNote(),
            ],
        ];
    }

    /**
     * Get display title for the note
     */
    private function getDisplayTitle(): string
    {
        if ($this->relationLoaded('model') && $this->model) {
            return $this->getModelDisplayName() . ' - Note';
        }

        return 'General Note';
    }

    /**
     * Get display subtitle for the note
     */
    private function getDisplaySubtitle(): string
    {
        $parts = [];

        if ($this->created_at) {
            $parts[] = Carbon::parse($this->created_at)->format('M j, Y');
        }

        if ($this->relationLoaded('user') && $this->user) {
            if ($this->user_type === 'App\Modules\Customers\Models\Staff') {
                $parts[] = 'by ' . $this->user->first_name . ' ' . $this->user->last_name;
            }
        }

        return implode(' • ', $parts);
    }

    /**
     * Get metadata for display
     */
    private function getMetadata(): array
    {
        $metadata = [];

        if ($this->description) {
            $wordCount = str_word_count($this->description);
            $metadata['word_count'] = $wordCount . ' word' . ($wordCount !== 1 ? 's' : '');
        }

        if ($this->created_at) {
            $metadata['created'] = Carbon::parse($this->created_at)->diffForHumans();
        }

        if ($this->relationLoaded('model') && $this->model) {
            $metadata['related_to'] = $this->getModelCategory();
        }

        return $metadata;
    }

    /**
     * Get badge text
     */
    private function getBadgeText(): string
    {
        if ($this->created_at && Carbon::parse($this->created_at)->isToday()) {
            return 'Today';
        }

        if ($this->created_at && Carbon::parse($this->created_at)->isYesterday()) {
            return 'Yesterday';
        }

        if ($this->created_at && Carbon::parse($this->created_at)->gt(now()->subDays(7))) {
            return 'This Week';
        }

        return 'Note';
    }

    /**
     * Get badge color
     */
    private function getBadgeColor(): string
    {
        if ($this->created_at && Carbon::parse($this->created_at)->isToday()) {
            return '#28a745'; // Green for today
        }

        if ($this->created_at && Carbon::parse($this->created_at)->gt(now()->subDays(3))) {
            return '#17a2b8'; // Blue for recent
        }

        return '#6c757d'; // Gray for older
    }

    /**
     * Get badge variant for UI
     */
    private function getBadgeVariant(): string
    {
        if ($this->created_at && Carbon::parse($this->created_at)->isToday()) {
            return 'success';
        }

        if ($this->created_at && Carbon::parse($this->created_at)->gt(now()->subDays(3))) {
            return 'info';
        }

        return 'secondary';
    }

    /**
     * Get model display name
     */
    private function getModelDisplayName(): string
    {
        if (!$this->relationLoaded('model') || !$this->model) {
            return $this->getModelCategory();
        }

        switch ($this->model_type) {
            case 'App\Modules\Leads\Models\Lead':
                return $this->model->title ?? $this->model->first_name . ' ' . $this->model->last_name ?? 'Lead';
            case 'App\Modules\Projects\Models\Project':
                return $this->model->title ?? 'Project';
            case 'App\Modules\Tasks\Models\Task':
                return $this->model->title ?? 'Task';
            case 'App\Modules\Deals\Models\Deal':
                return $this->model->title ?? 'Deal';
            case 'App\Modules\Tickets\Models\Ticket':
                return $this->model->subject ?? 'Ticket';
            case 'App\Modules\Customers\Models\Staff':
                return $this->model->first_name . ' ' . $this->model->last_name ?? 'Staff';
            case 'App\Modules\Proposals\Models\Proposal':
                return $this->model->title ?? 'Proposal';
            case 'App\Modules\Estimates\Models\Estimate':
                return $this->model->title ?? 'Estimate';
            default:
                return 'Item';
        }
    }

    /**
     * Get model category name
     */
    private function getModelCategory(): string
    {
        $categories = [
            'App\Modules\Leads\Models\Lead' => 'Lead',
            'App\Modules\Projects\Models\Project' => 'Project',
            'App\Modules\Tasks\Models\Task' => 'Task',
            'App\Modules\Deals\Models\Deal' => 'Deal',
            'App\Modules\Tickets\Models\Ticket' => 'Ticket',
            'App\Modules\Customers\Models\Staff' => 'Staff',
            'App\Modules\Proposals\Models\Proposal' => 'Proposal',
            'App\Modules\Estimates\Models\Estimate' => 'Estimate',
        ];

        return $categories[$this->model_type] ?? 'General';
    }

    /**
     * Check if note belongs to current user
     */
    private function isCurrentUserNote(): bool
    {
        $currentUser = request()->user();
        
        if (!$currentUser) {
            return false;
        }

        return $this->user_id === $currentUser->staff_id && 
               $this->user_type === get_class($currentUser);
    }
}
