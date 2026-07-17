<?php

namespace App\Http\Requests\Services;

use Illuminate\Foundation\Http\FormRequest;

class UpdateServiceStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status' => ['required', 'in:approved,rejected,pending'],
            'admin_note' => ['nullable', 'string'],
            'service_date' => ['nullable', 'date'],
            'service_time' => ['nullable', 'date_format:H:i'],
        ];
    }
}
