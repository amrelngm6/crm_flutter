<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Carbon\Carbon;

class GoalRequest extends FormRequest
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
        return [
            'title' => [
                'required',
                'string',
                'max:255',
                'min:3',
            ],
            'description' => [
                'nullable',
                'string',
                'max:2000',
            ],
            'status' => [
                'sometimes',
                'string',
                Rule::in(['active', 'completed', 'on_hold', 'cancelled', 'archived']),
            ],
            'due_date' => [
                'nullable',
                'date',
                'after_or_equal:today',
            ],
            'project_id' => [
                'nullable',
                'integer',
                'min:1',
                'exists:projects,id',
            ],
            'deal_id' => [
                'nullable',
                'integer',
                'min:1',
                'exists:deals,id',
            ],
            'task_id' => [
                'nullable',
                'integer',
                'min:1',
                'exists:tasks,id',
            ],
        ];
    }

    /**
     * Get custom validation messages.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'title.required' => 'Goal title is required',
            'title.string' => 'Goal title must be a valid text',
            'title.max' => 'Goal title cannot exceed 255 characters',
            'title.min' => 'Goal title must be at least 3 characters',
            
            'description.string' => 'Description must be a valid text',
            'description.max' => 'Description cannot exceed 2000 characters',
            
            'status.string' => 'Status must be a valid text',
            'status.in' => 'Invalid status. Must be one of: active, completed, on_hold, cancelled, archived',
            
            'due_date.date' => 'Please provide a valid due date',
            'due_date.after_or_equal' => 'Due date cannot be in the past',
            
            'project_id.integer' => 'Project ID must be a valid number',
            'project_id.min' => 'Project ID must be a positive number',
            'project_id.exists' => 'Selected project does not exist',
            
            'deal_id.integer' => 'Deal ID must be a valid number',
            'deal_id.min' => 'Deal ID must be a positive number',
            'deal_id.exists' => 'Selected deal does not exist',
            
            'task_id.integer' => 'Task ID must be a valid number',
            'task_id.min' => 'Task ID must be a positive number',
            'task_id.exists' => 'Selected task does not exist',
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
            'title' => 'goal title',
            'description' => 'description',
            'status' => 'status',
            'due_date' => 'due date',
            'project_id' => 'project',
            'deal_id' => 'deal',
            'task_id' => 'task',
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
        if ($this->has('title')) {
            $data['title'] = trim($this->input('title'));
        }

        if ($this->has('description')) {
            $data['description'] = trim($this->input('description'));
        }

        // Normalize status to lowercase
        if ($this->has('status')) {
            $data['status'] = strtolower(trim($this->input('status')));
        }

        // Convert due_date to proper format if needed
        if ($this->has('due_date') && $this->input('due_date')) {
            $dueDate = $this->input('due_date');
            
            // Try to parse different date formats
            try {
                if (is_string($dueDate)) {
                    $parsedDate = Carbon::parse($dueDate);
                    $data['due_date'] = $parsedDate->format('Y-m-d H:i:s');
                }
            } catch (\Exception $e) {
                // Keep original value for validation to catch the error
                $data['due_date'] = $dueDate;
            }
        }

        // Ensure integer fields are properly cast
        foreach (['project_id', 'deal_id', 'task_id'] as $field) {
            if ($this->has($field) && $this->input($field) !== null) {
                $data[$field] = (int) $this->input($field);
            }
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
            $this->validateRelatedEntities($validator);
            $this->validateStatusTransitions($validator);
            $this->validateDateLimits($validator);
        });
    }

    /**
     * Validate related entities belong to user's business
     */
    protected function validateRelatedEntities($validator): void
    {
        $user = $this->user();
        $businessId = $user->business_id;

        // Validate project belongs to business
        if ($this->filled('project_id')) {
            $project = \App\Modules\Projects\Models\Project::find($this->input('project_id'));
            if ($project && $project->business_id != $businessId) {
                $validator->errors()->add('project_id', 'You do not have access to this project');
            }
        }

        // Validate deal belongs to business
        if ($this->filled('deal_id')) {
            $deal = \App\Modules\Deals\Models\Deal::find($this->input('deal_id'));
            if ($deal && $deal->business_id != $businessId) {
                $validator->errors()->add('deal_id', 'You do not have access to this deal');
            }
        }

        // Validate task belongs to business
        if ($this->filled('task_id')) {
            $task = \App\Modules\Tasks\Models\Task::find($this->input('task_id'));
            if ($task && $task->business_id != $businessId) {
                $validator->errors()->add('task_id', 'You do not have access to this task');
            }
        }
    }

    /**
     * Validate status transitions (for updates)
     */
    protected function validateStatusTransitions($validator): void
    {
        if ($this->isMethod('PUT') || $this->isMethod('PATCH')) {
            $currentStatus = null;
            
            // Get current status from route parameter
            $goalId = $this->route('goal');
            if ($goalId) {
                try {
                    $goal = \App\Modules\Goals\Models\Goal::find($goalId);
                    $currentStatus = $goal->status ?? null;
                } catch (\Exception $e) {
                    // Goal might not exist, let the controller handle it
                }
            }

            $newStatus = $this->input('status');
            
            if ($currentStatus && $newStatus && $currentStatus !== $newStatus) {
                // Define allowed status transitions
                $allowedTransitions = [
                    'active' => ['completed', 'on_hold', 'cancelled'],
                    'completed' => ['active', 'archived'],
                    'on_hold' => ['active', 'cancelled'],
                    'cancelled' => ['active'],
                    'archived' => [], // Cannot transition from archived
                ];

                if (isset($allowedTransitions[$currentStatus])) {
                    if (!in_array($newStatus, $allowedTransitions[$currentStatus])) {
                        $validator->errors()->add('status', "Cannot change status from '{$currentStatus}' to '{$newStatus}'");
                    }
                }
            }

            // Special validation for completed status
            if ($newStatus === 'completed' && $this->filled('due_date')) {
                $dueDate = Carbon::parse($this->input('due_date'));
                if ($dueDate->isFuture()) {
                    $validator->errors()->add('status', 'Cannot mark goal as completed with a future due date');
                }
            }
        }
    }

    /**
     * Validate date limits
     */
    protected function validateDateLimits($validator): void
    {
        if ($this->filled('due_date')) {
            try {
                $dueDate = Carbon::parse($this->input('due_date'));
                
                // Don't allow due dates more than 10 years in the future
                if ($dueDate->isAfter(now()->addYears(10))) {
                    $validator->errors()->add('due_date', 'Due date cannot be more than 10 years in the future');
                }
                
                // Warn if more than 2 years in the future (but don't block)
                if ($dueDate->isAfter(now()->addYears(2))) {
                    \Log::info('Goal created with due date more than 2 years in future', [
                        'due_date' => $dueDate->toDateTimeString(),
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
        if (isset($data['due_date'])) {
            try {
                $dueDate = Carbon::parse($data['due_date']);
                $data['computed'] = [
                    'is_today' => $dueDate->isToday(),
                    'is_future' => $dueDate->isFuture(),
                    'days_until_due' => $dueDate->diffInDays(now(), false),
                    'formatted_due_date' => $dueDate->format('Y-m-d H:i:s'),
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
        \Log::warning('Goal validation failed', [
            'errors' => $validator->errors()->toArray(),
            'input' => $this->except(['password', 'password_confirmation']),
            'user_id' => $this->user()->staff_id ?? null,
        ]);

        parent::failedValidation($validator);
    }
}
