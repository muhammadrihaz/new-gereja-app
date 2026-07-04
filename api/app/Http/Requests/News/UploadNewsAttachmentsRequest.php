<?php

namespace App\Http\Requests\News;

use Illuminate\Foundation\Http\FormRequest;

class UploadNewsAttachmentsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'files' => ['required', 'array', 'min:1', 'max:20'],
            'files.*' => [
                'file',
                'max:20480',
                'mimetypes:image/jpeg,image/png,image/webp,image/gif,application/pdf,application/zip',
            ],
        ];
    }
}
