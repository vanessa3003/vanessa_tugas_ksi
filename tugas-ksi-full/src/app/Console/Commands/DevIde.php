<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class DevIde extends Command
{
    protected $signature = 'devide';
    protected $description = 'Command description for DevIde';

    public function handle()
    {
        // Logic for DevIde
        $this->info('DevIde executed');
    }
}
