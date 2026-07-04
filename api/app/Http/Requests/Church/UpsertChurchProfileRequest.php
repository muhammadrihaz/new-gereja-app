<?php

namespace App\Http\Requests\Church;

use Illuminate\Foundation\Http\FormRequest;

class UpsertChurchProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:150'],
            'address' => ['nullable', 'string', 'max:500'],
            'phone' => ['nullable', 'string', 'max:50'],
            'email' => ['nullable', 'email', 'max:150'],
            'logo' => ['nullable', 'array'],
            'logo.url' => ['nullable', 'string', 'max:500'],
            'logo.disk' => ['nullable', 'string', 'max:50'],
            'logo.path' => ['nullable', 'string', 'max:500'],
            'logo.original_name' => ['nullable', 'string', 'max:255'],
            'logo.mime' => ['nullable', 'string', 'max:120'],
            'logo.size' => ['nullable', 'integer', 'min:0'],
            'logo.variants' => ['nullable', 'array'],
            'metadata' => ['nullable', 'array'],
        ];
    }
}
