
https://leetcode.com/problems/find-invalid-ip-addresses/description/
3451. Find Invalid IP Addresses

WITH parsed AS (
    SELECT
        ip,
        log_id,

        SUBSTRING_INDEX(ip, '.', 1) AS o1,
        SUBSTRING_INDEX(SUBSTRING_INDEX(ip, '.', 2), '.', -1) AS o2,
        SUBSTRING_INDEX(SUBSTRING_INDEX(ip, '.', 3), '.', -1) AS o3,
        SUBSTRING_INDEX(ip, '.', -1) AS o4,

        -- count number of dots + 1 approximation using length
        (LENGTH(ip) - LENGTH(REPLACE(ip, '.', '')) + 1) AS octet_count
    FROM logs
),

flagged AS (
    SELECT
        ip,
        CASE
            WHEN octet_count <> 4 THEN 1
            WHEN o1 NOT REGEXP '^[0-9]+$' OR CAST(o1 AS UNSIGNED) > 255 OR (o1 REGEXP '^0[0-9]+$') THEN 1
            WHEN o2 NOT REGEXP '^[0-9]+$' OR CAST(o2 AS UNSIGNED) > 255 OR (o2 REGEXP '^0[0-9]+$') THEN 1
            WHEN o3 NOT REGEXP '^[0-9]+$' OR CAST(o3 AS UNSIGNED) > 255 OR (o3 REGEXP '^0[0-9]+$') THEN 1
            WHEN o4 NOT REGEXP '^[0-9]+$' OR CAST(o4 AS UNSIGNED) > 255 OR (o4 REGEXP '^0[0-9]+$') THEN 1
            ELSE 0
        END AS is_invalid
    FROM parsed
)

SELECT
    ip,
    COUNT(*) AS invalid_count
FROM flagged
WHERE is_invalid = 1
GROUP BY ip
ORDER BY invalid_count DESC, ip DESC;