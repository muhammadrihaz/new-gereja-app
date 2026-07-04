<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Mail;

class SendTestEmailCommand extends Command
{
    protected $signature = 'notifications:test-email {email} {--subject=Test Email} {--message=Test email dari sistem}';

    protected $description = 'Send a test email using the configured mailer.';

    public function handle(): int
    {
        $email = (string) $this->argument('email');
        $subject = (string) $this->option('subject');
        $message = (string) $this->option('message');

        Mail::raw($message, function ($mail) use ($email, $subject): void {
            $mail->to($email)->subject($subject);
        });

        $this->info('Email sent to ' . $email);

        return Command::SUCCESS;
    }
}
