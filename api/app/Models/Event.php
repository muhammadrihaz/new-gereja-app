<?php

namespace App\Models;

use App\Models\EventDocumentation;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Event extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'date',
        'start_at',
        'end_at',
        'location',
        'category',
        'is_archived',
        'archived_at',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'datetime',
            'start_at' => 'datetime',
            'end_at' => 'datetime',
            'archived_at' => 'datetime',
            'location' => 'array',
            'is_archived' => 'boolean',
        ];
    }

    /**
     * Scope: only events visible to jemaat/members (active + upcoming, not archived).
     */
    public function scopeVisibleToMembers($query)
    {
        return $query->where('is_archived', false);
    }

    /**
     * An event is considered "expired" when its end_at (or start_at fallback) is in the past.
     */
    public function isExpired(?\DateTimeInterface $now = null): bool
    {
        $reference = $this->end_at ?? $this->start_at ?? $this->date;
        if ($reference === null) {
            return false;
        }
        $now = $now ?? now();
        return $reference->lessThan($now);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function documentations(): HasMany
    {
        return $this->hasMany(EventDocumentation::class);
    }
}
