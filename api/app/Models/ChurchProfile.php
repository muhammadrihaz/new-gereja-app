<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ChurchProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'address',
        'phone',
        'email',
        'logo',
        'metadata',
    ];

    protected function casts(): array
    {
        return [
            'logo' => 'array',
            'metadata' => 'array',
        ];
    }
}
