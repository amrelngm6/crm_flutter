<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Requests\LoginRequest;
use App\Modules\MobileAPI\Requests\RefreshTokenRequest;
use App\Modules\MobileAPI\Resources\StaffResource;
use App\Modules\MobileAPI\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    protected AuthService $authService;

    public function __construct(AuthService $authService)
    {
        $this->authService = $authService;
    }

    /**
     * Authenticate staff member and return access token
     */
    public function login(LoginRequest $request): JsonResponse
    {
        try {
            $credentials = $request->validated();
            
            $staff = Staff::where('email', $credentials['email'])
                         ->where('status', 1) // Only active staff
                         ->first();

            if (!$staff || !Hash::check($credentials['password'], $staff->password)) {
                throw ValidationException::withMessages([
                    'email' => ['The provided credentials are incorrect.'],
                ]);
            }

            // Create tokens
            $tokens = $this->authService->createTokens($staff, $request->device_name ?? 'mobile-app');

            return response()->json([
                'success' => true,
                'message' => 'Login successful',
                'data' => [
                    'user' => new StaffResource($staff),
                    'tokens' => $tokens,
                    'business' => [
                        'id' => $staff->business_id,
                        'name' => $staff->business->name ?? null,
                    ]
                ]
            ]);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {

            return response()->json([
                'success' => false,
                'message' => 'Login failed',
                'errors' => ['server' => ['An error occurred during login' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Refresh access token using refresh token
     */
    public function refresh(RefreshTokenRequest $request): JsonResponse
    {
        try {
            $refreshToken = $request->validated()['refresh_token'];
            
            $tokens = $this->authService->refreshTokens($refreshToken);

            return response()->json([
                'success' => true,
                'message' => 'Token refreshed successfully',
                'data' => [
                    'tokens' => $tokens
                ]
            ]);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid refresh token',
                'errors' => $e->errors()
            ], 401);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Token refresh failed',
                'errors' => ['server' => ['An error occurred during token refresh']]
            ], 500);
        }
    }

    /**
     * Get authenticated user profile
     */
    public function profile(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            
            return response()->json([
                'success' => true,
                'data' => [
                    'user' => new StaffResource($staff),
                    'business' => [
                        'id' => $staff->business_id,
                        'name' => $staff->business->name ?? null,
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to get profile',
                'errors' => ['server' => ['An error occurred while fetching profile']]
            ], 500);
        }
    }

    /**
     * Update user profile
     */
    public function updateProfile(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            
            $request->validate([
                'first_name' => 'sometimes|string|max:255',
                'last_name' => 'sometimes|string|max:255',
                'phone' => 'sometimes|string|max:20',
                'about' => 'sometimes|string|max:1000',
                'position' => 'sometimes|string|max:255',
            ]);

            $staff->update($request->only([
                'first_name', 'last_name', 'phone', 'about', 'position'
            ]));

            return response()->json([
                'success' => true,
                'message' => 'Profile updated successfully',
                'data' => [
                    'user' => new StaffResource($staff->fresh()),
                ]
            ]);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Profile update failed',
                'errors' => ['server' => ['An error occurred while updating profile']]
            ], 500);
        }
    }

    /**
     * Change password
     */
    public function changePassword(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            
            $request->validate([
                'current_password' => 'required|string',
                'new_password' => 'required|string|min:8|confirmed',
            ]);

            if (!Hash::check($request->current_password, $staff->password)) {
                throw ValidationException::withMessages([
                    'current_password' => ['The current password is incorrect.'],
                ]);
            }

            $staff->update([
                'password' => Hash::make($request->new_password)
            ]);

            // Revoke all tokens except current one
            $currentToken = $staff->currentAccessToken();
            $staff->tokens()->where('id', '!=', $currentToken->id)->delete();

            return response()->json([
                'success' => true,
                'message' => 'Password changed successfully',
            ]);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Password change failed',
                'errors' => ['server' => ['An error occurred while changing password']]
            ], 500);
        }
    }

    /**
     * Logout and revoke token
     */
    public function logout(Request $request): JsonResponse
    {
        try {
            $request->user()->currentAccessToken()->delete();

            return response()->json([
                'success' => true,
                'message' => 'Logged out successfully'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Logout failed',
                'errors' => ['server' => ['An error occurred during logout']]
            ], 500);
        }
    }

    /**
     * Logout from all devices
     */
    public function logoutAll(Request $request): JsonResponse
    {
        try {
            $request->user()->tokens()->delete();

            return response()->json([
                'success' => true,
                'message' => 'Logged out from all devices successfully'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Logout from all devices failed',
                'errors' => ['server' => ['An error occurred during logout']]
            ], 500);
        }
    }
}
