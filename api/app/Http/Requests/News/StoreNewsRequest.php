<?php

namespace App\Http\Requests\News;

use Illuminate\Foundation\Http\FormRequest;

class StoreNewsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:500'],
            'content' => ['required', 'string'],
            'cover_image' => ['nullable'],
            'cover_file' => ['nullable', 'file', 'image', 'max:5120'],
            'published_at' => ['nullable', 'date'],
            'kegiatan_date' => ['nullable', 'date'],
        ];
    }
}
