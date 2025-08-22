<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmailAccountResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'type' => $this->type,
            'server_type' => $this->server_type,
            'host' => $this->host,
            'port' => $this->port,
            'encryption' => $this->encryption,
            'username' => $this->username,
            'is_active' => $this->is_active,
            'is_default' => $this->is_default,
            'last_sync' => $this->last_sync?->toISOString(),
            'sync_status' => $this->sync_status,
            'sync_error' => $this->sync_error,
            
            // SMTP Settings (if applicable)
            'smtp_host' => $this->smtp_host,
            'smtp_port' => $this->smtp_port,
            'smtp_encryption' => $this->smtp_encryption,
            'smtp_username' => $this->smtp_username,
            
            // Connection status
            'connection_status' => $this->getConnectionStatus(),
            'last_connection_test' => $this->last_connection_test?->toISOString(),
            
            // Statistics
            'stats' => [
                'total_messages' => $this->whenLoaded('messages', function() {
                    return $this->messages->count();
                }),
                'unread_messages' => $this->whenLoaded('messages', function() {
                    return $this->messages->where('is_read', false)->count();
                }),
                'recent_messages' => $this->whenLoaded('messages', function() {
                    return $this->messages->where('created_at', '>=', now()->subDays(7))->count();
                }),
            ],
            
            // User information
            'user' => [
                'id' => $this->user_id,
                'name' => $this->whenLoaded('user', function() {
                    return $this->user->name;
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
     * Get connection status based on last sync and errors
     */
    private function getConnectionStatus(): string
    {
        if (!$this->is_active) {
            return 'inactive';
        }
        
        if ($this->sync_error) {
            return 'error';
        }
        
        if (!$this->last_sync) {
            return 'never_synced';
        }
        
        // Consider connection stale if last sync was more than 24 hours ago
        if ($this->last_sync < now()->subHours(24)) {
            return 'stale';
        }
        
        return 'connected';
    }
}
