<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ServiceApplication extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'nomor_kk_snapshot',
        'category',
        'form_data',
        'attachments',
        'status',
        'admin_note',
        'service_date',
        'service_time',
    ];

    protected function casts(): array
    {
        return [
            'form_data' => 'array',
            'attachments' => 'encrypted:array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
