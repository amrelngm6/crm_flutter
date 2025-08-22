<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmailAttachmentResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'message_id' => $this->message_id,
            'filename' => $this->filename,
            'original_filename' => $this->original_filename ?? $this->filename,
            'mime_type' => $this->mime_type,
            'size' => $this->size,
            'size_human' => $this->getHumanReadableSize(),
            'file_path' => $this->file_path,
            'content_id' => $this->content_id,
            'is_inline' => $this->is_inline ?? false,
            'disposition' => $this->disposition ?? 'attachment',
            
            // File type information
            'file_extension' => $this->getFileExtension(),
            'file_type' => $this->getFileType(),
            'file_category' => $this->getFileCategory(),
            
            // Preview capabilities
            'is_previewable' => $this->isPreviewable(),
            'is_image' => $this->isImage(),
            'is_document' => $this->isDocument(),
            'is_archive' => $this->isArchive(),
            'is_video' => $this->isVideo(),
            'is_audio' => $this->isAudio(),
            
            // Download information
            'download_url' => $this->getDownloadUrl(),
            'preview_url' => $this->isPreviewable() ? $this->getPreviewUrl() : null,
            
            // Security information
            'is_safe' => $this->isSafeFileType(),
            'security_warning' => $this->getSecurityWarning(),
            
            // Thumbnails for images
            'thumbnail_url' => $this->isImage() ? $this->getThumbnailUrl() : null,
            
            // Business information
            'business_id' => $this->business_id,
            
            // Timestamps
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
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
     * Get file extension
     */
    private function getFileExtension(): string
    {
        return strtolower(pathinfo($this->filename, PATHINFO_EXTENSION));
    }
    
    /**
     * Get file type based on mime type
     */
    private function getFileType(): string
    {
        $mimeType = $this->mime_type;
        
        if (strpos($mimeType, 'image/') === 0) {
            return 'image';
        } elseif (strpos($mimeType, 'video/') === 0) {
            return 'video';
        } elseif (strpos($mimeType, 'audio/') === 0) {
            return 'audio';
        } elseif (strpos($mimeType, 'text/') === 0) {
            return 'text';
        } elseif (in_array($mimeType, [
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/vnd.ms-powerpoint',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation'
        ])) {
            return 'document';
        } elseif (in_array($mimeType, [
            'application/zip',
            'application/x-rar-compressed',
            'application/x-tar',
            'application/gzip'
        ])) {
            return 'archive';
        }
        
        return 'other';
    }
    
    /**
     * Get file category for grouping
     */
    private function getFileCategory(): string
    {
        $type = $this->getFileType();
        
        switch ($type) {
            case 'image':
                return 'Images';
            case 'video':
                return 'Videos';
            case 'audio':
                return 'Audio';
            case 'document':
                return 'Documents';
            case 'archive':
                return 'Archives';
            case 'text':
                return 'Text Files';
            default:
                return 'Other Files';
        }
    }
    
    /**
     * Check if file is previewable
     */
    private function isPreviewable(): bool
    {
        $previewableMimes = [
            'image/jpeg', 'image/png', 'image/gif', 'image/webp',
            'text/plain', 'text/html', 'text/css', 'text/javascript',
            'application/pdf'
        ];
        
        return in_array($this->mime_type, $previewableMimes);
    }
    
    /**
     * Check if file is an image
     */
    private function isImage(): bool
    {
        return strpos($this->mime_type, 'image/') === 0;
    }
    
    /**
     * Check if file is a document
     */
    private function isDocument(): bool
    {
        $documentMimes = [
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/vnd.ms-powerpoint',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'text/plain',
            'text/html',
            'text/csv'
        ];
        
        return in_array($this->mime_type, $documentMimes);
    }
    
    /**
     * Check if file is an archive
     */
    private function isArchive(): bool
    {
        $archiveMimes = [
            'application/zip',
            'application/x-rar-compressed',
            'application/x-tar',
            'application/gzip',
            'application/x-7z-compressed'
        ];
        
        return in_array($this->mime_type, $archiveMimes);
    }
    
    /**
     * Check if file is a video
     */
    private function isVideo(): bool
    {
        return strpos($this->mime_type, 'video/') === 0;
    }
    
    /**
     * Check if file is audio
     */
    private function isAudio(): bool
    {
        return strpos($this->mime_type, 'audio/') === 0;
    }
    
    /**
     * Check if file type is considered safe
     */
    private function isSafeFileType(): bool
    {
        $unsafeMimes = [
            'application/x-executable',
            'application/x-msdownload',
            'application/x-msdos-program',
            'application/x-msi',
            'application/x-sh',
            'application/x-csh',
            'text/x-script',
            'application/javascript',
            'application/x-javascript'
        ];
        
        $unsafeExtensions = ['exe', 'bat', 'cmd', 'com', 'pif', 'scr', 'vbs', 'js'];
        
        return !in_array($this->mime_type, $unsafeMimes) && 
               !in_array($this->getFileExtension(), $unsafeExtensions);
    }
    
    /**
     * Get security warning if applicable
     */
    private function getSecurityWarning(): ?string
    {
        if (!$this->isSafeFileType()) {
            return 'This file type may contain executable code. Please verify the source before opening.';
        }
        
        if ($this->size > 50 * 1024 * 1024) { // 50MB
            return 'Large file size - please ensure you have sufficient storage space.';
        }
        
        return null;
    }
    
    /**
     * Get download URL
     */
    private function getDownloadUrl(): string
    {
        return route('mobile-api.email-attachments.download', [
            'messageId' => $this->message_id,
            'attachmentId' => $this->id
        ]);
    }
    
    /**
     * Get preview URL
     */
    private function getPreviewUrl(): string
    {
        return route('mobile-api.email-attachments.preview', [
            'messageId' => $this->message_id,
            'attachmentId' => $this->id
        ]);
    }
    
    /**
     * Get thumbnail URL for images
     */
    private function getThumbnailUrl(): ?string
    {
        if (!$this->isImage()) {
            return null;
        }
        
        // This would typically generate a thumbnail URL
        // For now, we'll use the preview URL
        return $this->getPreviewUrl();
    }
}
