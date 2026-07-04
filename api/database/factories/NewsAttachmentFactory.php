<?php

namespace Database\Factories;

use App\Models\NewsAttachment;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<NewsAttachment>
 */
class NewsAttachmentFactory extends Factory
{
    protected $model = NewsAttachment::class;

    public function definition(): array
    {
        return [
            'news_id' => \App\Models\News::factory(),
            'file_path' => 'news-attachments/test/' . $this->faker->uuid() . '.jpg',
            'file_name' => $this->faker->word() . '.jpg',
            'mime_type' => 'image/jpeg',
            'file_size' => $this->faker->numberBetween(10000, 500000),
        ];
    }
}
