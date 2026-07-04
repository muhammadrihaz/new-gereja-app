<?php

namespace App\Http\Requests\Devices;

use Illuminate\Foundation\Http\FormRequest;

class RegisterDeviceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'fcm_token' => ['required', 'string', 'min:20'],
            'device_name' => ['nullable', 'string', 'max:120'],
            'device_type' => ['required', 'in:android,ios,web'],
        ];
    }
}
