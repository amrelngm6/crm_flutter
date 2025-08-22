<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Mobile API Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration settings for the MediansCRM Mobile API
    |
    */

    'version' => '1.0.0',

    /*
    |--------------------------------------------------------------------------
    | Authentication Settings
    |--------------------------------------------------------------------------
    */
    'auth' => [
        'access_token_expiry' => 60, // minutes
        'refresh_token_expiry' => 30 * 24 * 60, // 30 days in minutes
        'max_tokens_per_user' => 5, // Maximum concurrent tokens per user
        'token_cleanup_enabled' => true, // Auto cleanup expired tokens
    ],

    /*
    |--------------------------------------------------------------------------
    | API Limits
    |--------------------------------------------------------------------------
    */
    'limits' => [
        'pagination_max_per_page' => 100,
        'pagination_default_per_page' => 20,
        'search_max_results' => 500,
        'max_file_upload_size' => 10 * 1024 * 1024, // 10MB
    ],

    /*
    |--------------------------------------------------------------------------
    | Rate Limiting
    |--------------------------------------------------------------------------
    */
    'rate_limiting' => [
        'authenticated_requests' => '60:1', // 60 requests per minute
        'guest_requests' => '30:1', // 30 requests per minute
        'login_attempts' => '5:1', // 5 login attempts per minute
    ],

    /*
    |--------------------------------------------------------------------------
    | Features
    |--------------------------------------------------------------------------
    */
    'features' => [
        'leads_management' => true,
        'tasks_management' => true,
        'clients_management' => true,
        'meetings_management' => true,
        'projects_management' => true,
        'invoices_management' => true,
        'notifications' => true,
        'dashboard_analytics' => true,
        'file_uploads' => true,
        'offline_sync' => false, // Future feature
    ],

    /*
    |--------------------------------------------------------------------------
    | Security Settings
    |--------------------------------------------------------------------------
    */
    'security' => [
        'force_https' => env('MOBILE_API_FORCE_HTTPS', true),
        'cors_enabled' => true,
        'csrf_protection' => false, // Disabled for mobile API
        'input_sanitization' => true,
    ],

    /*
    |--------------------------------------------------------------------------
    | Logging
    |--------------------------------------------------------------------------
    */
    'logging' => [
        'enabled' => true,
        'log_requests' => env('MOBILE_API_LOG_REQUESTS', false),
        'log_responses' => env('MOBILE_API_LOG_RESPONSES', false),
        'log_errors' => true,
    ],

    /*
    |--------------------------------------------------------------------------
    | Cache Settings
    |--------------------------------------------------------------------------
    */
    'cache' => [
        'enabled' => true,
        'default_ttl' => 300, // 5 minutes
        'user_profile_ttl' => 600, // 10 minutes
        'dropdown_data_ttl' => 1800, // 30 minutes
    ],
];
