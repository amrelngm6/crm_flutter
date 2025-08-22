<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CommentRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'message' => 'required|string|max:2000',
            'model_id' => 'nullable|integer',
            'model_type' => [
                'nullable',
                'string',
                Rule::in([
                    'App\Modules\Leads\Models\Lead',
                    'App\Modules\Projects\Models\Project',
                    'App\Modules\Tasks\Models\Task',
                    'App\Modules\Deals\Models\Deal',
                    'App\Modules\Tickets\Models\Ticket',
                    'App\Modules\Customers\Models\Staff',
                    'App\Modules\Proposals\Models\Proposal',
                    'App\Modules\Estimates\Models\Estimate',
                ])
            ],
            'status_id' => 'nullable|integer|in:1,2,3',
        ];
    }

    /**
     * Get custom validation messages.
     */
    public function messages(): array
    {
        return [
            'message.required' => 'Comment message is required.',
            'message.string' => 'Comment message must be a valid text.',
            'message.max' => 'Comment message cannot exceed 2000 characters.',
            'model_id.integer' => 'Model ID must be a valid number.',
            'model_type.in' => 'Invalid model type. Must be a valid module model.',
            'status_id.in' => 'Invalid status. Must be one of: Active (1), Pending (2), Hidden (3).',
        ];
    }

    /**
     * Get custom validation attributes.
     */
    public function attributes(): array
    {
        return [
            'message' => 'comment message',
            'model_id' => 'related item ID',
            'model_type' => 'related item type',
            'status_id' => 'comment status',
        ];
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $this->validateModelExists($validator);
            $this->validateCommentContent($validator);
        });
    }

    /**
     * Validate that the related model exists if specified
     */
    private function validateModelExists($validator): void
    {
        if ($this->model_id && $this->model_type) {
            try {
                $modelClass = $this->model_type;
                
                if (!class_exists($modelClass)) {
                    $validator->errors()->add('model_type', 'Invalid model type specified.');
                    return;
                }

                // Get the primary key name for the model
                $model = new $modelClass();
                $primaryKey = $model->getKeyName();
                
                // Check if the model exists
                $exists = $modelClass::where($primaryKey, $this->model_id)->exists();
                
                if (!$exists) {
                    $validator->errors()->add('model_id', 'The selected item does not exist.');
                }

                // For business-scoped models, ensure they belong to the user's business
                if (method_exists($model, 'forBusiness')) {
                    $user = $this->user();
                    if ($user && isset($user->business_id)) {
                        $exists = $modelClass::forBusiness($user->business_id)
                                            ->where($primaryKey, $this->model_id)
                                            ->exists();
                        
                        if (!$exists) {
                            $validator->errors()->add('model_id', 'The selected item is not accessible.');
                        }
                    }
                }

            } catch (\Exception $e) {
                $validator->errors()->add('model_type', 'Error validating related item.');
            }
        } elseif ($this->model_id && !$this->model_type) {
            $validator->errors()->add('model_type', 'Model type is required when model ID is specified.');
        } elseif (!$this->model_id && $this->model_type) {
            $validator->errors()->add('model_id', 'Model ID is required when model type is specified.');
        }
    }

    /**
     * Validate comment content
     */
    private function validateCommentContent($validator): void
    {
        if ($this->message) {
            // Check for minimum meaningful content
            $trimmed = trim($this->message);
            if (strlen($trimmed) < 5) {
                $validator->errors()->add('message', 'Comment message must be at least 5 characters long.');
            }

            // Check for excessive repetition (basic spam detection)
            if ($this->hasExcessiveRepetition($trimmed)) {
                $validator->errors()->add('message', 'Comment message contains excessive repetition.');
            }

            // Check for HTML tags (basic security)
            if ($trimmed !== strip_tags($trimmed)) {
                $validator->errors()->add('message', 'HTML tags are not allowed in comment message.');
            }

            // Check for excessive caps (shouting)
            if ($this->hasExcessiveCaps($trimmed)) {
                $validator->errors()->add('message', 'Please avoid excessive use of capital letters.');
            }
        }
    }

    /**
     * Check for excessive character repetition
     */
    private function hasExcessiveRepetition(string $text): bool
    {
        // Check for more than 5 consecutive identical characters
        if (preg_match('/(.)\1{5,}/', $text)) {
            return true;
        }

        // Check for more than 3 consecutive identical words
        $words = explode(' ', $text);
        $consecutiveCount = 1;
        $previousWord = '';
        
        foreach ($words as $word) {
            if (strtolower($word) === strtolower($previousWord)) {
                $consecutiveCount++;
                if ($consecutiveCount > 3) {
                    return true;
                }
            } else {
                $consecutiveCount = 1;
            }
            $previousWord = $word;
        }

        return false;
    }

    /**
     * Check for excessive capital letters
     */
    private function hasExcessiveCaps(string $text): bool
    {
        if (strlen($text) < 10) {
            return false; // Don't check short texts
        }

        $uppercaseCount = 0;
        $letterCount = 0;
        
        for ($i = 0; $i < strlen($text); $i++) {
            $char = $text[$i];
            if (ctype_alpha($char)) {
                $letterCount++;
                if (ctype_upper($char)) {
                    $uppercaseCount++;
                }
            }
        }

        // If more than 70% of letters are uppercase, consider it excessive
        return $letterCount > 0 && ($uppercaseCount / $letterCount) > 0.7;
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        // Convert empty strings to null
        $input = $this->all();
        
        foreach (['model_id', 'model_type', 'status_id'] as $field) {
            if (isset($input[$field]) && $input[$field] === '') {
                $input[$field] = null;
            }
        }

        // Trim message
        if (isset($input['message'])) {
            $input['message'] = trim($input['message']);
        }

        $this->replace($input);
    }

    /**
     * Get the validated data with defaults
     */
    public function validatedWithDefaults(): array
    {
        $validated = $this->validated();
        
        // Set default status if not provided
        if (!isset($validated['status_id'])) {
            $validated['status_id'] = 1; // Active
        }
        
        return $validated;
    }
}
