<?php

namespace App\Http\Controllers;

use App\Models\ServiceApplication;
use App\Support\ApiResponse;
use App\Models\User;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ServiceApplicationExportController extends Controller
{
    use ApiResponse;

    public function exportApplicationPdf(ServiceApplication $application): Response
    {
        /** @var User|null $user */
        $user = auth('sanctum')->user();

        // Verify authorization - user can only download their own or admin can download any
        if ($user && ($user->id === $application->user_id || $user->role === 'admin')) {
            // TODO: Implement PDF generation logic using Laravel DomPDF or similar
            // For now, return a placeholder response
            return response()->download(storage_path('app/placeholder.pdf'), 'aplikasi-layanan-' . $application->id . '.pdf');
        }

        return response('Unauthorized', 403);
    }

    public function exportAllApplicationsCsv(Request $request): Response
    {
        $perPage = min((int) $request->query('per_page', 100000), 100000);
        $query = ServiceApplication::query();

        // Filter by status if provided
        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        // Filter by date range if provided
        if ($fromDate = $request->query('from_date')) {
            $query->whereDate('created_at', '>=', $fromDate);
        }

        if ($toDate = $request->query('to_date')) {
            $query->whereDate('created_at', '<=', $toDate);
        }

        $applications = $query->with('user')->limit($perPage)->get();

        $csv = $this->generateCsv($applications);

        return response($csv, 200, [
            'Content-Type' => 'text/csv; charset=utf-8',
            'Content-Disposition' => 'attachment; filename="pengajuan-layanan-' . now()->format('Y-m-d-H-i-s') . '.csv"',
        ]);
    }

    private function generateCsv($applications): string
    {
        $headers = [
            'ID',
            'Nama Jemaat',
            'Username',
            'Email',
            'Nomor KK',
            'Kategori Layanan',
            'Status',
            'Tanggal Pengajuan',
            'Catatan Admin',
        ];

        $csv = implode(',', $this->escapeCsvFields($headers)) . "\n";

        foreach ($applications as $app) {
            $row = [
                $app->id,
                $app->user->name ?? 'N/A',
                $app->user->username ?? 'N/A',
                $app->user->email ?? 'N/A',
                $app->nomor_kk_snapshot ?? $app->user->nomor_kk ?? 'N/A',
                $app->category ?? 'N/A',
                $app->status ?? 'N/A',
                $app->created_at?->format('Y-m-d H:i:s') ?? 'N/A',
                $app->admin_notes ?? '',
            ];

            $csv .= implode(',', $this->escapeCsvFields($row)) . "\n";
        }

        return $csv;
    }

    private function escapeCsvFields(array $fields): array
    {
        return array_map(function ($field) {
            $field = str_replace('"', '""', $field ?? '');

            if (str_contains($field, ',') || str_contains($field, '"') || str_contains($field, "\n")) {
                return '"' . $field . '"';
            }

            return $field;
        }, $fields);
    }
}
