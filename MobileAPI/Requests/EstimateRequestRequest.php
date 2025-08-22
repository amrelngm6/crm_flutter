<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use App\Modules\Customers\Models\Staff;
use App\Modules\Customers\Models\Client;

class EstimateRequestRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true; // Authorization is handled by middleware
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        $rules = [
            'message' => 'required|string|max:2000',
            'date' => 'nullable|date|after_or_equal:today',
            'assigned_to' => 'nullable|exists:staff,staff_id',
            'status_id' => 'nullable|exists:status_list,status_id',
        ];

        // Additional rules for update requests
        if ($this->isMethod('PUT') || $this->isMethod('PATCH')) {
            $rules['estimate_id'] = 'nullable|exists:estimates,id';
        }

        return $rules;
    }

    /**
     * Get custom validation messages.
     */
    public function messages(): array
    {
        return [
            'message.required' => 'The request message is required.',
            'message.string' => 'The request message must be a valid text.',
            'message.max' => 'The request message cannot exceed 2000 characters.',
            'date.date' => 'The date must be a valid date.',
            'date.after_or_equal' => 'The date cannot be in the past.',
            'assigned_to.exists' => 'The selected staff member does not exist.',
            'status_id.exists' => 'The selected status does not exist.',
            'estimate_id.exists' => 'The selected estimate does not exist.',
        ];
    }

    /**
     * Get custom validation attributes.
     */
    public function attributes(): array
    {
        return [
            'message' => 'request message',
            'date' => 'request date',
            'assigned_to' => 'assigned staff',
            'status_id' => 'status',
            'estimate_id' => 'estimate',
        ];
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            // Additional business logic validation can be added here
            $this->validateBusinessSettings($validator);
        });
    }

    /**
     * Validate business settings constraints
     */
    protected function validateBusinessSettings($validator): void
    {
        try {
            // Check if estimate requests are enabled
            if (!\App\Modules\Estimates\Helpers\EstimateSettingsHelper::areEstimateRequestsEnabled()) {
                $validator->errors()->add('message', 'Estimate requests are currently disabled.');
                return;
            }

            // For new requests, check daily limit (only applies to client requests)
            if ($this->isMethod('POST') && $this->user()) {
                $user = $this->user();
                $userId = $user->staff_id ?? $user->client_id ?? null;
                
                if ($userId && !$this->checkDailyLimit($userId)) {
                    $validator->errors()->add('message', 'Daily estimate request limit has been exceeded.');
                }
            }

        } catch (\Exception $e) {
            // Log error but don't fail validation for settings issues
            logger()->warning('Error validating estimate request business settings: ' . $e->getMessage());
        }
    }

    /**
     * Check daily request limit for user
     */
    protected function checkDailyLimit($userId): bool
    {
        try {
            return \App\Modules\Estimates\Helpers\EstimateSettingsHelper::checkDailyRequestLimit($userId);
        } catch (\Exception $e) {
            // If we can't check the limit, allow the request
            return true;
        }
    }

    /**
     * Get the validated data from the request with additional processing.
     */
    public function validated($key = null, $default = null)
    {
        $validated = parent::validated($key, $default);

        // Set default date if not provided
        if (!isset($validated['date']) || empty($validated['date'])) {
            $validated['date'] = now()->toDateString();
        }

        // Set default status if not provided (pending)
        if (!isset($validated['status_id']) || empty($validated['status_id'])) {
            try {
                $pendingStatus = \App\Modules\Core\Models\Status::where('name', 'Pending')
                                                                ->where('model', 'App\Modules\Estimates\Models\EstimateRequest')
                                                                ->first();
                if ($pendingStatus) {
                    $validated['status_id'] = $pendingStatus->status_id;
                }
            } catch (\Exception $e) {
                // Use default status ID if query fails
                $validated['status_id'] = 1;
            }
        }

        return $validated;
    }
}
