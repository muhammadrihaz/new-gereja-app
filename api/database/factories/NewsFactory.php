<?php

namespace Database\Factories;

use App\Models\News;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<News>
 */
class NewsFactory extends Factory
{
    protected $model = News::class;

    public function definition(): array
    {
        return [
            'title' => $this->faker->sentence(4),
            'description' => $this->faker->sentence(10),
            'content' => $this->faker->paragraphs(3, true),
            'cover_image' => null,
            'created_by' => User::factory(),
            'published_at' => now()->subHours($this->faker->numberBetween(1, 72)),
        ];
    }
}
