<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class NoteRequest extends FormRequest
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
            'description' => 'required|string|max:2000',
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
        ];
    }

    /**
     * Get custom validation messages.
     */
    public function messages(): array
    {
        return [
            'description.required' => 'Note description is required.',
            'description.string' => 'Note description must be a valid text.',
            'description.max' => 'Note description cannot exceed 2000 characters.',
            'model_id.integer' => 'Model ID must be a valid number.',
            'model_type.in' => 'Invalid model type. Must be a valid module model.',
        ];
    }

    /**
     * Get custom validation attributes.
     */
    public function attributes(): array
    {
        return [
            'description' => 'note description',
            'model_id' => 'related item ID',
            'model_type' => 'related item type',
        ];
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $this->validateModelExists($validator);
            $this->validateNoteContent($validator);
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
     * Validate note content
     */
    private function validateNoteContent($validator): void
    {
        if ($this->description) {
            // Check for minimum meaningful content
            $trimmed = trim($this->description);
            if (strlen($trimmed) < 10) {
                $validator->errors()->add('description', 'Note description must be at least 10 characters long.');
            }

            // Check for excessive repetition (basic spam detection)
            if ($this->hasExcessiveRepetition($trimmed)) {
                $validator->errors()->add('description', 'Note description contains excessive repetition.');
            }

            // Check for HTML tags (basic security)
            if ($trimmed !== strip_tags($trimmed)) {
                $validator->errors()->add('description', 'HTML tags are not allowed in note description.');
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
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        // Convert empty strings to null
        $input = $this->all();
        
        foreach (['model_id', 'model_type'] as $field) {
            if (isset($input[$field]) && $input[$field] === '') {
                $input[$field] = null;
            }
        }

        // Trim description
        if (isset($input['description'])) {
            $input['description'] = trim($input['description']);
        }

        $this->replace($input);
    }

    /**
     * Get the validated data with defaults
     */
    public function validatedWithDefaults(): array
    {
        $validated = $this->validated();
        
        // Add any default values here if needed
        
        return $validated;
    }
}
