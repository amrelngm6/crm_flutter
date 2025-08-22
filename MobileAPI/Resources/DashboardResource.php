<?php

namespace App\Modules\MobileAPI\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DashboardResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'overview' => $this->resource['overview'] ?? [],
            'recent_activities' => $this->resource['recent_activities'] ?? [],
            'upcoming_events' => $this->resource['upcoming_events'] ?? [],
            'performance_metrics' => $this->resource['performance_metrics'] ?? [],
            'quick_actions' => $this->resource['quick_actions'] ?? [],
        ];
    }
}
