<?php

namespace App\Modules\MobileAPI\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Emails\Models\EmailAccount;
use App\Modules\Emails\Models\EmailMessage;
use App\Modules\Emails\Models\EmailAttachment;
use App\Modules\Customers\Models\Staff;
use App\Modules\MobileAPI\Resources\EmailAttachmentResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Response;

class EmailAttachmentController extends Controller
{
    /**
     * Get attachments for a specific email message
     */
    public function index(Request $request, int $messageId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $emailMessage = EmailMessage::forBusiness($businessId)
                                       ->whereIn('account_id', $userAccountIds)
                                       ->findOrFail($messageId);

            $attachments = EmailAttachment::where('message_id', $emailMessage->id)
                                         ->orderBy('filename')
                                         ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'attachments' => EmailAttachmentResource::collection($attachments),
                    'message_id' => $emailMessage->id,
                    'total_attachments' => $attachments->count(),
                    'total_size' => $attachments->sum('size'),
                ]
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Email message not found',
                'errors' => ['email_message' => ['Email message not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch attachments',
                'errors' => ['server' => ['An error occurred while fetching attachments: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get single attachment details
     */
    public function show(Request $request, int $messageId, int $attachmentId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $emailMessage = EmailMessage::forBusiness($businessId)
                                       ->whereIn('account_id', $userAccountIds)
                                       ->findOrFail($messageId);

            $attachment = EmailAttachment::where('message_id', $emailMessage->id)
                                        ->where('id', $attachmentId)
                                        ->firstOrFail();

            return response()->json([
                'success' => true,
                'data' => new EmailAttachmentResource($attachment)
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Attachment not found',
                'errors' => ['attachment' => ['Attachment not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch attachment',
                'errors' => ['server' => ['An error occurred while fetching attachment: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Download attachment
     */
    public function download(Request $request, int $messageId, int $attachmentId)
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $emailMessage = EmailMessage::forBusiness($businessId)
                                       ->whereIn('account_id', $userAccountIds)
                                       ->findOrFail($messageId);

            $attachment = EmailAttachment::where('message_id', $emailMessage->id)
                                        ->where('id', $attachmentId)
                                        ->firstOrFail();

            // Check if file exists in storage
            if (!Storage::exists($attachment->file_path)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Attachment file not found',
                    'errors' => ['file' => ['Attachment file not found on server']]
                ], 404);
            }

            // Get file content and headers
            $fileContent = Storage::get($attachment->file_path);
            $headers = [
                'Content-Type' => $attachment->mime_type ?? 'application/octet-stream',
                'Content-Disposition' => 'attachment; filename="' . $attachment->filename . '"',
                'Content-Length' => strlen($fileContent),
            ];

            return Response::make($fileContent, 200, $headers);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Attachment not found',
                'errors' => ['attachment' => ['Attachment not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to download attachment',
                'errors' => ['server' => ['An error occurred while downloading attachment: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get attachment preview (for images/documents)
     */
    public function preview(Request $request, int $messageId, int $attachmentId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $emailMessage = EmailMessage::forBusiness($businessId)
                                       ->whereIn('account_id', $userAccountIds)
                                       ->findOrFail($messageId);

            $attachment = EmailAttachment::where('message_id', $emailMessage->id)
                                        ->where('id', $attachmentId)
                                        ->firstOrFail();

            // Check if attachment is previewable (images, text files, PDFs)
            $previewableMimes = [
                'image/jpeg', 'image/png', 'image/gif', 'image/webp',
                'text/plain', 'text/html', 'text/css', 'text/javascript',
                'application/pdf'
            ];

            $isPreviewable = in_array($attachment->mime_type, $previewableMimes);

            if (!$isPreviewable) {
                return response()->json([
                    'success' => false,
                    'message' => 'Attachment is not previewable',
                    'errors' => ['preview' => ['This file type cannot be previewed']]
                ], 422);
            }

            // Check if file exists in storage
            if (!Storage::exists($attachment->file_path)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Attachment file not found',
                    'errors' => ['file' => ['Attachment file not found on server']]
                ], 404);
            }

            $previewData = [
                'id' => $attachment->id,
                'filename' => $attachment->filename,
                'mime_type' => $attachment->mime_type,
                'size' => $attachment->size,
                'is_image' => strpos($attachment->mime_type, 'image/') === 0,
                'is_text' => strpos($attachment->mime_type, 'text/') === 0,
                'is_pdf' => $attachment->mime_type === 'application/pdf',
            ];

            // For text files, include content
            if (strpos($attachment->mime_type, 'text/') === 0 && $attachment->size < 1024 * 1024) { // Max 1MB for text preview
                $previewData['content'] = Storage::get($attachment->file_path);
            }

            // For images, include base64 data
            if (strpos($attachment->mime_type, 'image/') === 0 && $attachment->size < 5 * 1024 * 1024) { // Max 5MB for image preview
                $fileContent = Storage::get($attachment->file_path);
                $previewData['base64_data'] = 'data:' . $attachment->mime_type . ';base64,' . base64_encode($fileContent);
            }

            return response()->json([
                'success' => true,
                'data' => $previewData
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Attachment not found',
                'errors' => ['attachment' => ['Attachment not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to preview attachment',
                'errors' => ['server' => ['An error occurred while previewing attachment: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Upload attachment for email composition
     */
    public function upload(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            $request->validate([
                'file' => 'required|file|max:25600', // Max 25MB
                'message_id' => 'nullable|exists:email_messages,id',
            ]);

            $file = $request->file('file');
            
            // Validate file type (basic security)
            $allowedMimes = [
                'application/pdf',
                'application/msword',
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                'application/vnd.ms-excel',
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'application/vnd.ms-powerpoint',
                'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                'text/plain',
                'text/csv',
                'image/jpeg',
                'image/png',
                'image/gif',
                'image/webp',
                'application/zip',
                'application/x-rar-compressed',
            ];

            if (!in_array($file->getMimeType(), $allowedMimes)) {
                return response()->json([
                    'success' => false,
                    'message' => 'File type not allowed',
                    'errors' => ['file' => ['This file type is not allowed']]
                ], 422);
            }

            // Store file
            $fileName = time() . '_' . $file->getClientOriginalName();
            $filePath = $file->storeAs('email_attachments', $fileName, 'local');

            // Create attachment record
            $attachmentData = [
                'message_id' => $request->message_id,
                'filename' => $file->getClientOriginalName(),
                'file_path' => $filePath,
                'mime_type' => $file->getMimeType(),
                'size' => $file->getSize(),
                'business_id' => $businessId,
            ];

            $attachment = EmailAttachment::create($attachmentData);

            return response()->json([
                'success' => true,
                'message' => 'File uploaded successfully',
                'data' => new EmailAttachmentResource($attachment)
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
                'message' => 'Failed to upload file',
                'errors' => ['server' => ['An error occurred while uploading file: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Delete attachment
     */
    public function destroy(Request $request, int $messageId, int $attachmentId): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Get user's account IDs to ensure access control
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $emailMessage = EmailMessage::forBusiness($businessId)
                                       ->whereIn('account_id', $userAccountIds)
                                       ->findOrFail($messageId);

            $attachment = EmailAttachment::where('message_id', $emailMessage->id)
                                        ->where('id', $attachmentId)
                                        ->firstOrFail();

            // Delete file from storage
            if (Storage::exists($attachment->file_path)) {
                Storage::delete($attachment->file_path);
            }

            // Delete attachment record
            $attachment->delete();

            return response()->json([
                'success' => true,
                'message' => 'Attachment deleted successfully'
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Attachment not found',
                'errors' => ['attachment' => ['Attachment not found']]
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete attachment',
                'errors' => ['server' => ['An error occurred while deleting attachment: ' . $e->getMessage()]]
            ], 500);
        }
    }

    /**
     * Get attachment statistics
     */
    public function getStatistics(Request $request): JsonResponse
    {
        try {
            $staff = $request->user();
            $businessId = $staff->business_id;

            // Get user's account IDs
            $userAccountIds = EmailAccount::forBusiness($businessId)
                                         ->forUser($staff)
                                         ->pluck('id');

            $totalAttachments = EmailAttachment::whereHas('message', function($query) use ($businessId, $userAccountIds) {
                $query->forBusiness($businessId)
                      ->whereIn('account_id', $userAccountIds);
            })->count();

            $totalSize = EmailAttachment::whereHas('message', function($query) use ($businessId, $userAccountIds) {
                $query->forBusiness($businessId)
                      ->whereIn('account_id', $userAccountIds);
            })->sum('size');

            // File type breakdown
            $fileTypeBreakdown = EmailAttachment::whereHas('message', function($query) use ($businessId, $userAccountIds) {
                $query->forBusiness($businessId)
                      ->whereIn('account_id', $userAccountIds);
            })
            ->selectRaw('mime_type, COUNT(*) as count, SUM(size) as total_size')
            ->groupBy('mime_type')
            ->orderByDesc('count')
            ->get();

            // Size breakdown
            $sizeRanges = [
                'small' => EmailAttachment::whereHas('message', function($query) use ($businessId, $userAccountIds) {
                    $query->forBusiness($businessId)
                          ->whereIn('account_id', $userAccountIds);
                })->where('size', '<', 1024 * 1024)->count(), // < 1MB

                'medium' => EmailAttachment::whereHas('message', function($query) use ($businessId, $userAccountIds) {
                    $query->forBusiness($businessId)
                          ->whereIn('account_id', $userAccountIds);
                })->whereBetween('size', [1024 * 1024, 10 * 1024 * 1024])->count(), // 1MB - 10MB

                'large' => EmailAttachment::whereHas('message', function($query) use ($businessId, $userAccountIds) {
                    $query->forBusiness($businessId)
                          ->whereIn('account_id', $userAccountIds);
                })->where('size', '>', 10 * 1024 * 1024)->count(), // > 10MB
            ];

            return response()->json([
                'success' => true,
                'data' => [
                    'overview' => [
                        'total_attachments' => $totalAttachments,
                        'total_size' => $totalSize,
                        'total_size_mb' => round($totalSize / (1024 * 1024), 2),
                        'average_size' => $totalAttachments > 0 ? round($totalSize / $totalAttachments, 2) : 0,
                    ],
                    'file_type_breakdown' => $fileTypeBreakdown->map(function($item) {
                        return [
                            'mime_type' => $item->mime_type,
                            'count' => $item->count,
                            'total_size' => $item->total_size,
                            'total_size_mb' => round($item->total_size / (1024 * 1024), 2),
                        ];
                    }),
                    'size_ranges' => $sizeRanges,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch attachment statistics',
                'errors' => ['server' => ['An error occurred while fetching statistics: ' . $e->getMessage()]]
            ], 500);
        }
    }
}
