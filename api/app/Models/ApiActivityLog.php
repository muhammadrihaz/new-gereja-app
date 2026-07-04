<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ApiActivityLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'trace_id',
        'method',
        'path',
        'route_name',
        'query_params',
        'request_body',
        'response_body',
        'status_code',
        'duration_ms',
        'ip_address',
        'user_agent',
        'user_id',
    ];

    protected function casts(): array
    {
        return [
            'query_params' => 'array',
            'request_body' => 'array',
            'response_body' => 'array',
            'duration_ms' => 'integer',
            'status_code' => 'integer',
            'user_id' => 'integer',
        ];
    }
}
