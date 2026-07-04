<?php

namespace App\Services;

use App\Models\ServiceApplication;
use App\Models\UserDevice;
use Illuminate\Database\Eloquent\Builder;

class NotificationTargetingService
{
    public function resolveTargetTokens(string $targetType, array $filters = []): array
    {
        return collect($this->resolveTargetDevices($targetType, $filters))
            ->pluck('fcm_token')
            ->unique()
            ->values()
            ->all();
    }

    /**
     * @return list<array{user_id:int,fcm_token:string}>
     */
    public function resolveTargetDevices(string $targetType, array $filters = []): array
    {
        $query = UserDevice::query();

        match ($targetType) {
            'all' => $query,
            'role' => $this->applyRoleFilter($query, $filters),
            'users' => $this->applyUsersFilter($query, $filters),
            'event_attendees' => $this->applyEventAttendeesFallback($query, $filters),
            'service_applicants' => $this->applyServiceApplicantsFilter($query, $filters),
            default => $query->whereRaw('1 = 0'),
        };

        return $query
            ->get(['user_id', 'fcm_token'])
            ->unique('fcm_token')
            ->map(fn(UserDevice $device) => [
                'user_id' => (int) $device->user_id,
                'fcm_token' => (string) $device->fcm_token,
            ])
            ->values()
            ->all();
    }

    private function applyRoleFilter(Builder $query, array $filters): void
    {
        $role = $filters['role'] ?? null;
        $query->whereHas('user', fn(Builder $builder) => $builder->where('role', $role));
    }

    private function applyUsersFilter(Builder $query, array $filters): void
    {
        $userIds = $filters['user_ids'] ?? [];
        $query->whereIn('user_id', $userIds);
    }

    private function applyEventAttendeesFallback(Builder $query, array $filters): void
    {
        // Attendance module is not available yet. Fallback to jemaat role filtering.
        $query->whereHas('user', fn(Builder $builder) => $builder->where('role', 'jemaat'));
    }

    private function applyServiceApplicantsFilter(Builder $query, array $filters): void
    {
        $category = $filters['service_category'] ?? null;
        $status = $filters['service_status'] ?? null;

        $serviceQuery = ServiceApplication::query()->select('user_id')->distinct();

        if (is_string($category) && $category !== '') {
            $serviceQuery->where('category', $category);
        }

        if (is_string($status) && $status !== '') {
            $serviceQuery->where('status', $status);
        }

        $userIds = $serviceQuery->pluck('user_id');
        $query->whereIn('user_id', $userIds);
    }
}
