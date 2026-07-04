<?php

namespace Database\Factories;

use App\Models\Event;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Event>
 */
class EventFactory extends Factory
{
    protected $model = Event::class;

    public function definition(): array
    {
        $startAt = now()->addDays(3)->setHour(9)->setMinute(0);

        return [
            'title' => $this->faker->sentence(3),
            'description' => $this->faker->paragraph(),
            'date' => $startAt,
            'start_at' => $startAt,
            'end_at' => (clone $startAt)->addHours(2),
            'location' => [
                'address' => $this->faker->address(),
                'latitude' => -8.67,
                'longitude' => 115.21,
            ],
            'category' => 'ibadah',
            'created_by' => User::factory(),
        ];
    }
}
