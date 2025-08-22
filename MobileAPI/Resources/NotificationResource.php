<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'content' => strip_tags($this->content),
            'type' => $this->type,
            'is_read' => $this->is_read,
            'read_at' => $this->read_at,
            'action_url' => $this->action_url,
            'data' => $this->data,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            
            // Enhanced mobile-specific attributes
            'formatted_title' => $this->getFormattedTitle(),
            'formatted_content' => $this->getFormattedContent(),
            'notification_icon' => $this->getNotificationIcon(),
            'notification_color' => $this->getNotificationColor(),
            'priority_level' => $this->getPriorityLevel(),
            'relative_time' => $this->getRelativeTime(),
            'action_available' => !empty($this->action_url),
            
            // Template information (if available)
            'template' => $this->when($this->relationLoaded('template') && $this->template, [
                'id' => $this->template?->id,
                'name' => $this->template?->name,
                'category' => $this->template?->category ?? 'general',
            ]),
            
            // Mobile display format
            'display' => [
                'primary_text' => $this->title,
                'secondary_text' => $this->getShortContent(),
                'icon' => $this->getNotificationIcon(),
                'color' => $this->getNotificationColor(),
                'badge_text' => $this->getBadgeText(),
                'show_badge' => $this->shouldShowBadge(),
            ],
        ];
    }

    /**
     * Get formatted title for mobile display
     */
    protected function getFormattedTitle(): string
    {
        return $this->title ?? 'Notification';
    }

    /**
     * Get formatted content (strip HTML and limit length)
     */
    protected function getFormattedContent(): string
    {
        $content = strip_tags($this->content ?? '');
        return strlen($content) > 200 ? substr($content, 0, 200) . '...' : $content;
    }

    /**
     * Get short content for mobile list view
     */
    protected function getShortContent(): string
    {
        $content = strip_tags($this->content ?? '');
        return strlen($content) > 80 ? substr($content, 0, 80) . '...' : $content;
    }

    /**
     * Get notification icon based on type
     */
    protected function getNotificationIcon(): string
    {
        return match($this->type) {
            'task' => 'task-check',
            'meeting' => 'calendar-event',
            'deal' => 'handshake',
            'lead' => 'user-plus',
            'client' => 'users',
            'estimate' => 'file-dollar',
            'proposal' => 'file-text',
            'invoice' => 'receipt',
            'ticket' => 'support',
            'project' => 'folder-open',
            'reminder' => 'alarm',
            'chat' => 'message-circle',
            'system' => 'settings',
            'urgent' => 'alert-triangle',
            'success' => 'check-circle',
            'warning' => 'alert-circle',
            'error' => 'x-circle',
            'info' => 'info-circle',
            default => 'bell'
        };
    }

    /**
     * Get notification color based on type and priority
     */
    protected function getNotificationColor(): string
    {
        // Check for urgent/priority indicators first
        if ($this->type === 'urgent' || $this->getPriorityLevel() === 'high') {
            return '#dc3545'; // Red for urgent
        }

        if ($this->type === 'warning') {
            return '#ffc107'; // Yellow for warning
        }

        if ($this->type === 'success') {
            return '#28a745'; // Green for success
        }

        if ($this->type === 'error') {
            return '#dc3545'; // Red for error
        }

        // Type-based colors
        return match($this->type) {
            'task' => '#28a745',        // Green
            'meeting' => '#007bff',     // Blue
            'deal' => '#28a745',        // Green
            'lead' => '#17a2b8',        // Teal
            'client' => '#6f42c1',      // Purple
            'estimate' => '#fd7e14',    // Orange
            'proposal' => '#20c997',    // Teal
            'invoice' => '#ffc107',     // Yellow
            'ticket' => '#dc3545',      // Red
            'project' => '#6c757d',     // Gray
            'reminder' => '#17a2b8',    // Teal
            'chat' => '#007bff',        // Blue
            'system' => '#6c757d',      // Gray
            'info' => '#17a2b8',        // Teal
            default => '#6c757d'        // Gray
        };
    }

    /**
     * Get priority level based on type and content
     */
    protected function getPriorityLevel(): string
    {
        // Check content for priority keywords
        $content = strtolower($this->content ?? '');
        $title = strtolower($this->title ?? '');
        
        if (str_contains($content, 'urgent') || str_contains($title, 'urgent') || 
            str_contains($content, 'emergency') || str_contains($title, 'emergency') ||
            $this->type === 'urgent') {
            return 'high';
        }

        if (str_contains($content, 'important') || str_contains($title, 'important') ||
            in_array($this->type, ['reminder', 'meeting', 'deal'])) {
            return 'medium';
        }

        return 'normal';
    }

    /**
     * Get relative time string
     */
    protected function getRelativeTime(): string
    {
        if (!$this->created_at) {
            return 'Unknown';
        }

        $now = now();
        $diff = $this->created_at->diffInMinutes($now);

        if ($diff < 1) {
            return 'Just now';
        } elseif ($diff < 60) {
            return $diff . 'm ago';
        } elseif ($diff < 1440) { // 24 hours
            $hours = intval($diff / 60);
            return $hours . 'h ago';
        } elseif ($diff < 10080) { // 7 days
            $days = intval($diff / 1440);
            return $days . 'd ago';
        } else {
            return $this->created_at->format('M j');
        }
    }

    /**
     * Get badge text for notification
     */
    protected function getBadgeText(): ?string
    {
        if (!$this->is_read) {
            return 'NEW';
        }

        if ($this->getPriorityLevel() === 'high') {
            return 'URGENT';
        }

        if ($this->type === 'reminder' && !$this->is_read) {
            return 'REMINDER';
        }

        return null;
    }

    /**
     * Determine if badge should be shown
     */
    protected function shouldShowBadge(): bool
    {
        return !empty($this->getBadgeText());
    }
}
