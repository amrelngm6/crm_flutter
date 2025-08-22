<?php

namespace App\Modules\MobileAPI\Services;

use App\Modules\Customers\Models\Staff;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class AuthService
{
    /**
     * Create access and refresh tokens for staff
     */
    public function createTokens(Staff $staff, string $deviceName = 'mobile-app'): array
    {
        // Delete existing tokens for this device
        $staff->tokens()->where('name', $deviceName)->delete();

        // Create access token (expires in 60 minutes)
        $accessToken = $staff->createToken(
            $deviceName,
            ['*'],
            now()->addMinutes(60)
        );

        // Create refresh token (expires in 30 days)
        $refreshToken = $staff->createToken(
            $deviceName . '_refresh',
            ['refresh'],
            now()->addDays(30)
        );

        // Update last activity timestamp
        $staff->update(['last_activity' => time()]);

        return [
            'access_token' => $accessToken->plainTextToken,
            'refresh_token' => $refreshToken->plainTextToken,
            'token_type' => 'Bearer',
            'expires_in' => 3600, // 60 minutes in seconds
            'refresh_expires_in' => 2592000, // 30 days in seconds
        ];
    }

    /**
     * Refresh access token using refresh token
     */
    public function refreshTokens(string $refreshToken): array
    {
        // Find the refresh token
        $tokenParts = explode('|', $refreshToken);
        if (count($tokenParts) !== 2) {
            throw ValidationException::withMessages([
                'refresh_token' => ['Invalid refresh token format'],
            ]);
        }

        $token = PersonalAccessToken::findToken($refreshToken);
        
        if (!$token || !$token->can('refresh') || $token->expires_at < now()) {
            throw ValidationException::withMessages([
                'refresh_token' => ['Invalid or expired refresh token'],
            ]);
        }

        $staff = $token->tokenable;
        
        if (!$staff instanceof Staff || $staff->status != 1) {
            throw ValidationException::withMessages([
                'refresh_token' => ['Invalid user or user is inactive'],
            ]);
        }

        // Extract device name from token name
        $deviceName = str_replace('_refresh', '', $token->name);

        // Revoke old tokens for this device
        $staff->tokens()
              ->where('name', $deviceName)
              ->orWhere('name', $deviceName . '_refresh')
              ->delete();

        // Create new tokens
        return $this->createTokens($staff, $deviceName);
    }

    /**
     * Validate and get staff from access token
     */
    public function validateAccessToken(string $accessToken): ?Staff
    {
        $token = PersonalAccessToken::findToken($accessToken);
        
        if (!$token || $token->expires_at < now()) {
            return null;
        }

        $staff = $token->tokenable;
        
        if (!$staff instanceof Staff || $staff->status != 1) {
            return null;
        }

        // Update last activity
        $staff->update(['last_activity' => now()]);

        return $staff;
    }

    /**
     * Revoke all tokens for a staff member
     */
    public function revokeAllTokens(Staff $staff): bool
    {
        $staff->tokens()->delete();
        return true;
    }

    /**
     * Revoke specific token
     */
    public function revokeToken(string $token): bool
    {
        $tokenModel = PersonalAccessToken::findToken($token);
        
        if ($tokenModel) {
            $tokenModel->delete();
            return true;
        }

        return false;
    }

    /**
     * Clean expired tokens
     */
    public function cleanExpiredTokens(): int
    {
        return PersonalAccessToken::where('expires_at', '<', now())->delete();
    }
}
