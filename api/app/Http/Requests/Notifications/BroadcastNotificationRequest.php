<?php

namespace App\Http\Requests\Notifications;

use Illuminate\Foundation\Http\FormRequest;

class BroadcastNotificationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'message' => ['required', 'string', 'max:2000'],
            'target_type' => ['required', 'in:all,role,users,event_attendees,service_applicants'],
            'target_filters' => ['nullable', 'array'],
            'target_filters.role' => ['required_if:target_type,role', 'in:admin,jemaat'],
            'target_filters.user_ids' => ['required_if:target_type,users', 'array', 'min:1'],
            'target_filters.user_ids.*' => ['integer', 'exists:users,id'],
            'target_filters.event_id' => ['required_if:target_type,event_attendees', 'integer', 'exists:events,id'],
            'target_filters.service_category' => ['nullable', 'string', 'max:80'],
            'target_filters.service_status' => ['nullable', 'in:pending,approved,rejected'],
        ];
    }
}
