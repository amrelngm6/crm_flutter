<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Emails\Models\EmailSignature;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Resources\EmailSignatureResource;
use App\Modules\MobileAPI\Requests\EmailSignatureRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EmailSignatureController extends Controller
{
    /**
     * Get email signatures for the authenticated user
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $signatures = EmailSignature::forBusiness($businessId)
                                       ->forUser($staff)
                                       ->orderBy('is_default', 'desc')
                                       ->orderBy('name')
                                       ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'signatures' => EmailSignatureResource::collection($signatures),
                    'total' => $signatures->count(),
                    'has_default' => $signatures->where('is_default', true)->isNotEmpty(),
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch signatures',
                'errors' => ['server' => ['An error occurred while fetching signatures: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single signature
     */
    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $signature = EmailSignature::forBusiness($businessId)
                                      ->forUser($staff)
                                      ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new EmailSignatureResource($signature)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Signature not found',
                'errors' => ['signature' => ['Signature not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch signature',
                'errors' => ['server' => ['An error occurred while fetching signature: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Create new email signature
     */
    public function store(EmailSignatureRequest $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $data = $request->validated();
            $data['business_id'] = $businessId;
            $data['user_id'] = $staff->id;

            // If this is set as default, update other signatures
            if ($data['is_default']) {
                EmailSignature::forBusiness($businessId)
                             ->forUser($staff)
                             ->update(['is_default' => false]);
            }

            $signature = EmailSignature::create($data);

            return response()->json([
                'success' => true,
                'message' => 'Signature created successfully',
                'data' => new EmailSignatureResource($signature)
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create signature',
                'errors' => ['server' => ['An error occurred while creating signature: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Update email signature
     */
    public function update(EmailSignatureRequest $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $signature = EmailSignature::forBusiness($businessId)
                                      ->forUser($staff)
                                      ->findOrFail($id);

            $data = $request->validated();

            // If this is set as default, update other signatures
            if ($data['is_default']) {
                EmailSignature::forBusiness($businessId)
                             ->forUser($staff)
                             ->where('id', '!=', $id)
                             ->update(['is_default' => false]);
            }

            $signature->update($data);

            return response()->json([
                'success' => true,
                'message' => 'Signature updated successfully',
                'data' => new EmailSignatureResource($signature)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Signature not found',
                'errors' => ['signature' => ['Signature not found']]
            ], 404);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update signature',
                'errors' => ['server' => ['An error occurred while updating signature: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete email signature
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $signature = EmailSignature::forBusiness($businessId)
                                      ->forUser($staff)
                                      ->findOrFail($id);

            $signature->delete();

            return response()->json([
                'success' => true,
                'message' => 'Signature deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Signature not found',
                'errors' => ['signature' => ['Signature not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete signature',
                'errors' => ['server' => ['An error occurred while deleting signature: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Set signature as default
     */
    public function setDefault(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $signature = EmailSignature::forBusiness($businessId)
                                      ->forUser($staff)
                                      ->findOrFail($id);

            // Update all signatures to not default
            EmailSignature::forBusiness($businessId)
                         ->forUser($staff)
                         ->update(['is_default' => false]);

            // Set this signature as default
            $signature->update(['is_default' => true]);

            return response()->json([
                'success' => true,
                'message' => 'Default signature updated successfully',
                'data' => new EmailSignatureResource($signature)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Signature not found',
                'errors' => ['signature' => ['Signature not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to set default signature',
                'errors' => ['server' => ['An error occurred while setting default signature: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get default signature
     */
    public function getDefault(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $signature = EmailSignature::forBusiness($businessId)
                                      ->forUser($staff)
                                      ->where('is_default', true)
                                      ->first();

            if (!$signature) {
                return response()->json([
                    'success' => true,
                    'message' => 'No default signature found',
                    'data' => null
                ]);
            }

            return response()->json([
                'success' => true,
                'data' => new EmailSignatureResource($signature)
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch default signature',
                'errors' => ['server' => ['An error occurred while fetching default signature: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Duplicate an existing signature
     */
    public function duplicate(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $originalSignature = EmailSignature::forBusiness($businessId)
                                              ->forUser($staff)
                                              ->findOrFail($id);

            // Create duplicate
            $duplicateData = $originalSignature->toArray();
            unset($duplicateData['id']);
            unset($duplicateData['created_at']);
            unset($duplicateData['updated_at']);
            
            $duplicateData['name'] = $originalSignature->name . ' (Copy)';
            $duplicateData['is_default'] = false; // Duplicates are never default

            $duplicateSignature = EmailSignature::create($duplicateData);

            return response()->json([
                'success' => true,
                'message' => 'Signature duplicated successfully',
                'data' => new EmailSignatureResource($duplicateSignature)
            ], 201);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Signature not found',
                'errors' => ['signature' => ['Signature not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to duplicate signature',
                'errors' => ['server' => ['An error occurred while duplicating signature: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Preview signature HTML
     */
    public function preview(Request $request, int $id): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $signature = EmailSignature::forBusiness($businessId)
                                      ->forUser($staff)
                                      ->findOrFail($id);

            // Replace placeholder variables with actual user data
            $html = $signature->html_content;
            $placeholders = [
                '{{name}}' => $staff->name,
                '{{first_name}}' => $staff->first_name ?? explode(' ', $staff->name)[0] ?? '',
                '{{last_name}}' => $staff->last_name ?? (count(explode(' ', $staff->name)) > 1 ? explode(' ', $staff->name)[1] : ''),
                '{{email}}' => $staff->email,
                '{{phone}}' => $staff->phone ?? '',
                '{{job_title}}' => $staff->job_title ?? '',
                '{{company}}' => $staff->business->name ?? '',
                '{{website}}' => $staff->business->website ?? '',
            ];

            foreach ($placeholders as $placeholder => $value) {
                $html = str_replace($placeholder, $value, $html);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'signature_id' => $signature->id,
                    'name' => $signature->name,
                    'html_content' => $html,
                    'text_content' => strip_tags($html),
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Signature not found',
                'errors' => ['signature' => ['Signature not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to preview signature',
                'errors' => ['server' => ['An error occurred while previewing signature: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get available placeholders for signatures
     */
    public function getPlaceholders(Request $request): JsonResponse
    {
        try {
            $placeholders = [
                [
                    'key' => '{{name}}',
                    'label' => 'Full Name',
                    'description' => 'User\'s full name'
                ],
                [
                    'key' => '{{first_name}}',
                    'label' => 'First Name',
                    'description' => 'User\'s first name'
                ],
                [
                    'key' => '{{last_name}}',
                    'label' => 'Last Name',
                    'description' => 'User\'s last name'
                ],
                [
                    'key' => '{{email}}',
                    'label' => 'Email Address',
                    'description' => 'User\'s email address'
                ],
                [
                    'key' => '{{phone}}',
                    'label' => 'Phone Number',
                    'description' => 'User\'s phone number'
                ],
                [
                    'key' => '{{job_title}}',
                    'label' => 'Job Title',
                    'description' => 'User\'s job title'
                ],
                [
                    'key' => '{{company}}',
                    'label' => 'Company Name',
                    'description' => 'Business/company name'
                ],
                [
                    'key' => '{{website}}',
                    'label' => 'Website',
                    'description' => 'Company website URL'
                ],
            ];

            return response()->json([
                'success' => true,
                'data' => [
                    'placeholders' => $placeholders,
                    'total' => count($placeholders),
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch placeholders',
                'errors' => ['server' => ['An error occurred while fetching placeholders: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get signature templates
     */
    public function getTemplates(Request $request): JsonResponse
    {
        try {
            $templates = [
                [
                    'id' => 'simple',
                    'name' => 'Simple Text',
                    'description' => 'Basic text signature with contact information',
                    'html_content' => '<div style="font-family: Arial, sans-serif; font-size: 14px; color: #333;">
                        <strong>{{name}}</strong><br>
                        {{job_title}}<br>
                        {{company}}<br>
                        Email: {{email}}<br>
                        Phone: {{phone}}
                    </div>'
                ],
                [
                    'id' => 'professional',
                    'name' => 'Professional',
                    'description' => 'Professional signature with separator line',
                    'html_content' => '<div style="font-family: Arial, sans-serif; font-size: 14px; color: #333;">
                        <hr style="border: 1px solid #ccc; margin: 10px 0;">
                        <table>
                            <tr>
                                <td style="padding-right: 20px; vertical-align: top;">
                                    <strong style="color: #2c5aa0;">{{name}}</strong><br>
                                    <span style="color: #666;">{{job_title}}</span><br>
                                    <span style="color: #666;">{{company}}</span>
                                </td>
                                <td style="vertical-align: top;">
                                    <div style="color: #666; font-size: 12px;">
                                        <strong>Email:</strong> {{email}}<br>
                                        <strong>Phone:</strong> {{phone}}<br>
                                        <strong>Website:</strong> {{website}}
                                    </div>
                                </td>
                            </tr>
                        </table>
                    </div>'
                ],
                [
                    'id' => 'modern',
                    'name' => 'Modern',
                    'description' => 'Modern signature with colors and styling',
                    'html_content' => '<div style="font-family: \'Segoe UI\', Tahoma, Geneva, Verdana, sans-serif;">
                        <div style="background: linear-gradient(90deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px; border-radius: 8px;">
                            <h3 style="margin: 0; font-size: 18px;">{{name}}</h3>
                            <p style="margin: 5px 0; opacity: 0.9;">{{job_title}} at {{company}}</p>
                        </div>
                        <div style="padding: 10px 0; color: #333;">
                            <div style="font-size: 14px;">
                                📧 {{email}} | 📞 {{phone}}<br>
                                🌐 {{website}}
                            </div>
                        </div>
                    </div>'
                ],
                [
                    'id' => 'minimal',
                    'name' => 'Minimal',
                    'description' => 'Clean and minimal signature design',
                    'html_content' => '<div style="font-family: Georgia, serif; font-size: 14px; color: #444; border-left: 3px solid #007acc; padding-left: 15px;">
                        <div style="font-weight: bold; font-size: 16px; margin-bottom: 5px;">{{name}}</div>
                        <div style="color: #666; margin-bottom: 3px;">{{job_title}}</div>
                        <div style="color: #666; margin-bottom: 8px;">{{company}}</div>
                        <div style="font-size: 12px; color: #888;">
                            {{email}} • {{phone}}
                        </div>
                    </div>'
                ]
            ];

            return response()->json([
                'success' => true,
                'data' => [
                    'templates' => $templates,
                    'total' => count($templates),
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch templates',
                'errors' => ['server' => ['An error occurred while fetching templates: ' . $e->getMessage()]]
            ], 500);
        }
    }
}
