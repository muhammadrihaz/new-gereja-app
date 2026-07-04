<?php

namespace App\Http\Requests\Devices;

use Illuminate\Foundation\Http\FormRequest;

class RefreshDeviceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            // The previous FCM token this device had (if any). May be omitted if
            // the client has lost it. When present it is used to migrate the
            // existing row instead of creating a duplicate.
            'old_fcm_token' => ['nullable', 'string', 'min:10', 'max:255'],
            // The freshly-rotated FCM token from Firebase. Required.
            'new_fcm_token' => ['required', 'string', 'min:20', 'max:255'],
            'device_name' => ['nullable', 'string', 'max:120'],
            'device_type' => ['required', 'in:android,ios,web'],
        ];
    }
}
