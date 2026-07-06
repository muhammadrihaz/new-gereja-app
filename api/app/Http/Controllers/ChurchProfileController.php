<?php

namespace App\Http\Controllers;

use App\Http\Requests\Church\UpsertChurchProfileRequest;
use App\Models\ChurchProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;

class ChurchProfileController extends Controller
{
    use ApiResponse;

    public function show(): JsonResponse
    {
        $profile = ChurchProfile::query()->first();

        if (! $profile) {
            $profile = ChurchProfile::query()->create([
                'name' => config('app.name', 'Profil Gereja'),
                'logo' => null,
            ]);
        }

        return $this->successResponse($profile, 'Profil gereja berhasil diambil');
    }

    public function upsert(UpsertChurchProfileRequest $request): JsonResponse
    {
        $profile = ChurchProfile::query()->first();

        if ($profile) {
            $profile->update($request->validated());
        } else {
            $profile = ChurchProfile::query()->create($request->validated());
        }

        return $this->successResponse($profile->toArray(), 'Profil gereja berhasil disimpan');
    }
}
