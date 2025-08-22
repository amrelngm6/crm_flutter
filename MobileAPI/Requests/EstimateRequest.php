<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class EstimateRequest extends FormRequest
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
        $estimateId = $this->route('estimate');

        return [
            'estimate_number' => [
                'required',
                'string',
                'max:255',
                Rule::unique('estimates')->ignore($estimateId)
            ],
            'title' => 'required|string|max:255',
            'content' => 'nullable|string',
            'status_id' => 'required|exists:estimate_statuses,id',
            'client_id' => 'required|exists:clients,client_id',
            'assigned_to' => 'nullable|exists:staff,staff_id',
            'date' => 'required|date',
            'expiry_date' => 'nullable|date|after:date',
            'currency_code' => 'required|string|size:3',
            
            // Financial fields
            'subtotal' => 'nullable|numeric|min:0',
            'discount_amount' => 'nullable|numeric|min:0',
            'tax_amount' => 'nullable|numeric|min:0',
            'total' => 'nullable|numeric|min:0',
            
            // Model relationship
            'model_id' => 'nullable|integer',
            'model_type' => 'nullable|string|max:255',
            
            // Approval fields
            'approval_status' => 'nullable|in:pending,approved,rejected',
            
            // Items array
            'items' => 'nullable|array',
            'items.*.item_name' => 'required|string|max:255',
            'items.*.description' => 'nullable|string',
            'items.*.quantity' => 'required|numeric|min:0.01',
            'items.*.unit_price' => 'required|numeric|min:0',
            'items.*.subtotal' => 'nullable|numeric|min:0',
            'items.*.tax' => 'nullable|numeric|min:0',
            'items.*.total' => 'nullable|numeric|min:0',
            'items.*.item_id' => 'nullable|integer',
            'items.*.item_type' => 'nullable|string|max:255',
        ];
    }

    /**
     * Get custom validation messages.
     */
    public function messages(): array
    {
        return [
            'estimate_number.required' => 'The estimate number is required.',
            'estimate_number.unique' => 'This estimate number already exists.',
            'title.required' => 'The estimate title is required.',
            'status_id.required' => 'The estimate status is required.',
            'status_id.exists' => 'The selected status is invalid.',
            'client_id.required' => 'A client must be selected.',
            'client_id.exists' => 'The selected client does not exist.',
            'assigned_to.exists' => 'The assigned staff member does not exist.',
            'date.required' => 'The estimate date is required.',
            'date.date' => 'The estimate date must be a valid date.',
            'expiry_date.date' => 'The expiry date must be a valid date.',
            'expiry_date.after' => 'The expiry date must be after the estimate date.',
            'currency_code.required' => 'The currency code is required.',
            'currency_code.size' => 'The currency code must be exactly 3 characters.',
            'subtotal.numeric' => 'The subtotal must be a valid number.',
            'subtotal.min' => 'The subtotal cannot be negative.',
            'discount_amount.numeric' => 'The discount amount must be a valid number.',
            'discount_amount.min' => 'The discount amount cannot be negative.',
            'tax_amount.numeric' => 'The tax amount must be a valid number.',
            'tax_amount.min' => 'The tax amount cannot be negative.',
            'total.numeric' => 'The total must be a valid number.',
            'total.min' => 'The total cannot be negative.',
            'approval_status.in' => 'The approval status must be pending, approved, or rejected.',
            'items.array' => 'Items must be provided as an array.',
            'items.*.item_name.required' => 'Each item must have a name.',
            'items.*.item_name.max' => 'Item name cannot exceed 255 characters.',
            'items.*.quantity.required' => 'Each item must have a quantity.',
            'items.*.quantity.numeric' => 'Item quantity must be a valid number.',
            'items.*.quantity.min' => 'Item quantity must be greater than 0.',
            'items.*.unit_price.required' => 'Each item must have a unit price.',
            'items.*.unit_price.numeric' => 'Item unit price must be a valid number.',
            'items.*.unit_price.min' => 'Item unit price cannot be negative.',
        ];
    }

    /**
     * Get custom attributes for validator errors.
     */
    public function attributes(): array
    {
        return [
            'estimate_number' => 'estimate number',
            'client_id' => 'client',
            'assigned_to' => 'assigned staff',
            'status_id' => 'status',
            'currency_code' => 'currency',
            'expiry_date' => 'expiry date',
            'approval_status' => 'approval status',
            'items.*.item_name' => 'item name',
            'items.*.quantity' => 'quantity',
            'items.*.unit_price' => 'unit price',
        ];
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        // Auto-calculate totals if items are provided but totals are missing
        if ($this->has('items') && is_array($this->items)) {
            $calculatedSubtotal = 0;
            $calculatedTax = 0;
            
            foreach ($this->items as $index => $item) {
                if (isset($item['quantity']) && isset($item['unit_price'])) {
                    $itemSubtotal = $item['quantity'] * $item['unit_price'];
                    $itemTax = $item['tax'] ?? 0;
                    $itemTotal = $itemSubtotal + $itemTax;
                    
                    // Update item calculations
                    $this->merge([
                        "items.{$index}.subtotal" => $itemSubtotal,
                        "items.{$index}.total" => $itemTotal,
                    ]);
                    
                    $calculatedSubtotal += $itemSubtotal;
                    $calculatedTax += $itemTax;
                }
            }
            
            // Update estimate totals if not provided
            if (!$this->has('subtotal')) {
                $this->merge(['subtotal' => $calculatedSubtotal]);
            }
            
            if (!$this->has('tax_amount')) {
                $this->merge(['tax_amount' => $calculatedTax]);
            }
            
            if (!$this->has('total')) {
                $discountAmount = $this->discount_amount ?? 0;
                $this->merge(['total' => $calculatedSubtotal + $calculatedTax - $discountAmount]);
            }
        }
        
        // Set default approval status for new estimates
        if (!$this->has('approval_status')) {
            $this->merge(['approval_status' => 'pending']);
        }
        
        // Auto-generate estimate number if not provided
        if (!$this->has('estimate_number')) {
            $this->merge(['estimate_number' => $this->generateEstimateNumber()]);
        }
    }

    /**
     * Generate a unique estimate number
     */
    private function generateEstimateNumber(): string
    {
        $prefix = 'EST';
        $year = date('Y');
        $month = date('m');
        
        // Get the next sequential number for this month
        $lastEstimate = \App\Models\Estimate::where('estimate_number', 'like', "{$prefix}-{$year}{$month}-%")
            ->orderBy('estimate_number', 'desc')
            ->first();
        
        if ($lastEstimate) {
            $lastNumber = (int) substr($lastEstimate->estimate_number, -4);
            $nextNumber = $lastNumber + 1;
        } else {
            $nextNumber = 1;
        }
        
        return sprintf('%s-%s%s-%04d', $prefix, $year, $month, $nextNumber);
    }
}
