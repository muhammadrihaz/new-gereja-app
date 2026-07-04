<?php

namespace App\Http\Controllers;

use App\Models\EventCategory;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class EventCategoryController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        $categories = EventCategory::query()
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        return $this->successResponse($categories, 'Kategori event berhasil diambil');
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => ['required', 'string', 'max:80', 'unique:event_categories,code'],
            'name' => ['required', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $category = EventCategory::query()->create([
            'code' => $validated['code'],
            'name' => $validated['name'],
            'sort_order' => $validated['sort_order'] ?? 0,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        Cache::forget('event_categories.active');

        return $this->successResponse($category, 'Kategori event berhasil dibuat', 201);
    }

    public function update(Request $request, EventCategory $category): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $category->update($validated);

        Cache::forget('event_categories.active');

        return $this->successResponse($category, 'Kategori event berhasil diperbarui');
    }

    public function destroy(EventCategory $category): JsonResponse
    {
        $category->delete();

        Cache::forget('event_categories.active');

        return $this->successResponse(null, 'Kategori event berhasil dihapus');
    }
}
