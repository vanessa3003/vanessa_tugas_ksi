<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class ProjectUpdate extends Command
{
    protected $signature = 'projectupdate';
    protected $description = 'Command description for ProjectUpdate';

    public function handle()
    {
        // Logic for ProjectUpdate
        $this->info('ProjectUpdate executed');
    }
}
