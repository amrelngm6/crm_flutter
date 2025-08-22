<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class TaskRequest extends FormRequest
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
            'description' => 'sometimes|string|max:2000',
            'priority_id' => 'sometimes|exists:priorities,priority_id',
            'status_id' => 'sometimes|exists:status_list,status_id',
            'due_date' => 'sometimes|date',
            'start_date' => 'sometimes|date',
            'finished_date' => 'sometimes|date',
            'model_id' => 'sometimes|integer',
            'model_type' => 'sometimes|string|max:255',
            'is_public' => 'sometimes|boolean',
            'is_paid' => 'sometimes|boolean',
            'visible_to_client' => 'sometimes|boolean',
            'points' => 'sometimes|integer|min:0',
            'sort' => 'sometimes|integer|min:0',
            'team' => 'sometimes|array',
            'team.*' => 'exists:staff,staff_id',
            'checklist' => 'sometimes|array',
            'checklist.*.description' => 'required|string|max:500',
            'checklist.*.points' => 'sometimes|integer|min:0',
            'checklist.*.visible_to_client' => 'sometimes|boolean',
            'checklist.*.status' => 'sometimes|boolean',
        ];
    }

    /**
     * Get custom error messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'name.required' => 'Task name is required',
            'name.max' => 'Task name is too long',
            'description.max' => 'Task description is too long',
            'priority_id.exists' => 'Selected priority is invalid',
            'status_id.exists' => 'Selected status is invalid',
            'due_date.date' => 'Due date must be a valid date',
            'start_date.date' => 'Start date must be a valid date',
            'finished_date.date' => 'Finished date must be a valid date',
            'model_id.integer' => 'Model ID must be an integer',
            'model_type.string' => 'Model type must be a string',
            'model_type.max' => 'Model type is too long',
            'is_public.boolean' => 'Is public must be true or false',
            'is_paid.boolean' => 'Is paid must be true or false',
            'visible_to_client.boolean' => 'Visible to client must be true or false',
            'points.integer' => 'Points must be an integer',
            'points.min' => 'Points cannot be negative',
            'sort.integer' => 'Sort must be an integer',
            'sort.min' => 'Sort cannot be negative',
            'team.array' => 'Team must be an array',
            'team.*.exists' => 'One or more selected team members are invalid',
            'checklist.array' => 'Checklist must be an array',
            'checklist.*.description.required' => 'Checklist item description is required',
            'checklist.*.description.string' => 'Checklist item description must be a string',
            'checklist.*.description.max' => 'Checklist item description is too long',
            'checklist.*.points.integer' => 'Checklist item points must be an integer',
            'checklist.*.points.min' => 'Checklist item points cannot be negative',
            'checklist.*.visible_to_client.boolean' => 'Checklist item visible to client must be true or false',
            'checklist.*.status.boolean' => 'Checklist item status must be true or false',
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
