<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = optional($this->user())->id;

        return [
            'name' => ['nullable', 'string', 'max:160'],
            'username' => ['nullable', 'string', 'max:60', 'unique:users,username,' . $userId],
            'email' => ['nullable', 'email', 'max:191', 'unique:users,email,' . $userId],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
            'nomor_kk' => ['nullable', 'string', 'max:32'],
            'jenis_kelamin' => ['nullable', 'in:L,P'],
            'usia' => ['nullable', 'integer', 'min:1', 'max:120'],
            'tempat_lahir' => ['nullable', 'string', 'max:100'],
            'tanggal_lahir' => ['nullable', 'date'],
            'alamat' => ['required', 'string'],
            'phone_number' => ['nullable', 'string', 'max:20'],
            'status' => ['nullable', 'in:active,jemaat,simpatisan'],
        ];
    }

    public function messages(): array
    {
        return [
            'password.confirmed' => 'Konfirmasi password tidak cocok',
            'email.unique' => 'Email sudah terdaftar',
            'username.unique' => 'Username sudah terdaftar',
        ];
    }
}
