<?php

namespace App\Http\Requests\News;

use Illuminate\Foundation\Http\FormRequest;

class UpdateNewsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:500'],
            'content' => ['sometimes', 'required', 'string'],
            'cover_image' => ['nullable'],
            'cover_file' => ['nullable', 'file', 'image', 'max:5120'],
            'published_at' => ['nullable', 'date'],
            'kegiatan_date' => ['nullable', 'date'],
        ];
    }
}
