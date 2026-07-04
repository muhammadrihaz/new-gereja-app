<?php

namespace App\Http\Requests\Services;

use Illuminate\Foundation\Http\FormRequest;

class ApplyServiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'target_user_id' => ['nullable', 'integer', 'exists:users,id'],
            'category' => ['required', 'string', 'max:80', 'exists:service_categories,code'],
            'form_data' => ['required', 'array', 'min:1'],
            'attachments' => ['nullable', 'array'],
            'attachments.*' => ['string', 'max:500'],
        ];
    }
}
