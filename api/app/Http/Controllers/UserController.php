<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $role = $request->query('role');
        $search = trim((string) $request->query('search', ''));
        $perPage = min((int) $request->query('per_page', 30), 100);

        $query = User::query()->select(['id', 'name', 'username', 'email', 'phone_number', 'role', 'nomor_kk', 'jenis_kelamin', 'tempat_lahir', 'tanggal_lahir', 'usia', 'alamat', 'status']);

        if (is_string($role) && $role !== '') {
            $query->where('role', $role);
        }

        if ($search !== '') {
            $query->where(function ($q) use ($search): void {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('nomor_kk', 'like', "%{$search}%");
            });
        }

        $users = $query->orderBy('name')->paginate($perPage);

        return $this->successResponse(
            $users->items(),
            'Daftar pengguna berhasil diambil',
            200,
            [
                'meta' => [
                    'current_page' => $users->currentPage(),
                    'per_page' => $users->perPage(),
                    'total' => $users->total(),
                    'last_page' => $users->lastPage(),
                ],
            ]
        );
    }

    public function families(Request $request): JsonResponse
    {
        $search = trim((string) $request->query('search', ''));
        $perPage = min((int) $request->query('per_page', 10), 100);

        $baseQuery = User::query()
            ->where('role', 'jemaat')
            ->whereNotNull('nomor_kk')
            ->where('nomor_kk', '!=', '');

        if ($search !== '') {
            $baseQuery->where(function ($q) use ($search): void {
                $q->where('nomor_kk', 'like', "%{$search}%")
                    ->orWhere('name', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $groupedKk = (clone $baseQuery)
            ->select('nomor_kk')
            ->groupBy('nomor_kk')
            ->orderBy('nomor_kk')
            ->paginate($perPage);

        $kkNumbers = collect($groupedKk->items())
            ->pluck('nomor_kk')
            ->filter(fn($value) => is_string($value) && $value !== '')
            ->values()
            ->all();

        $membersByKk = (clone $baseQuery)
            ->whereIn('nomor_kk', $kkNumbers)
            ->select(['id', 'name', 'username', 'email', 'phone_number', 'nomor_kk', 'jenis_kelamin', 'tempat_lahir', 'tanggal_lahir', 'usia', 'alamat', 'status'])
            ->orderBy('name')
            ->get()
            ->groupBy('nomor_kk');

        $data = collect($kkNumbers)->map(function (string $nomorKk) use ($membersByKk): array {
            $members = $membersByKk->get($nomorKk, collect())->values();

            return [
                'nomor_kk' => $nomorKk,
                'total_members' => $members->count(),
                'members' => $members,
            ];
        })->values();

        return $this->successResponse(
            $data,
            'Daftar keluarga jemaat berhasil diambil',
            200,
            [
                'meta' => [
                    'current_page' => $groupedKk->currentPage(),
                    'per_page' => $groupedKk->perPage(),
                    'total' => $groupedKk->total(),
                    'last_page' => $groupedKk->lastPage(),
                ],
            ]
        );
    }

    public function familyMembers(): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();

        if (! $user->nomor_kk) {
            return $this->errorResponse('Anda belum memiliki nomor KK', 'NO_KK_REGISTERED', 422);
        }

        $members = User::query()
            ->where('nomor_kk', $user->nomor_kk)
            ->where('role', 'jemaat')
            ->select(['id', 'name', 'username', 'email', 'nomor_kk', 'jenis_kelamin', 'tempat_lahir', 'tanggal_lahir', 'usia', 'alamat', 'phone_number', 'status', 'profile_photo_path'])
            ->orderBy('name')
            ->get()
            ->map(function (User $member) {
                $data = $member->toArray();
                $data['profile_photo_url'] = $member->profile_photo_path
                    ? \Illuminate\Support\Facades\Storage::url($member->profile_photo_path)
                    : null;

                return $data;
            });

        return $this->successResponse([
            'nomor_kk' => $user->nomor_kk,
            'total_members' => $members->count(),
            'members' => $members,
        ], 'Data keluarga berhasil diambil');
    }
}
