<?php

namespace App\Http\Controllers;

use App\Models\KKRegistration;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class KKRegistrationController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $search = trim((string) $request->query('search', ''));
        $perPage = min((int) $request->query('per_page', 30), 100);

        $query = KKRegistration::query();

        if ($search !== '') {
            $query->where(function ($q) use ($search): void {
                $q->where('nomor_kk', 'like', "%{$search}%")
                    ->orWhere('nama_kepala_keluarga', 'like', "%{$search}%")
                    ->orWhere('alamat', 'like', "%{$search}%")
                    ->orWhere('phone_number', 'like', "%{$search}%");
            });
        }

        $kks = $query->orderBy('created_at', 'desc')->paginate($perPage);

        return $this->successResponse(
            $kks->items(),
            'Daftar KK berhasil diambil',
            200,
            [
                'pagination' => [
                    'current_page' => $kks->currentPage(),
                    'per_page' => $kks->perPage(),
                    'total' => $kks->total(),
                    'last_page' => $kks->lastPage(),
                ],
            ]
        );
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nomor_kk' => ['required', 'string', 'min:16', 'max:32', 'unique:kk_registrations,nomor_kk'],
            'nama_kepala_keluarga' => ['required', 'string', 'max:160'],
            'alamat' => ['nullable', 'string'],
            'phone_number' => ['nullable', 'string', 'max:20'],
        ], [
            'nomor_kk.unique' => 'Nomor KK sudah terdaftar',
        ]);

        /** @var \App\Models\User $user */
        $user = auth('sanctum')->user();

        $kk = KKRegistration::query()->create([
            'nomor_kk' => $validated['nomor_kk'],
            'nama_kepala_keluarga' => $validated['nama_kepala_keluarga'],
            'alamat' => $validated['alamat'] ?? null,
            'phone_number' => $validated['phone_number'] ?? null,
            'registered_by' => $user->id,
        ]);

        return $this->successResponse($kk, 'KK berhasil terdaftar', 201);
    }

    public function update(Request $request, KKRegistration $kk): JsonResponse
    {
        $validated = $request->validate([
            'nomor_kk' => ['nullable', 'string', 'min:16', 'max:32', 'unique:kk_registrations,nomor_kk,' . $kk->id],
            'nama_kepala_keluarga' => ['nullable', 'string', 'max:160'],
            'alamat' => ['nullable', 'string'],
            'phone_number' => ['nullable', 'string', 'max:20'],
        ]);

        $kk->update($validated);

        return $this->successResponse($kk->fresh(), 'KK berhasil diperbarui');
    }

    public function show(KKRegistration $kk): JsonResponse
    {
        $members = $kk->members()->select(['id', 'name', 'username', 'email', 'nomor_kk', 'jenis_kelamin', 'usia', 'alamat', 'phone_number', 'status'])->get();

        return $this->successResponse([
            'kk' => $kk,
            'members' => $members,
            'total_members' => $members->count(),
        ]);
    }

    public function destroy(KKRegistration $kk): JsonResponse
    {
        // Prevent deletion if there are associated members
        if ($kk->members()->count() > 0) {
            return $this->errorResponse('Tidak dapat menghapus KK karena masih ada anggota keluarga terdaftar', 'KK_HAS_MEMBERS', 422);
        }

        $kk->delete();

        return $this->successResponse(null, 'KK berhasil dihapus');
    }
}
