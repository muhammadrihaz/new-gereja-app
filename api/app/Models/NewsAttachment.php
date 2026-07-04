<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NewsAttachment extends Model
{
    use HasFactory;

    protected $fillable = [
        'news_id',
        'file_path',
        'file_name',
        'mime_type',
        'file_size',
    ];

    public function news(): BelongsTo
    {
        return $this->belongsTo(News::class);
    }
}
