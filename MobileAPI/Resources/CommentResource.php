<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Resources\Json\JsonResource;
use Carbon\Carbon;

class CommentResource extends JsonResource
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
            'message' => $this->message,
            'message_preview' => $this->message ? (strlen($this->message) > 150 ? substr($this->message, 0, 150) . '...' : $this->message) : null,
            'word_count' => $this->message ? str_word_count($this->message) : 0,
            'char_count' => $this->message ? strlen($this->message) : 0,
            'status' => [
                'id' => $this->status_id,
                'name' => $this->getStatusName(),
                'color' => $this->getStatusColor(),
            ],
            'file' => [
                'has_attachment' => $this->relationLoaded('file') && $this->file,
                'file_info' => $this->whenLoaded('file', function () {
                    if (!$this->file) return null;
                    
                    return [
                        'id' => $this->file->id,
                        'name' => $this->file->name ?? 'Attachment',
                        'file_name' => $this->file->file_name ?? null,
                        'mime_type' => $this->file->mime_type ?? null,
                        'size' => $this->file->size ?? null,
                        'size_formatted' => $this->file->size ? $this->formatFileSize($this->file->size) : null,
                        'url' => $this->file->url ?? null,
                        'is_image' => $this->isImageFile($this->file->mime_type ?? ''),
                        'is_document' => $this->isDocumentFile($this->file->mime_type ?? ''),
                    ];
                }),
            ],
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
            'is_edited' => $this->created_at && $this->updated_at ? !Carbon::parse($this->created_at)->equalTo(Carbon::parse($this->updated_at)) : false,
            
            // Additional computed fields for mobile UI
            'display_info' => [
                'title' => $this->getDisplayTitle(),
                'subtitle' => $this->getDisplaySubtitle(),
                'metadata' => $this->getMetadata(),
                'status_badge' => [
                    'text' => $this->getStatusName(),
                    'color' => $this->getStatusColor(),
                    'variant' => $this->getStatusVariant(),
                ],
                'attachment_badge' => [
                    'has_attachment' => $this->relationLoaded('file') && $this->file,
                    'icon' => $this->getAttachmentIcon(),
                    'text' => $this->getAttachmentText(),
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
                }) ?? 'General Comment',
                'preview' => $this->message ? (strlen($this->message) > 100 ? substr($this->message, 0, 100) . '...' : $this->message) : '',
                'date_display' => $this->created_at ? Carbon::parse($this->created_at)->format('M j') : null,
                'time_display' => $this->created_at ? Carbon::parse($this->created_at)->format('g:i A') : null,
                'has_attachment' => $this->relationLoaded('file') && $this->file,
                'status_display' => $this->getStatusName(),
                'is_mine' => $this->isCurrentUserComment(),
            ],
        ];
    }

    /**
     * Get display title for the comment
     */
    private function getDisplayTitle(): string
    {
        if ($this->relationLoaded('model') && $this->model) {
            return $this->getModelDisplayName() . ' - Comment';
        }

        return 'General Comment';
    }

    /**
     * Get display subtitle for the comment
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

        if ($this->relationLoaded('file') && $this->file) {
            $parts[] = 'with attachment';
        }

        return implode(' • ', $parts);
    }

    /**
     * Get metadata for display
     */
    private function getMetadata(): array
    {
        $metadata = [];

        if ($this->message) {
            $wordCount = str_word_count($this->message);
            $metadata['word_count'] = $wordCount . ' word' . ($wordCount !== 1 ? 's' : '');
        }

        if ($this->created_at) {
            $metadata['created'] = Carbon::parse($this->created_at)->diffForHumans();
        }

        if ($this->created_at && $this->updated_at && !Carbon::parse($this->created_at)->equalTo(Carbon::parse($this->updated_at))) {
            $metadata['edited'] = 'Edited ' . Carbon::parse($this->updated_at)->diffForHumans();
        }

        if ($this->relationLoaded('model') && $this->model) {
            $metadata['related_to'] = $this->getModelCategory();
        }

        return $metadata;
    }

    /**
     * Get status name
     */
    private function getStatusName(): string
    {
        $statuses = [
            1 => 'Active',
            2 => 'Pending',
            3 => 'Hidden',
        ];

        return $statuses[$this->status_id] ?? 'Unknown';
    }

    /**
     * Get status color
     */
    private function getStatusColor(): string
    {
        $colors = [
            1 => '#28a745', // Green for active
            2 => '#ffc107', // Yellow for pending
            3 => '#6c757d', // Gray for hidden
        ];

        return $colors[$this->status_id] ?? '#6c757d';
    }

    /**
     * Get status variant for UI
     */
    private function getStatusVariant(): string
    {
        $variants = [
            1 => 'success',
            2 => 'warning',
            3 => 'secondary',
        ];

        return $variants[$this->status_id] ?? 'secondary';
    }

    /**
     * Get attachment icon
     */
    private function getAttachmentIcon(): ?string
    {
        if (!$this->relationLoaded('file') || !$this->file) {
            return null;
        }

        $mimeType = $this->file->mime_type ?? '';

        if ($this->isImageFile($mimeType)) {
            return 'image';
        }

        if ($this->isDocumentFile($mimeType)) {
            return 'file-text';
        }

        return 'paperclip';
    }

    /**
     * Get attachment text
     */
    private function getAttachmentText(): ?string
    {
        if (!$this->relationLoaded('file') || !$this->file) {
            return null;
        }

        return $this->file->name ?? 'Attachment';
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
     * Check if comment belongs to current user
     */
    private function isCurrentUserComment(): bool
    {
        $currentUser = request()->user();
        
        if (!$currentUser) {
            return false;
        }

        return $this->user_id === $currentUser->staff_id && 
               $this->user_type === get_class($currentUser);
    }

    /**
     * Check if file is an image
     */
    private function isImageFile(string $mimeType): bool
    {
        return strpos($mimeType, 'image/') === 0;
    }

    /**
     * Check if file is a document
     */
    private function isDocumentFile(string $mimeType): bool
    {
        $documentTypes = [
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/vnd.ms-powerpoint',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'text/plain',
        ];

        return in_array($mimeType, $documentTypes);
    }

    /**
     * Format file size in human readable format
     */
    private function formatFileSize(int $size): string
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        
        for ($i = 0; $size > 1024 && $i < count($units) - 1; $i++) {
            $size /= 1024;
        }
        
        return round($size, 2) . ' ' . $units[$i];
    }
}
