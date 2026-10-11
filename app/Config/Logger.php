```php
<?php

namespace Config;

use CodeIgniter\Config\BaseConfig;
use CodeIgniter\Log\Handlers\FileHandler;
use CodeIgniter\Log\Handlers\ErrorlogHandler;

class Logger extends BaseConfig
{
    /**
     * Log threshold.
     * Production: log errors and more severe messages.
     * Development: log all message levels.
     */
    public $threshold = (ENVIRONMENT === 'production') ? 4 : 9;

    /**
     * Date format for log entries.
     */
    public string $dateFormat = 'Y-m-d H:i:s';

    /**
     * Log handlers.
     */
    public array $handlers = [
        ErrorlogHandler::class => [
            'handles' => [
                'critical',
                'alert',
                'emergency',
                'debug',
                'error',
                'info',
                'notice',
                'warning',
            ],
            'messageType' => 0,
        ],

        FileHandler::class => [
            'handles' => [
                'critical',
                'alert',
                'emergency',
                'debug',
                'error',
                'info',
                'notice',
                'warning',
            ],
            'fileExtension' => '',
            'filePermissions' => 0644,
            'path' => '',
        ],
    ];
}
```