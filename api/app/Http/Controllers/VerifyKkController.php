<?php

namespace App\Http\Controllers;

use App\Http\Controllers\AuthController;
use App\Models\KKRegistration;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VerifyKkController extends Controller
{
    use ApiResponse;

    public function __invoke(Request $request): JsonResponse
    {
        $request->validate([
            'name' => ['required', 'string', 'max:160'],
            'nomor_kk' => ['required', 'string', 'min:16', 'max:32'],
        ]);

        $name = trim($request->string('name')->toString());
        $nomorKk = trim($request->string('nomor_kk')->toString());
        $normalizedName = AuthController::normalizeName($name);

        $registeredKk = KKRegistration::query()
            ->where('nomor_kk', $nomorKk)
            ->first(['nama_kepala_keluarga']);

        $isHeadOfFamily = $registeredKk !== null
            && AuthController::normalizeName((string) $registeredKk->nama_kepala_keluarga) === $normalizedName;

        $isRegisteredMember = User::query()
            ->where('nomor_kk', $nomorKk)
            ->get(['name'])
            ->contains(function (User $member) use ($normalizedName): bool {
                return AuthController::normalizeName((string) $member->name) === $normalizedName;
            });

        if (! $isHeadOfFamily && ! $isRegisteredMember) {
            return $this->errorResponse(
                'Nomor KK atau nama lengkap tidak terdaftar',
                'KK_OR_NAME_NOT_REGISTERED',
                422,
            );
        }

        return $this->successResponse([
            'verified' => true,
            'name' => $name,
            'nomor_kk' => $nomorKk,
        ], 'Data jemaat ditemukan');
    }
}
