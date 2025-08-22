<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmailSignatureResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'html_content' => $this->html_content,
            'text_content' => $this->text_content ?? strip_tags($this->html_content),
            'is_default' => $this->is_default,
            'is_active' => $this->is_active ?? true,
            
            // Preview information
            'preview_html' => $this->getPreviewHtml(),
            'preview_text' => $this->getPreviewText(),
            'snippet' => $this->getSnippet(),
            
            // Usage statistics
            'usage_count' => $this->usage_count ?? 0,
            'last_used' => $this->last_used?->toISOString(),
            
            // Content analysis
            'has_placeholders' => $this->hasPlaceholders(),
            'placeholder_count' => $this->getPlaceholderCount(),
            'placeholders_used' => $this->getPlaceholdersUsed(),
            'estimated_height' => $this->getEstimatedHeight(),
            'character_count' => $this->getCharacterCount(),
            
            // Template information
            'template_type' => $this->getTemplateType(),
            'style_info' => $this->getStyleInfo(),
            
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
     * Get preview HTML with placeholders replaced
     */
    private function getPreviewHtml(): string
    {
        $html = $this->html_content;
        
        // Replace placeholders with sample data for preview
        $placeholders = [
            '{{name}}' => 'John Doe',
            '{{first_name}}' => 'John',
            '{{last_name}}' => 'Doe',
            '{{email}}' => 'john.doe@company.com',
            '{{phone}}' => '+1 (555) 123-4567',
            '{{job_title}}' => 'Sales Manager',
            '{{company}}' => 'Company Name',
            '{{website}}' => 'www.company.com',
        ];
        
        foreach ($placeholders as $placeholder => $value) {
            $html = str_replace($placeholder, $value, $html);
        }
        
        return $html;
    }
    
    /**
     * Get preview text with placeholders replaced
     */
    private function getPreviewText(): string
    {
        return strip_tags($this->getPreviewHtml());
    }
    
    /**
     * Get a snippet of the signature for quick preview
     */
    private function getSnippet(int $length = 100): string
    {
        $text = strip_tags($this->html_content);
        $text = preg_replace('/\s+/', ' ', trim($text));
        
        if (strlen($text) <= $length) {
            return $text;
        }
        
        return substr($text, 0, $length) . '...';
    }
    
    /**
     * Check if signature contains placeholders
     */
    private function hasPlaceholders(): bool
    {
        return strpos($this->html_content, '{{') !== false;
    }
    
    /**
     * Count total placeholders in signature
     */
    private function getPlaceholderCount(): int
    {
        return substr_count($this->html_content, '{{');
    }
    
    /**
     * Get list of placeholders used in signature
     */
    private function getPlaceholdersUsed(): array
    {
        $content = $this->html_content;
        $placeholders = [];
        
        $availablePlaceholders = [
            '{{name}}' => 'Full Name',
            '{{first_name}}' => 'First Name',
            '{{last_name}}' => 'Last Name',
            '{{email}}' => 'Email Address',
            '{{phone}}' => 'Phone Number',
            '{{job_title}}' => 'Job Title',
            '{{company}}' => 'Company Name',
            '{{website}}' => 'Website',
        ];
        
        foreach ($availablePlaceholders as $placeholder => $label) {
            if (strpos($content, $placeholder) !== false) {
                $placeholders[] = [
                    'placeholder' => $placeholder,
                    'label' => $label,
                    'count' => substr_count($content, $placeholder),
                ];
            }
        }
        
        return $placeholders;
    }
    
    /**
     * Estimate signature height in pixels (rough calculation)
     */
    private function getEstimatedHeight(): int
    {
        $content = $this->html_content;
        
        // Count line breaks
        $lineBreaks = substr_count($content, '<br>') + substr_count($content, '<br/>') + substr_count($content, '<br />');
        $paragraphs = substr_count($content, '<p>');
        $divs = substr_count($content, '<div>');
        
        // Rough estimation: each line ~20px, paragraphs add extra spacing
        $estimatedLines = max(1, $lineBreaks + $paragraphs + $divs);
        $baseHeight = $estimatedLines * 20;
        
        // Add extra height for styling elements
        if (strpos($content, 'style=') !== false) {
            $baseHeight += 20; // Extra padding/margin from styles
        }
        
        return min(300, max(50, $baseHeight)); // Cap between 50-300px
    }
    
    /**
     * Get character count of signature content
     */
    private function getCharacterCount(): array
    {
        $htmlCount = strlen($this->html_content);
        $textCount = strlen(strip_tags($this->html_content));
        
        return [
            'html' => $htmlCount,
            'text' => $textCount,
            'ratio' => $textCount > 0 ? round($htmlCount / $textCount, 2) : 0,
        ];
    }
    
    /**
     * Determine template type based on content analysis
     */
    private function getTemplateType(): string
    {
        $content = $this->html_content;
        
        if (strpos($content, '<table') !== false) {
            return 'table-based';
        } elseif (strpos($content, 'linear-gradient') !== false || strpos($content, 'background') !== false) {
            return 'modern';
        } elseif (strpos($content, 'border-left') !== false || strpos($content, 'border:') !== false) {
            return 'bordered';
        } elseif (strpos($content, '<div') === false && strpos($content, '<span') === false) {
            return 'simple-text';
        } else {
            return 'custom';
        }
    }
    
    /**
     * Extract style information from signature
     */
    private function getStyleInfo(): array
    {
        $content = $this->html_content;
        $styleInfo = [
            'has_colors' => false,
            'has_images' => false,
            'has_links' => false,
            'has_tables' => false,
            'has_custom_fonts' => false,
            'dominant_colors' => [],
            'font_families' => [],
        ];
        
        // Check for colors
        if (preg_match_all('/color:\s*([^;]+)/i', $content, $matches)) {
            $styleInfo['has_colors'] = true;
            $styleInfo['dominant_colors'] = array_unique($matches[1]);
        }
        
        // Check for images
        $styleInfo['has_images'] = strpos($content, '<img') !== false;
        
        // Check for links
        $styleInfo['has_links'] = strpos($content, '<a') !== false;
        
        // Check for tables
        $styleInfo['has_tables'] = strpos($content, '<table') !== false;
        
        // Check for custom fonts
        if (preg_match_all('/font-family:\s*([^;]+)/i', $content, $matches)) {
            $styleInfo['has_custom_fonts'] = true;
            $styleInfo['font_families'] = array_unique($matches[1]);
        }
        
        return $styleInfo;
    }
}
