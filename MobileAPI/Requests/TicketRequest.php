<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class TicketRequest extends FormRequest
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
        $ticketId = $this->route('ticket');

        return [
            'subject' => 'required|string|max:255',
            'message' => 'required|string',
            'client_id' => 'required|exists:clients,client_id',
            'status_id' => 'nullable|exists:status_list,status_id',
            'priority_id' => 'nullable|exists:priorities,priority_id',
            'category_id' => 'nullable|exists:categories,id',
            'due_date' => 'nullable|date|after:today',
            
            // Model relationship (optional)
            'model_id' => 'nullable|integer',
            'model_type' => 'nullable|string|max:255',
            
            // Staff assignment
            'members' => 'nullable|array',
            'members.*' => 'exists:staff,staff_id',
            
            // Custom fields
            'custom_field' => 'nullable|array',
        ];
    }

    /**
     * Get custom validation messages.
     */
    public function messages(): array
    {
        return [
            'subject.required' => 'The ticket subject is required.',
            'subject.max' => 'The ticket subject cannot exceed 255 characters.',
            'message.required' => 'The ticket message is required.',
            'client_id.required' => 'A client must be selected for the ticket.',
            'client_id.exists' => 'The selected client does not exist.',
            'status_id.exists' => 'The selected status is invalid.',
            'priority_id.exists' => 'The selected priority is invalid.',
            'category_id.exists' => 'The selected category is invalid.',
            'due_date.date' => 'The due date must be a valid date.',
            'due_date.after' => 'The due date must be in the future.',
            'members.array' => 'Staff members must be provided as an array.',
            'members.*.exists' => 'One or more selected staff members do not exist.',
            'custom_field.array' => 'Custom fields must be provided as an array.',
        ];
    }

    /**
     * Get custom attributes for validator errors.
     */
    public function attributes(): array
    {
        return [
            'client_id' => 'client',
            'status_id' => 'status',
            'priority_id' => 'priority',
            'category_id' => 'category',
            'due_date' => 'due date',
            'model_id' => 'related model ID',
            'model_type' => 'related model type',
            'members' => 'assigned staff members',
            'custom_field' => 'custom fields',
        ];
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        // Set default client type if not provided
        if ($this->has('client_id') && !$this->has('client_type')) {
            $this->merge([
                'client_type' => \App\Modules\Customers\Models\Client::class
            ]);
        }

        // Clean up members array (remove empty values)
        if ($this->has('members') && is_array($this->members)) {
            $this->merge([
                'members' => array_filter($this->members, function($value) {
                    return !empty($value);
                })
            ]);
        }

        // Set current date if no date provided
        if (!$this->has('date')) {
            $this->merge(['date' => date('Y-m-d')]);
        }
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            // Custom business logic validation
            
            // Check if client belongs to the same business
            if ($this->client_id) {
                $user = $this->user();
                $client = \App\Modules\Customers\Models\Client::find($this->client_id);
                
                if ($client && $client->business_id !== $user->business_id) {
                    $validator->errors()->add('client_id', 'The selected client does not belong to your business.');
                }
            }

            // Validate model relationship if provided
            if ($this->model_id && $this->model_type) {
                if (!class_exists($this->model_type)) {
                    $validator->errors()->add('model_type', 'The specified model type is invalid.');
                } else {
                    try {
                        $model = $this->model_type::find($this->model_id);
                        if (!$model) {
                            $validator->errors()->add('model_id', 'The specified model does not exist.');
                        }
                    } catch (\Exception $e) {
                        $validator->errors()->add('model_type', 'Error validating the model relationship.');
                    }
                }
            }

            // Validate staff members belong to the same business
            if ($this->members && is_array($this->members)) {
                $user = $this->user();
                $invalidStaff = \App\Modules\Customers\Models\Staff::whereIn('staff_id', $this->members)
                    ->where('business_id', '!=', $user->business_id)
                    ->exists();
                
                if ($invalidStaff) {
                    $validator->errors()->add('members', 'One or more selected staff members do not belong to your business.');
                }
            }
        });
    }
}
