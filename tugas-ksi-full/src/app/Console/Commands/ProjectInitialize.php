<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class ProjectInitialize extends Command
{
    protected $signature = 'projectinitialize';
    protected $description = 'Command description for ProjectInitialize';

    public function handle()
    {
        // Logic for ProjectInitialize
        $this->info('ProjectInitialize executed');
    }
}
