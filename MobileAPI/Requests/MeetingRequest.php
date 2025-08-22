<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class MeetingRequest extends FormRequest
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
            'description' => 'sometimes|string|max:2000',
            'start_date' => 'required|date|after:now',
            'end_date' => 'required|date|after:start_date',
            'location' => 'sometimes|string|max:255',
            'meeting_url' => 'sometimes|url|max:500',
            'client_id' => 'sometimes|exists:clients,id',
            'attendees' => 'sometimes|array',
            'attendees.*' => 'exists:staff,staff_id',
            'reminder_minutes' => 'sometimes|integer|min:0|max:10080', // Max 1 week
            'is_recurring' => 'sometimes|boolean',
            'recurring_type' => 'sometimes|string|in:daily,weekly,monthly',
            'recurring_end_date' => 'sometimes|date|after:end_date',
        ];
    }

    /**
     * Get custom error messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'title.required' => 'Meeting title is required',
            'title.max' => 'Meeting title is too long',
            'description.max' => 'Meeting description is too long',
            'start_date.required' => 'Start date is required',
            'start_date.date' => 'Start date must be a valid date',
            'start_date.after' => 'Start date must be in the future',
            'end_date.required' => 'End date is required',
            'end_date.date' => 'End date must be a valid date',
            'end_date.after' => 'End date must be after start date',
            'location.max' => 'Location is too long',
            'meeting_url.url' => 'Meeting URL must be a valid URL',
            'meeting_url.max' => 'Meeting URL is too long',
            'client_id.exists' => 'Selected client is invalid',
            'attendees.array' => 'Attendees must be an array',
            'attendees.*.exists' => 'One or more selected attendees are invalid',
            'reminder_minutes.integer' => 'Reminder minutes must be a number',
            'reminder_minutes.min' => 'Reminder minutes cannot be negative',
            'reminder_minutes.max' => 'Reminder cannot be more than 1 week',
            'recurring_type.in' => 'Invalid recurring type',
            'recurring_end_date.date' => 'Recurring end date must be a valid date',
            'recurring_end_date.after' => 'Recurring end date must be after meeting end date',
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
