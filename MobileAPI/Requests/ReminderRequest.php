<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Carbon\Carbon;

class ReminderRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true; // Authorization is handled in the controller
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $rules = [
            'name' => [
                'required',
                'string',
                'max:255',
                'min:3',
            ],
            'description' => [
                'nullable',
                'string',
                'max:1000',
            ],
            'date' => [
                'required',
                'date',
                'after_or_equal:now',
            ],
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
                ]),
            ],
            'model_id' => [
                'nullable',
                'integer',
                'min:1',
                'required_with:model_type',
            ],
        ];

        // For update requests, allow past dates (to maintain existing overdue reminders)
        if ($this->isMethod('PUT') || $this->isMethod('PATCH')) {
            $rules['date'] = [
                'required',
                'date',
            ];
        }

        return $rules;
    }

    /**
     * Get custom validation messages.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'name.required' => 'Reminder name is required',
            'name.string' => 'Reminder name must be a valid text',
            'name.max' => 'Reminder name cannot exceed 255 characters',
            'name.min' => 'Reminder name must be at least 3 characters',
            
            'description.string' => 'Description must be a valid text',
            'description.max' => 'Description cannot exceed 1000 characters',
            
            'date.required' => 'Reminder date and time is required',
            'date.date' => 'Please provide a valid date and time',
            'date.after_or_equal' => 'Reminder date cannot be in the past',
            
            'model_type.string' => 'Model type must be a valid text',
            'model_type.in' => 'Invalid model type selected',
            
            'model_id.integer' => 'Model ID must be a valid number',
            'model_id.min' => 'Model ID must be a positive number',
            'model_id.required_with' => 'Model ID is required when model type is specified',
        ];
    }

    /**
     * Get custom attributes for validator errors.
     *
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'name' => 'reminder name',
            'description' => 'description',
            'date' => 'reminder date',
            'model_type' => 'entity type',
            'model_id' => 'entity ID',
        ];
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        // Clean up and format the data before validation
        $data = [];

        // Trim whitespace from text fields
        if ($this->has('name')) {
            $data['name'] = trim($this->input('name'));
        }

        if ($this->has('description')) {
            $data['description'] = trim($this->input('description'));
        }

        // Convert date to proper format if needed
        if ($this->has('date')) {
            $date = $this->input('date');
            
            // Try to parse different date formats
            try {
                if (is_string($date)) {
                    $parsedDate = Carbon::parse($date);
                    $data['date'] = $parsedDate->format('Y-m-d H:i:s');
                }
            } catch (\Exception $e) {
                // Keep original value for validation to catch the error
                $data['date'] = $date;
            }
        }

        // Ensure model_id is integer if provided
        if ($this->has('model_id') && $this->input('model_id') !== null) {
            $data['model_id'] = (int) $this->input('model_id');
        }

        $this->merge($data);
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            // Additional custom validation
            $this->validateModelRelationship($validator);
            $this->validateDateLimits($validator);
        });
    }

    /**
     * Validate model relationship exists
     */
    protected function validateModelRelationship($validator): void
    {
        if ($this->filled('model_type') && $this->filled('model_id')) {
            $modelType = $this->input('model_type');
            $modelId = $this->input('model_id');
            
            try {
                // Check if the model exists and belongs to the user's business
                $user = $this->user();
                $businessId = $user->business_id;
                
                if (!class_exists($modelType)) {
                    $validator->errors()->add('model_type', 'Invalid model type specified');
                    return;
                }
                
                $model = $modelType::find($modelId);
                
                if (!$model) {
                    $validator->errors()->add('model_id', 'The specified entity does not exist');
                    return;
                }
                
                // Check if model has business_id and belongs to user's business
                if (method_exists($model, 'getAttribute') && $model->getAttribute('business_id')) {
                    if ($model->business_id != $businessId) {
                        $validator->errors()->add('model_id', 'You do not have access to this entity');
                        return;
                    }
                }
                
                // Special handling for Staff model (uses staff_id as primary key)
                if ($modelType === 'App\Modules\Customers\Models\Staff') {
                    if ($model->business_id != $businessId) {
                        $validator->errors()->add('model_id', 'You do not have access to this staff member');
                        return;
                    }
                }
                
            } catch (\Exception $e) {
                $validator->errors()->add('model_id', 'Error validating entity: ' . $e->getMessage());
            }
        }
    }

    /**
     * Validate date limits (not too far in the future)
     */
    protected function validateDateLimits($validator): void
    {
        if ($this->filled('date')) {
            try {
                $date = Carbon::parse($this->input('date'));
                
                // Don't allow reminders more than 5 years in the future
                if ($date->isAfter(now()->addYears(5))) {
                    $validator->errors()->add('date', 'Reminder date cannot be more than 5 years in the future');
                }
                
                // For new reminders, warn if more than 1 year in the future
                if ($this->isMethod('POST') && $date->isAfter(now()->addYear())) {
                    // This is just a warning, not an error - let it pass but could be logged
                    \Log::info('Reminder created with date more than 1 year in future', [
                        'date' => $date->toDateTimeString(),
                        'user_id' => $this->user()->staff_id ?? null,
                    ]);
                }
                
            } catch (\Exception $e) {
                // Date parsing will be handled by the main date validation rule
            }
        }
    }

    /**
     * Get validation data with additional computed fields
     */
    public function getValidationData(): array
    {
        $data = $this->validated();
        
        // Add computed fields that might be useful
        if (isset($data['date'])) {
            try {
                $date = Carbon::parse($data['date']);
                $data['computed'] = [
                    'is_today' => $date->isToday(),
                    'is_future' => $date->isFuture(),
                    'days_until' => $date->diffInDays(now(), false),
                    'formatted_date' => $date->format('Y-m-d H:i:s'),
                ];
            } catch (\Exception $e) {
                // Ignore computation errors
            }
        }
        
        return $data;
    }

    /**
     * Handle a failed validation attempt.
     */
    protected function failedValidation(\Illuminate\Contracts\Validation\Validator $validator): void
    {
        // Log validation failures for debugging
        \Log::warning('Reminder validation failed', [
            'errors' => $validator->errors()->toArray(),
            'input' => $this->except(['password', 'password_confirmation']),
            'user_id' => $this->user()->staff_id ?? null,
        ]);

        parent::failedValidation($validator);
    }
}
