<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class EmailSignatureRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true; // Authorization handled by Sanctum middleware
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        $signatureId = $this->route('id'); // For update requests
        $businessId = $this->user()->business_id;

        return [
            'name' => [
                'required',
                'string',
                'max:100',
                Rule::unique('email_signatures')
                    ->where('business_id', $businessId)
                    ->where('user_id', $this->user()->id)
                    ->ignore($signatureId),
            ],
            'html_content' => [
                'required',
                'string',
                'max:10000', // 10KB limit for HTML content
            ],
            'text_content' => [
                'nullable',
                'string',
                'max:5000', // 5KB limit for text content
            ],
            'is_default' => [
                'boolean',
            ],
            'is_active' => [
                'boolean',
            ],
        ];
    }

    /**
     * Get custom messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'name.required' => 'Signature name is required.',
            'name.unique' => 'You already have a signature with this name.',
            'name.max' => 'Signature name cannot exceed 100 characters.',
            'html_content.required' => 'Signature content is required.',
            'html_content.max' => 'Signature content cannot exceed 10,000 characters.',
            'text_content.max' => 'Text content cannot exceed 5,000 characters.',
        ];
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            // Validate HTML content for basic security
            $htmlContent = $this->input('html_content');
            if ($htmlContent) {
                // Check for potentially dangerous tags
                $dangerousTags = ['<script', '<iframe', '<object', '<embed', '<form'];
                foreach ($dangerousTags as $tag) {
                    if (stripos($htmlContent, $tag) !== false) {
                        $validator->errors()->add('html_content', 'HTML content contains potentially unsafe elements.');
                        break;
                    }
                }

                // Check for javascript events
                $jsEvents = ['onclick', 'onload', 'onerror', 'onmouseover'];
                foreach ($jsEvents as $event) {
                    if (stripos($htmlContent, $event) !== false) {
                        $validator->errors()->add('html_content', 'HTML content contains JavaScript events which are not allowed.');
                        break;
                    }
                }
            }

            // Validate placeholder syntax
            if ($htmlContent && strpos($htmlContent, '{{') !== false) {
                $this->validatePlaceholders($htmlContent, $validator);
            }

            // If setting as default, ensure user doesn't exceed limits
            if ($this->input('is_default') && $this->isMethod('POST')) {
                $this->validateDefaultSignatureLimit($validator);
            }
        });
    }

    /**
     * Validate placeholder syntax in signature content
     */
    private function validatePlaceholders(string $content, $validator): void
    {
        $validPlaceholders = [
            '{{name}}', '{{first_name}}', '{{last_name}}', '{{email}}',
            '{{phone}}', '{{job_title}}', '{{company}}', '{{website}}'
        ];

        // Find all placeholders in content
        preg_match_all('/\{\{[^}]+\}\}/', $content, $matches);
        
        foreach ($matches[0] as $placeholder) {
            if (!in_array($placeholder, $validPlaceholders)) {
                $validator->errors()->add('html_content', "Invalid placeholder: {$placeholder}. Valid placeholders are: " . implode(', ', $validPlaceholders));
            }
        }
    }

    /**
     * Validate default signature limits
     */
    private function validateDefaultSignatureLimit($validator): void
    {
        $businessId = $this->user()->business_id;
        $userId = $this->user()->id;

        // Check if user already has a default signature
        $hasDefault = \App\Modules\Emails\Models\EmailSignature::forBusiness($businessId)
            ->forUser($userId)
            ->where('is_default', true)
            ->exists();

        if ($hasDefault) {
            // This is fine - we'll update the existing default in the controller
            return;
        }

        // Check total signature count limits (optional business rule)
        $totalSignatures = \App\Modules\Emails\Models\EmailSignature::forBusiness($businessId)
            ->forUser($userId)
            ->count();

        if ($totalSignatures >= 10) { // Max 10 signatures per user
            $validator->errors()->add('general', 'You have reached the maximum limit of 10 email signatures.');
        }
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        // Auto-generate text content if not provided
        if ($this->has('html_content') && !$this->has('text_content')) {
            $this->merge([
                'text_content' => strip_tags($this->input('html_content'))
            ]);
        }

        // Set default values
        $this->merge([
            'is_default' => $this->boolean('is_default'),
            'is_active' => $this->boolean('is_active', true), // Default to active
        ]);
    }

    /**
     * Get validated data with additional processing
     */
    public function getValidatedData(): array
    {
        $data = $this->validated();

        // Clean HTML content
        if (isset($data['html_content'])) {
            $data['html_content'] = $this->cleanHtmlContent($data['html_content']);
        }

        // Ensure text content is generated
        if (isset($data['html_content']) && empty($data['text_content'])) {
            $data['text_content'] = strip_tags($data['html_content']);
        }

        return $data;
    }

    /**
     * Clean HTML content for security
     */
    private function cleanHtmlContent(string $html): string
    {
        // Remove potentially dangerous attributes
        $html = preg_replace('/\s(on\w+)=["\'][^"\']*["\']/i', '', $html);
        
        // Remove script tags and their content
        $html = preg_replace('/<script[^>]*>.*?<\/script>/is', '', $html);
        
        // Remove javascript: URLs
        $html = preg_replace('/javascript:[^"\'\s>]*/i', '', $html);
        
        return trim($html);
    }
}
