<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class LeadRequest extends FormRequest
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
        $leadId = $this->route('lead');
        $isUpdate = $this->isMethod('PUT') || $this->isMethod('PATCH');

        return [
            'first_name' => 'required|string|max:255',
            'last_name' => 'sometimes|string|max:255',
            'email' => [
                'required',
                'email',
                'max:255',
                $isUpdate 
                    ? "unique:leads,email,{$leadId},id,business_id," . auth()->user()->business_id
                    : "unique:leads,email,NULL,id,business_id," . auth()->user()->business_id
            ],
            'phone' => 'sometimes|string|max:20',
            'company' => 'sometimes|string|max:255',
            'position' => 'sometimes|string|max:255',
            'address' => 'sometimes|string|max:500',
            'city' => 'sometimes|string|max:100',
            'state' => 'sometimes|string|max:100',
            'country' => 'sometimes|string|max:100',
            'postal_code' => 'sometimes|string|max:20',
            'website' => 'sometimes|url|max:255',
            'source_id' => 'sometimes|exists:lead_sources,id',
            'assigned_to' => 'sometimes|exists:staff,staff_id',
            'status' => 'sometimes|string|in:new,contacted,qualified,converted,lost',
            'notes' => 'sometimes|string|max:2000',
            'budget' => 'sometimes|numeric|min:0',
            'expected_close_date' => 'sometimes|date|after:today',
        ];
    }

    /**
     * Get custom error messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'first_name.required' => 'First name is required',
            'email.required' => 'Email address is required',
            'email.email' => 'Please provide a valid email address',
            'email.unique' => 'This email address is already in use',
            'phone.max' => 'Phone number is too long',
            'website.url' => 'Please provide a valid website URL',
            'source_id.exists' => 'Selected lead source is invalid',
            'assigned_to.exists' => 'Selected staff member is invalid',
            'status.in' => 'Invalid lead status',
            'budget.numeric' => 'Budget must be a number',
            'budget.min' => 'Budget cannot be negative',
            'expected_close_date.date' => 'Expected close date must be a valid date',
            'expected_close_date.after' => 'Expected close date must be in the future',
        ];
    }

    /**
     * Handle a failed validation attempt.
     */
    protected function failedValidation(Validator $validator)
    {
        throw new HttpResponseException(
            response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422)
        );
    }
}
