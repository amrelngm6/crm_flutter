<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EstimateResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'estimate_number' => $this->estimate_number,
            'title' => $this->title,
            'content' => $this->content,
            'status' => [
                'id' => $this->status_id,
                'name' => $this->status->name ?? 'Unknown',
                'color' => $this->status->color ?? '#6c757d',
            ],
            'approval' => [
                'status' => $this->approval_status,
                'requires_approval' => $this->requiresApproval(),
                'is_approved' => $this->approval_status === 'approved',
                'is_rejected' => $this->approval_status === 'rejected',
                'is_pending' => $this->approval_status === 'pending',
            ],
            'dates' => [
                'date' => $this->date,
                'expiry_date' => $this->expiry_date,
                'is_expired' => $this->isExpired(),
                'days_until_expiry' => $this->expiry_date ? 
                    max(0, (strtotime($this->expiry_date) - time()) / (60 * 60 * 24)) : null,
                'converted_at' => $this->converted_at,
            ],
            'financial' => [
                'currency_code' => $this->currency_code,
                'subtotal' => $this->subtotal,
                'discount_amount' => $this->discount_amount,
                'tax_amount' => $this->tax_amount,
                'total' => $this->total,
                'formatted_total' => $this->formatCurrency($this->total, $this->currency_code),
            ],
            'conversion' => [
                'converted_to_invoice' => $this->converted_to_invoice,
                'is_converted' => $this->isConvertedToInvoice(),
                'invoice_id' => $this->invoice_id,
                'invoice' => $this->when($this->invoice, [
                    'id' => $this->invoice->id ?? null,
                    'invoice_number' => $this->invoice->invoice_number ?? null,
                    'status' => $this->invoice->status ?? null,
                ]),
            ],
            'client' => $this->when($this->client, [
                'id' => $this->client->client_id ?? null,
                'name' => $this->client->name ?? null,
                'email' => $this->client->email ?? null,
                'phone' => $this->client->phone ?? null,
                'company_name' => $this->client->company_name ?? null,
                'avatar' => $this->client ? $this->client->avatar() : null,
            ]),
            'assigned_to' => $this->when($this->assignedTo, [
                'id' => $this->assignedTo->staff_id ?? null,
                'name' => $this->assignedTo->name ?? 'Unknown',
                'email' => $this->assignedTo->email ?? null,
                'avatar' => isset($this->assignedTo->user) ? $this->assignedTo->user->avatar() : null,
            ]),
            'model' => [
                'id' => $this->model_id,
                'type' => $this->model_type,
                'name' => $this->modelName(),
                'details' => $this->when($this->model, [
                    'name' => $this->model->name ?? null,
                    'title' => $this->model->title ?? null,
                ]),
            ],
            'items' => $this->whenLoaded('items', function() {
                return [
                    'count' => $this->items->count(),
                    'items' => $this->items->map(function($item) {
                        return [
                            'id' => $item->id,
                            'item_name' => $item->item_name,
                            'description' => $item->description,
                            'quantity' => $item->quantity,
                            'unit_price' => $item->unit_price,
                            'subtotal' => $item->subtotal,
                            'tax' => $item->tax,
                            'total' => $item->total,
                            'item_id' => $item->item_id,
                            'item_type' => $item->item_type,
                        ];
                    }),
                ];
            }),
            'requests' => $this->whenLoaded('requests', function() {
                return [
                    'count' => $this->requests->count(),
                    'latest' => $this->requests->first() ? [
                        'id' => $this->requests->first()->id,
                        'status' => $this->requests->first()->status,
                        'created_at' => $this->requests->first()->created_at,
                    ] : null,
                ];
            }),
            'business_id' => $this->business_id,
            'created_by' => $this->created_by,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }

    /**
     * Format currency amount
     */
    private function formatCurrency($amount, $currencyCode): string
    {
        if (!$amount) return '0.00';
        
        $formattedAmount = number_format($amount, 2);
        
        return match(strtoupper($currencyCode)) {
            'USD' => '$' . $formattedAmount,
            'EUR' => '€' . $formattedAmount,
            'GBP' => '£' . $formattedAmount,
            'JPY' => '¥' . number_format($amount, 0),
            default => $currencyCode . ' ' . $formattedAmount
        };
    }
}
