<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class KKRegistration extends Model
{
    use HasFactory;

    protected $table = 'kk_registrations';

    protected $fillable = [
        'nomor_kk',
        'nama_kepala_keluarga',
        'alamat',
        'phone_number',
        'registered_by',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function registeredBy()
    {
        return $this->belongsTo(User::class, 'registered_by');
    }

    public function members(): HasMany
    {
        return $this->hasMany(User::class, 'nomor_kk', 'nomor_kk');
    }
}
