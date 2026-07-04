<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rules\Password;

class JemaatManagementController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $search = trim((string) $request->query('search', ''));
        $filterKk = trim((string) $request->query('filter_kk', ''));
        $filterStatus = trim((string) $request->query('filter_status', ''));
        $perPage = min((int) $request->query('per_page', 30), 100);

        $query = User::query()
            ->where('role', 'jemaat')
            ->select(['id', 'name', 'username', 'email', 'nomor_kk', 'jenis_kelamin', 'usia', 'alamat', 'phone_number', 'status', 'profile_photo_path', 'created_at']);

        if ($search !== '') {
            $query->where(function ($q) use ($search): void {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($filterKk !== '') {
            $query->where('nomor_kk', $filterKk);
        }

        if ($filterStatus !== '' && in_array($filterStatus, ['active', 'jemaat', 'simpatisan'])) {
            $query->where('status', $filterStatus);
        }

        $jemaats = $query->orderBy('name')->paginate($perPage);

        return $this->successResponse(
            $jemaats->items(),
            'Daftar jemaat berhasil diambil',
            200,
            [
                'pagination' => [
                    'current_page' => $jemaats->currentPage(),
                    'per_page' => $jemaats->perPage(),
                    'total' => $jemaats->total(),
                    'last_page' => $jemaats->lastPage(),
                ],
            ]
        );
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:160'],
            'username' => ['required', 'string', 'max:60', 'unique:users,username'],
            'email' => ['required', 'email', 'max:191', 'unique:users,email'],
            'password' => ['required', 'string', Password::min(8)],
            'nomor_kk' => ['required', 'string', 'min:16', 'max:32', 'exists:kk_registrations,nomor_kk'],
            'jenis_kelamin' => ['nullable', 'in:L,P'],
            'usia' => ['nullable', 'integer', 'min:1', 'max:120'],
            'tempat_lahir' => ['nullable', 'string', 'max:100'],
            'tanggal_lahir' => ['nullable', 'date'],
            'alamat' => ['required', 'string'],
            'phone_number' => ['nullable', 'string', 'max:20'],
            'status' => ['nullable', 'in:active,jemaat,simpatisan'],
        ], [
            'nomor_kk.exists' => 'Nomor KK tidak terdaftar di sistem',
            'email.unique' => 'Email sudah terdaftar',
            'username.unique' => 'Username sudah terdaftar',
        ]);

        $user = User::query()->create([
            'name' => $validated['name'],
            'username' => $validated['username'],
            'email' => $validated['email'],
            'password' => $validated['password'],
            'nomor_kk' => $validated['nomor_kk'],
            'jenis_kelamin' => $validated['jenis_kelamin'] ?? null,
            'tempat_lahir' => $validated['tempat_lahir'] ?? null,
            'tanggal_lahir' => $validated['tanggal_lahir'] ?? null,
            'usia' => $validated['usia'] ?? null,
            'alamat' => $validated['alamat'] ?? null,
            'phone_number' => $validated['phone_number'] ?? null,
            'status' => $validated['status'] ?? 'active',
            'role' => 'jemaat',
        ]);

        return $this->successResponse($user, 'Jemaat berhasil ditambahkan', 201);
    }

    public function show(User $jemaat): JsonResponse
    {
        if ($jemaat->role !== 'jemaat') {
            return $this->errorResponse('User bukan jemaat', 'INVALID_ROLE', 422);
        }

        $data = $jemaat->toArray();
        $data['profile_photo_url'] = $jemaat->profile_photo_path
            ? \Illuminate\Support\Facades\Storage::url($jemaat->profile_photo_path)
            : null;

        // Get family members
        if ($jemaat->nomor_kk) {
            $data['family_members'] = User::query()
                ->where('nomor_kk', $jemaat->nomor_kk)
                ->where('role', 'jemaat')
                ->select(['id', 'name', 'username', 'nomor_kk', 'jenis_kelamin', 'usia'])
                ->orderBy('name')
                ->get()
                ->toArray();
        }

        return $this->successResponse($data, 'Detail jemaat berhasil diambil');
    }

    public function update(Request $request, User $jemaat): JsonResponse
    {
        if ($jemaat->role !== 'jemaat') {
            return $this->errorResponse('User bukan jemaat', 'INVALID_ROLE', 422);
        }

        $validated = $request->validate([
            'name' => ['nullable', 'string', 'max:160'],
            'username' => ['nullable', 'string', 'max:60', 'unique:users,username,' . $jemaat->id],
            'email' => ['nullable', 'email', 'max:191', 'unique:users,email,' . $jemaat->id],
            'nomor_kk' => ['nullable', 'string', 'min:16', 'max:32', 'exists:kk_registrations,nomor_kk'],
            'jenis_kelamin' => ['nullable', 'in:L,P'],
            'usia' => ['nullable', 'integer', 'min:1', 'max:120'],
            'tempat_lahir' => ['nullable', 'string', 'max:100'],
            'tanggal_lahir' => ['nullable', 'date'],
            'alamat' => ['required', 'string'],
            'phone_number' => ['nullable', 'string', 'max:20'],
            'status' => ['nullable', 'in:active,jemaat,simpatisan'],
        ]);

        $jemaat->update($validated);

        return $this->successResponse($jemaat->fresh(), 'Jemaat berhasil diperbarui');
    }

    public function destroy(User $jemaat): JsonResponse
    {
        if ($jemaat->role !== 'jemaat') {
            return $this->errorResponse('User bukan jemaat', 'INVALID_ROLE', 422);
        }

        // Optionally, check if user has any active service applications
        if ($jemaat->serviceApplications()->where('status', 'pending')->exists()) {
            return $this->errorResponse('Tidak dapat menghapus jemaat yang memiliki pengajuan layanan aktif', 'ACTIVE_APPLICATIONS_EXIST', 422);
        }

        $jemaat->delete();

        return $this->successResponse(null, 'Jemaat berhasil dihapus');
    }
}
