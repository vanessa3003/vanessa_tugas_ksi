<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class Recache extends Command
{
    protected $signature = 'recache';
    protected $description = 'Command description for Recache';

    public function handle()
    {
        // Logic for Recache
        $this->info('Recache executed');
    }
}
