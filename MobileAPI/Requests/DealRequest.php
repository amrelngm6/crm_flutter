<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class DealRequest extends FormRequest
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
            'name' => 'required|string|max:255',
            'code' => 'sometimes|string|max:100',
            'description' => 'sometimes|string|max:2000',
            'amount' => 'required|numeric|min:0|max:999999999.99',
            'currency_code' => 'sometimes|string|size:3',
            'probability' => 'sometimes|integer|min:0|max:100',
            'expected_due_date' => 'sometimes|date',
            'status' => 'sometimes|string|max:50',
            'client_id' => 'sometimes|exists:clients,client_id',
            'lead_id' => 'sometimes|exists:leads,lead_id',
            'pipeline_stage_id' => 'sometimes|exists:pipeline_stages,id',
            'team' => 'sometimes|array',
            'team.*' => 'exists:staff,staff_id',
        ];
    }

    /**
     * Get custom error messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'name.required' => 'Deal name is required',
            'name.max' => 'Deal name is too long',
            'code.max' => 'Deal code is too long',
            'description.max' => 'Deal description is too long',
            'amount.required' => 'Deal amount is required',
            'amount.numeric' => 'Deal amount must be a number',
            'amount.min' => 'Deal amount cannot be negative',
            'amount.max' => 'Deal amount is too large',
            'currency_code.size' => 'Currency code must be 3 characters',
            'probability.integer' => 'Probability must be an integer',
            'probability.min' => 'Probability cannot be negative',
            'probability.max' => 'Probability cannot exceed 100%',
            'expected_due_date.date' => 'Expected due date must be a valid date',
            'status.max' => 'Status is too long',
            'client_id.exists' => 'Selected client is invalid',
            'lead_id.exists' => 'Selected lead is invalid',
            'pipeline_stage_id.exists' => 'Selected pipeline stage is invalid',
            'team.array' => 'Team must be an array',
            'team.*.exists' => 'One or more selected team members are invalid',
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
