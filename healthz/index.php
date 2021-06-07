<?php

const ENV_WRITE_PERMISSIONS = 'HEALTHZ_WRITE_PERMISSIONS';

/**
 * Return 503 error
 * @param string $msg
 */
function returnError($msg = '')
{
    http_response_code(503);
    echo $msg;
    exit(1);
}

/**
 * Check file permissions
 */
function checkWritePermissions()
{
    $dirs = getenv(ENV_WRITE_PERMISSIONS);
    if (!empty($dirs)) {
        $dirs = explode(';', $dirs);
        foreach ($dirs as $dir) {
            if (!is_dir($dir) || !is_writeable($dir)) {
                returnError("$dir is not writeable.");
            }
        }
    }
}

try {
    checkWritePermissions();
    die('OK');
} catch (\Exception $e) {
    returnError($e->getMessage());
}
