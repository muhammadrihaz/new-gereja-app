<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:160'],
            'username' => ['required', 'string', 'max:60', 'unique:users,username'],
            'email' => ['nullable', 'email', 'max:191', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'nomor_kk' => ['required', 'string', 'min:16', 'max:32'],
            'jenis_kelamin' => ['nullable', 'in:L,P'],
            'usia' => ['nullable', 'integer', 'min:1', 'max:120'],
            'tempat_lahir' => ['nullable', 'string', 'max:100'],
            'tanggal_lahir' => ['nullable', 'date'],
            'alamat' => ['nullable', 'string'],
            'phone_number' => ['nullable', 'string', 'max:20'],
            'status' => ['nullable', 'in:active,inactive,simpatisan'],
            'fcm_token' => ['required', 'string', 'min:20'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama lengkap wajib diisi',
            'nomor_kk.exists' => 'Nomor KK atau nama lengkap tidak terdaftar, periksa ulang apakah sudah benar',
        ];
    }
}
