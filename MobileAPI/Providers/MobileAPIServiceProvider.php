<?php

namespace App\Modules\MobileAPI\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Route;

class MobileAPIServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        // Register services
        $this->app->bind(
            \App\Modules\MobileAPI\Services\AuthService::class,
            \App\Modules\MobileAPI\Services\AuthService::class
        );
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Load routes
        $this->loadRoutes();
        
        // Load views if needed
        // $this->loadViewsFrom(__DIR__.'/../views', 'mobile-api');
        
        // Load migrations if needed
        // $this->loadMigrationsFrom(__DIR__.'/../migrations');
    }

    /**
     * Load the mobile API routes
     */
    protected function loadRoutes(): void
    {
        Route::prefix('api')
            ->middleware('api')
            ->group(__DIR__ . '/../routes/api.php');
    }
}
