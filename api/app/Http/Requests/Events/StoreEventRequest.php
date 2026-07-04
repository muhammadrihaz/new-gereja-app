<?php

namespace App\Http\Requests\Events;

use Illuminate\Foundation\Http\FormRequest;

class StoreEventRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'date' => ['nullable', 'date'],
            'start_at' => ['required_without:date', 'date'],
            'end_at' => ['nullable', 'date', 'after_or_equal:start_at'],
            'category' => ['required', 'string', 'max:80', 'exists:event_categories,code'],
            'location' => ['required'],
            'location.address' => ['required_without:location', 'string', 'max:255'],
            'location.latitude' => ['required_with:location', 'numeric', 'between:-90,90'],
            'location.longitude' => ['required_with:location', 'numeric', 'between:-180,180'],
            'location.name' => ['nullable', 'string', 'max:160'],
            'location.place_id' => ['nullable', 'string', 'max:191'],
            'location.maps_url' => ['nullable', 'url', 'max:500'],
        ];
    }
}
