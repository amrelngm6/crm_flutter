<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class ProposalRequest extends FormRequest
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
            'title' => 'required|string|max:255',
            'content' => 'sometimes|string',
            'model_type' => 'sometimes|string|max:255',
            'model_id' => 'sometimes|integer',
            'client_type' => 'sometimes|string|max:255',
            'client_id' => 'sometimes|exists:clients,client_id',
            'assigned_to' => 'sometimes|exists:staff,staff_id',
            'date' => 'required|date',
            'expiry_date' => 'sometimes|date|after:date',
            'currency_code' => 'sometimes|string|size:3',
            'subtotal' => 'sometimes|numeric|min:0',
            'discount_amount' => 'sometimes|numeric|min:0',
            'tax_amount' => 'sometimes|numeric|min:0',
            'total' => 'sometimes|numeric|min:0',
            'status_id' => 'sometimes|exists:status_list,status_id',
            'items' => 'sometimes|array',
            'items.*.item_name' => 'required|string|max:255',
            'items.*.description' => 'sometimes|string',
            'items.*.quantity' => 'required|numeric|min:0.01',
            'items.*.unit_price' => 'required|numeric|min:0',
            'items.*.tax' => 'sometimes|numeric|min:0|max:100',
            'items.*.item_id' => 'sometimes|integer',
            'items.*.item_type' => 'sometimes|string|max:255',
        ];
    }

    /**
     * Get custom error messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'title.required' => 'Proposal title is required',
            'title.max' => 'Proposal title is too long',
            'model_type.max' => 'Model type is too long',
            'model_id.integer' => 'Model ID must be an integer',
            'client_type.max' => 'Client type is too long',
            'client_id.exists' => 'Selected client is invalid',
            'assigned_to.exists' => 'Selected staff member is invalid',
            'date.required' => 'Proposal date is required',
            'date.date' => 'Proposal date must be a valid date',
            'expiry_date.date' => 'Expiry date must be a valid date',
            'expiry_date.after' => 'Expiry date must be after proposal date',
            'currency_code.size' => 'Currency code must be 3 characters',
            'subtotal.numeric' => 'Subtotal must be a number',
            'subtotal.min' => 'Subtotal cannot be negative',
            'discount_amount.numeric' => 'Discount amount must be a number',
            'discount_amount.min' => 'Discount amount cannot be negative',
            'tax_amount.numeric' => 'Tax amount must be a number',
            'tax_amount.min' => 'Tax amount cannot be negative',
            'total.numeric' => 'Total must be a number',
            'total.min' => 'Total cannot be negative',
            'status_id.exists' => 'Selected status is invalid',
            'items.array' => 'Items must be an array',
            'items.*.item_name.required' => 'Item name is required',
            'items.*.item_name.max' => 'Item name is too long',
            'items.*.quantity.required' => 'Item quantity is required',
            'items.*.quantity.numeric' => 'Item quantity must be a number',
            'items.*.quantity.min' => 'Item quantity must be greater than 0',
            'items.*.unit_price.required' => 'Item unit price is required',
            'items.*.unit_price.numeric' => 'Item unit price must be a number',
            'items.*.unit_price.min' => 'Item unit price cannot be negative',
            'items.*.tax.numeric' => 'Item tax must be a number',
            'items.*.tax.min' => 'Item tax cannot be negative',
            'items.*.tax.max' => 'Item tax cannot exceed 100%',
            'items.*.item_id.integer' => 'Item ID must be an integer',
            'items.*.item_type.max' => 'Item type is too long',
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
