<?php

namespace App\Http\Requests\Events;

use Illuminate\Foundation\Http\FormRequest;

class UploadDocumentationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'report_summary' => ['nullable', 'string'],
            'files' => ['required', 'array', 'min:1', 'max:20'],
            'files.*' => [
                'file',
                'max:20480',
                'mimetypes:image/jpeg,image/png,image/webp,video/mp4,video/quicktime',
            ],
        ];
    }
}
