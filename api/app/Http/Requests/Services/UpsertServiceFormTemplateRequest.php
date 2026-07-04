<?php

namespace App\Http\Requests\Services;

use Illuminate\Foundation\Http\FormRequest;

class UpsertServiceFormTemplateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'category' => ['required', 'string', 'max:80', 'exists:service_categories,code'],
            'name' => ['required', 'string', 'max:120'],
            'is_active' => ['nullable', 'boolean'],
            'fields' => ['required', 'array', 'min:1'],
            'fields.*.key' => ['required', 'string', 'max:80'],
            'fields.*.type' => ['required', 'in:string,number,boolean,date,select'],
            'fields.*.required' => ['required', 'boolean'],
            'fields.*.label' => ['nullable', 'string', 'max:120'],
            'fields.*.options' => ['nullable', 'array'],
            'fields.*.options.*' => ['string', 'max:120'],
        ];
    }
}
