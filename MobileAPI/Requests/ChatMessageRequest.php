<?php

namespace App\Modules\MobileAPI\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ChatMessageRequest extends FormRequest
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
            'message' => 'required|string|max:2000',
            'type' => 'sometimes|string|in:text,file,image',
        ];
    }

    /**
     * Get custom messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'message.required' => 'Message content is required.',
            'message.string' => 'Message must be a string.',
            'message.max' => 'Message must not exceed 2000 characters.',
            'type.in' => 'Message type must be one of: text, file, image.',
        ];
    }
}
