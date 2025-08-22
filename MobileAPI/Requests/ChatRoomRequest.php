<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ChatRoomRequest extends FormRequest
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
            'participants' => 'required|array|min:1',
            'participants.*' => 'integer|exists:staff,staff_id',
        ];
    }

    /**
     * Get custom messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'name.required' => 'Room name is required.',
            'name.string' => 'Room name must be a string.',
            'name.max' => 'Room name must not exceed 255 characters.',
            'participants.required' => 'At least one participant is required.',
            'participants.array' => 'Participants must be an array.',
            'participants.min' => 'At least one participant is required.',
            'participants.*.integer' => 'Each participant ID must be an integer.',
            'participants.*.exists' => 'One or more participant IDs are invalid.',
        ];
    }
}
