<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotificationDispatchLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'sender_user_id',
        'recipient_user_id',
        'fcm_token',
        'module',
        'event_type',
        'title',
        'message',
        'context',
        'status',
        'provider',
        'trace_id',
        'provider_response',
        'read_at',
    ];

    protected function casts(): array
    {
        return [
            'context' => 'array',
            'provider_response' => 'array',
            'read_at' => 'datetime',
        ];
    }
}
