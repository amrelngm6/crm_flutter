<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class TodoRequest extends FormRequest
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
        $todoId = $this->route('todo');

        return [
            'description' => 'required|string|max:255',
            'date' => 'nullable|date|after_or_equal:today',
            'priority_id' => 'nullable|exists:priorities,priority_id',
            'status_id' => 'nullable|integer|in:0,1', // 0 = pending, 1 = completed
            'sort' => 'nullable|integer|min:1',
        ];
    }

    /**
     * Get custom validation messages.
     */
    public function messages(): array
    {
        return [
            'description.required' => 'The todo description is required.',
            'description.max' => 'The todo description cannot exceed 255 characters.',
            'date.date' => 'The due date must be a valid date.',
            'date.after_or_equal' => 'The due date cannot be in the past.',
            'priority_id.exists' => 'The selected priority is invalid.',
            'status_id.integer' => 'The status must be a valid integer.',
            'status_id.in' => 'The status must be either pending (0) or completed (1).',
            'sort.integer' => 'The sort order must be a valid integer.',
            'sort.min' => 'The sort order must be at least 1.',
        ];
    }

    /**
     * Get custom attributes for validator errors.
     */
    public function attributes(): array
    {
        return [
            'description' => 'todo description',
            'date' => 'due date',
            'priority_id' => 'priority',
            'status_id' => 'completion status',
            'sort' => 'sort order',
        ];
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        // Set default status if not provided (0 = pending)
        if (!$this->has('status_id')) {
            $this->merge(['status_id' => 0]);
        }

        // Set today's date if no date provided
        if (!$this->has('date') || empty($this->date)) {
            $this->merge(['date' => today()->format('Y-m-d')]);
        }

        // Clean up description
        if ($this->has('description')) {
            $this->merge([
                'description' => trim($this->description)
            ]);
        }
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            // Custom business logic validation
            
            // Validate priority belongs to the same business and is for Todo model
            if ($this->priority_id) {
                $user = $this->user();
                $priority = \App\Modules\Priorities\Models\Priority::find($this->priority_id);
                
                if ($priority) {
                    // Check if priority is for Todo model
                    if ($priority->model !== \App\Modules\Todos\Models\Todo::class) {
                        $validator->errors()->add('priority_id', 'The selected priority is not valid for todos.');
                    }
                    
                    // Check business scope
                    if (!in_array($user->business_id, [$priority->business_id ?? 0, 0]) && $priority->business_id > 0) {
                        $validator->errors()->add('priority_id', 'The selected priority does not belong to your business.');
                    }
                }
            }

            // Validate description is not empty after trimming
            if ($this->description && empty(trim($this->description))) {
                $validator->errors()->add('description', 'The todo description cannot be empty.');
            }
        });
    }
}
