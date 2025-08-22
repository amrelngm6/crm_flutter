<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Carbon\Carbon;

class EmailMessageResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'message_id' => $this->message_id,
            'subject' => $this->subject,
            'from_email' => $this->from_email,
            'from_name' => $this->from_name,
            'to_email' => $this->to_email,
            'to_name' => $this->to_name,
            'cc' => $this->cc,
            'bcc' => $this->bcc,
            'reply_to' => $this->reply_to,
            'date' => $this->date?->toISOString(),
            'body_html' => $this->body_html,
            'body_text' => $this->body_text,
            'snippet' => $this->getSnippet(),
            
            // Status flags
            'is_read' => $this->is_read,
            'is_starred' => $this->is_starred,
            'is_flagged' => $this->is_flagged,
            'is_draft' => $this->is_draft,
            'is_sent' => $this->is_sent,
            'is_archived' => $this->is_archived,
            'is_deleted' => $this->is_deleted,
            'is_spam' => $this->is_spam,
            
            // Folders and labels
            'folder' => $this->folder,
            'labels' => $this->labels ? json_decode($this->labels, true) : [],
            
            // Priority and importance
            'priority' => $this->priority,
            'importance' => $this->importance,
            
            // Thread information
            'thread_id' => $this->thread_id,
            'in_reply_to' => $this->in_reply_to,
            'references' => $this->references,
            
            // Account information
            'account' => [
                'id' => $this->account_id,
                'name' => $this->whenLoaded('account', function() {
                    return $this->account->name;
                }),
                'email' => $this->whenLoaded('account', function() {
                    return $this->account->email;
                }),
            ],
            
            // Attachments
            'has_attachments' => $this->whenLoaded('attachments', function() {
                return $this->attachments->count() > 0;
            }),
            'attachments_count' => $this->whenLoaded('attachments', function() {
                return $this->attachments->count();
            }),
            'attachments' => EmailAttachmentResource::collection($this->whenLoaded('attachments')),
            
            // Size information
            'size' => $this->size,
            'size_human' => $this->getHumanReadableSize(),
            
            // Contact information
            'sender_info' => $this->getSenderInfo(),
            'recipient_info' => $this->getRecipientInfo(),
            
            // Timing information
            'is_recent' => $this->isRecent(),
            'is_today' => $this->isToday(),
            'is_this_week' => $this->isThisWeek(),
            'relative_time' => $this->getRelativeTime(),
            
            // Threading
            'thread_info' => [
                'thread_id' => $this->thread_id,
                'thread_position' => $this->thread_position,
                'has_previous' => !empty($this->in_reply_to),
                'has_next' => $this->whenLoaded('replies', function() {
                    return $this->replies->count() > 0;
                }),
            ],
            
            // Business information
            'business_id' => $this->business_id,
            
            // Timestamps
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
    
    /**
     * Get a snippet of the email content for previews
     */
    private function getSnippet(int $length = 150): string
    {
        $text = $this->body_text ?: strip_tags($this->body_html ?: '');
        $text = preg_replace('/\s+/', ' ', trim($text));
        
        if (strlen($text) <= $length) {
            return $text;
        }
        
        return substr($text, 0, $length) . '...';
    }
    
    /**
     * Get human readable file size
     */
    private function getHumanReadableSize(): string
    {
        if (!$this->size) {
            return '0 B';
        }
        
        $units = ['B', 'KB', 'MB', 'GB'];
        $size = $this->size;
        $unitIndex = 0;
        
        while ($size >= 1024 && $unitIndex < count($units) - 1) {
            $size /= 1024;
            $unitIndex++;
        }
        
        return round($size, 1) . ' ' . $units[$unitIndex];
    }
    
    /**
     * Get sender information with contact resolution
     */
    private function getSenderInfo(): array
    {
        return [
            'email' => $this->from_email,
            'name' => $this->from_name ?: $this->extractNameFromEmail($this->from_email),
            'initials' => $this->getInitials($this->from_name ?: $this->from_email),
            'display_name' => $this->from_name ?: $this->from_email,
        ];
    }
    
    /**
     * Get recipient information
     */
    private function getRecipientInfo(): array
    {
        $recipients = [];
        
        // Parse TO recipients
        if ($this->to_email) {
            $toEmails = explode(',', $this->to_email);
            $toNames = $this->to_name ? explode(',', $this->to_name) : [];
            
            foreach ($toEmails as $index => $email) {
                $email = trim($email);
                $name = isset($toNames[$index]) ? trim($toNames[$index]) : '';
                
                $recipients[] = [
                    'type' => 'to',
                    'email' => $email,
                    'name' => $name ?: $this->extractNameFromEmail($email),
                    'display_name' => $name ?: $email,
                ];
            }
        }
        
        // Parse CC recipients
        if ($this->cc) {
            $ccEmails = explode(',', $this->cc);
            foreach ($ccEmails as $email) {
                $email = trim($email);
                $recipients[] = [
                    'type' => 'cc',
                    'email' => $email,
                    'name' => $this->extractNameFromEmail($email),
                    'display_name' => $email,
                ];
            }
        }
        
        // Parse BCC recipients (usually not visible in received emails)
        if ($this->bcc) {
            $bccEmails = explode(',', $this->bcc);
            foreach ($bccEmails as $email) {
                $email = trim($email);
                $recipients[] = [
                    'type' => 'bcc',
                    'email' => $email,
                    'name' => $this->extractNameFromEmail($email),
                    'display_name' => $email,
                ];
            }
        }
        
        return $recipients;
    }
    
    /**
     * Extract name from email address
     */
    private function extractNameFromEmail(string $email): string
    {
        $username = explode('@', $email)[0];
        return ucwords(str_replace(['.', '_', '-', '+'], ' ', $username));
    }
    
    /**
     * Get initials from name or email
     */
    private function getInitials(string $nameOrEmail): string
    {
        if (strpos($nameOrEmail, '@') !== false) {
            $nameOrEmail = $this->extractNameFromEmail($nameOrEmail);
        }
        
        $words = explode(' ', trim($nameOrEmail));
        $initials = '';
        
        foreach (array_slice($words, 0, 2) as $word) {
            $initials .= strtoupper(substr($word, 0, 1));
        }
        
        return $initials ?: strtoupper(substr($nameOrEmail, 0, 2));
    }
    
    /**
     * Check if message is recent (within last 24 hours)
     */
    private function isRecent(): bool
    {
        return $this->date && $this->date > now()->subHours(24);
    }
    
    /**
     * Check if message is from today
     */
    private function isToday(): bool
    {
        return $this->date && $this->date->isToday();
    }
    
    /**
     * Check if message is from this week
     */
    private function isThisWeek(): bool
    {
        return $this->date && $this->date > now()->startOfWeek();
    }
    
    /**
     * Get relative time description
     */
    private function getRelativeTime(): string
    {
        if (!$this->date) {
            return 'Unknown';
        }
        
        $carbon = Carbon::parse($this->date);
        
        if ($carbon->isToday()) {
            return $carbon->format('g:i A');
        } elseif ($carbon->isYesterday()) {
            return 'Yesterday';
        } elseif ($carbon > now()->subWeek()) {
            return $carbon->format('l'); // Day name
        } elseif ($carbon > now()->subYear()) {
            return $carbon->format('M j'); // Month Day
        } else {
            return $carbon->format('M j, Y'); // Month Day, Year
        }
    }
}
