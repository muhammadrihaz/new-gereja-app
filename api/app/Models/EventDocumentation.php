<?php

namespace App\Models;

use App\Models\Event;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EventDocumentation extends Model
{
    use HasFactory;

    protected $fillable = [
        'event_id',
        'file_path',
        'mime_type',
        'file_size',
        'report_summary',
    ];

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }
}
