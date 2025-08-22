<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Carbon\Carbon;

class TimesheetRequest extends FormRequest
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
        $rules = [
            'user_id' => 'nullable|integer|exists:staffs,staff_id',
            'user_type' => 'nullable|string|in:App\Modules\Customers\Models\Staff',
            'model_id' => 'nullable|integer',
            'model_type' => [
                'nullable',
                'string',
                Rule::in([
                    'App\Modules\Tasks\Models\Task',
                    'App\Modules\Projects\Models\Project', 
                    'App\Modules\Deals\Models\Deal',
                    'App\Modules\Tickets\Models\Ticket',
                    'App\Modules\Proposals\Models\Proposal',
                    'App\Modules\Estimates\Models\Estimate',
                ])
            ],
            'start' => 'required|date|before_or_equal:now',
            'end' => 'nullable|date|after:start',
            'notes' => 'nullable|string|max:1000',
            'status_id' => 'nullable|integer|exists:statuses,status_id',
        ];

        // For update requests, make start optional
        if ($this->isMethod('PUT') || $this->isMethod('PATCH')) {
            $rules['start'] = 'nullable|date|before_or_equal:now';
        }

        return $rules;
    }

    /**
     * Get custom validation messages.
     */
    public function messages(): array
    {
        return [
            'user_id.exists' => 'The selected staff member does not exist.',
            'user_type.in' => 'Invalid user type specified.',
            'model_id.integer' => 'Model ID must be a valid number.',
            'model_type.in' => 'Invalid model type. Must be a valid module model.',
            'start.required' => 'Start time is required.',
            'start.date' => 'Start time must be a valid date.',
            'start.before_or_equal' => 'Start time cannot be in the future.',
            'end.date' => 'End time must be a valid date.',
            'end.after' => 'End time must be after start time.',
            'notes.max' => 'Notes cannot exceed 1000 characters.',
            'status_id.exists' => 'The selected status does not exist.',
        ];
    }

    /**
     * Get custom validation attributes.
     */
    public function attributes(): array
    {
        return [
            'user_id' => 'staff member',
            'user_type' => 'user type',
            'model_id' => 'related item ID',
            'model_type' => 'related item type',
            'start' => 'start time',
            'end' => 'end time',
            'notes' => 'notes',
            'status_id' => 'status',
        ];
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $this->validateTimesheetLogic($validator);
            $this->validateModelExists($validator);
            $this->validateBusinessHours($validator);
        });
    }

    /**
     * Validate timesheet business logic
     */
    private function validateTimesheetLogic($validator): void
    {
        // If both start and end are provided, ensure duration is reasonable
        if ($this->start && $this->end) {
            $start = Carbon::parse($this->start);
            $end = Carbon::parse($this->end);
            
            $durationHours = $end->diffInHours($start);
            
            // Maximum 24 hours per entry
            if ($durationHours > 24) {
                $validator->errors()->add('end', 'Timesheet duration cannot exceed 24 hours.');
            }
            
            // Minimum 1 minute
            if ($end->diffInMinutes($start) < 1) {
                $validator->errors()->add('end', 'Timesheet duration must be at least 1 minute.');
            }
        }

        // For updates, check if trying to modify a completed timesheet inappropriately
        if ($this->isMethod('PUT') || $this->isMethod('PATCH')) {
            $timesheetId = $this->route('timesheet') ?? $this->route('id');
            
            if ($timesheetId) {
                try {
                    $timesheet = \App\Modules\Timesheets\Models\Timesheet::find($timesheetId);
                    
                    if ($timesheet && $timesheet->end && $this->has('start')) {
                        // Don't allow changing start time of completed timesheet
                        $validator->errors()->add('start', 'Cannot modify start time of a completed timesheet.');
                    }
                } catch (\Exception $e) {
                    // Timesheet not found, will be handled elsewhere
                }
            }
        }
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
        }
    }

    /**
     * Validate business hours (optional - can be customized per business)
     */
    private function validateBusinessHours($validator): void
    {
        // This is a sample validation - can be customized based on business requirements
        if ($this->start) {
            $start = Carbon::parse($this->start);
            
            // Example: Don't allow entries older than 30 days
            if ($start->lt(now()->subDays(30))) {
                $validator->errors()->add('start', 'Cannot create timesheet entries older than 30 days.');
            }
        }

        // Example: Weekend restrictions (uncomment if needed)
        /*
        if ($this->start) {
            $start = Carbon::parse($this->start);
            
            if ($start->isWeekend()) {
                $validator->errors()->add('start', 'Weekend timesheet entries require manager approval.');
            }
        }
        */
    }

    /**
     * Get the validated data after applying business logic
     */
    public function validatedWithDefaults(): array
    {
        $validated = $this->validated();
        
        // Set default user to current authenticated user if not specified
        if (!isset($validated['user_id'])) {
            $user = $this->user();
            $validated['user_id'] = $user->staff_id;
            $validated['user_type'] = get_class($user);
        }

        // Set default status if not specified
        if (!isset($validated['status_id'])) {
            if (isset($validated['end'])) {
                $validated['status_id'] = 2; // Completed
            } else {
                $validated['status_id'] = 1; // Active
            }
        }

        return $validated;
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        // Convert empty strings to null
        $input = $this->all();
        
        foreach (['model_id', 'user_id', 'status_id', 'notes', 'end'] as $field) {
            if (isset($input[$field]) && $input[$field] === '') {
                $input[$field] = null;
            }
        }

        // Ensure user_type is set correctly if user_id is provided
        if (isset($input['user_id']) && !isset($input['user_type'])) {
            $input['user_type'] = 'App\Modules\Customers\Models\Staff';
        }

        $this->replace($input);
    }
}
