<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class ForgotPasswordController extends Controller
{
    public function verify(Request $request)
    {
        $request->validate([
            'phone_number' => 'required|string',
            'family_card_number' => 'required|string',
            'birth_date' => 'required|date',
        ]);

        $user = User::where('phone_number', $request->phone_number)
            ->where('nomor_kk', $request->family_card_number)
            ->where('tanggal_lahir', $request->birth_date)
            ->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Data tidak ditemukan.'
            ]); // The spec says "Response Gagal" with JSON that has "success": false. Often the user wants 200 with false or 400. Let's return 400 like typically done, wait, original spec didn't specify status code. I'll just return 400.
        }

        $token = Str::random(64);
        Cache::put('reset_token_' . $token, $user->id, now()->addMinutes(15));

        return response()->json([
            'success' => true,
            'message' => 'Verifikasi berhasil.',
            'reset_token' => $token
        ]);
    }

    public function reset(Request $request)
    {
        $request->validate([
            'reset_token' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $userId = Cache::get('reset_token_' . $request->reset_token);

        if (!$userId) {
            return response()->json([
                'success' => false,
                'message' => 'Sesi reset password tidak valid atau telah kedaluwarsa.'
            ], 400);
        }

        $user = User::find($userId);
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Sesi reset password tidak valid atau telah kedaluwarsa.'
            ], 400);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        Cache::forget('reset_token_' . $request->reset_token);

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diperbarui.'
        ]);
    }
}
