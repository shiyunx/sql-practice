/*
https://leetcode.com/problems/find-emotionally-consistent-users/description/
3808. Find Emotionally Consistent Users

Table: reactions

+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| user_id      | int     |
| content_id   | int     |
| reaction     | varchar |
+--------------+---------+
(user_id, content_id) is the primary key (unique value) for this table.
Each row represents a reaction given by a user to a piece of content.
Write a solution to identify emotionally consistent users based on the following requirements:

For each user, count the total number of reactions they have given.
Only include users who have reacted to at least 5 different content items.
A user is considered emotionally consistent if at least 60% of their reactions are of the same type.
Return the result table ordered by reaction_ratio in descending order and then by user_id in ascending order.

Note:

reaction_ratio should be rounded to 2 decimal places
The result format is in the following example.

 

Example:

Input:

reactions table:

+---------+------------+----------+
| user_id | content_id | reaction |
+---------+------------+----------+
| 1       | 101        | like     |
| 1       | 102        | like     |
| 1       | 103        | like     |
| 1       | 104        | wow      |
| 1       | 105        | like     |
| 2       | 201        | like     |
| 2       | 202        | wow      |
| 2       | 203        | sad      |
| 2       | 204        | like     |
| 2       | 205        | wow      |
| 3       | 301        | love     |
| 3       | 302        | love     |
| 3       | 303        | love     |
| 3       | 304        | love     |
| 3       | 305        | love     |
+---------+------------+----------+
Output:

+---------+-------------------+----------------+
| user_id | dominant_reaction | reaction_ratio |
+---------+-------------------+----------------+
| 3       | love              | 1.00           |
| 1       | like              | 0.80           |
+---------+-------------------+----------------+
Explanation:

User 1:
Total reactions = 5
like appears 4 times
reaction_ratio = 4 / 5 = 0.80
Meets the 60% consistency requirement
User 2:
Total reactions = 5
Most frequent reaction appears only 2 times
reaction_ratio = 2 / 5 = 0.40
Does not meet the consistency requirement
User 3:
Total reactions = 5
'love' appears 5 times
reaction_ratio = 5 / 5 = 1.00
Meets the consistency requirement
The Results table is ordered by reaction_ratio in descending order, then by user_id in ascending order.

*/

WITH user_counts AS (
    SELECT
        user_id,
        COUNT(*) AS total_reactions
    FROM reactions
    GROUP BY user_id
),

reaction_freq AS (
    SELECT
        user_id,
        reaction,
        COUNT(*) AS reaction_count
    FROM reactions
    GROUP BY user_id, reaction
),

ranked AS (
    SELECT
        user_id,
        reaction,
        reaction_count,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY reaction_count DESC, reaction
        ) AS rn
    FROM reaction_freq
),

dominant AS (
    SELECT
        r.user_id,
        r.reaction AS dominant_reaction,
        r.reaction_count,
        uc.total_reactions,
        ROUND(1.0 * r.reaction_count / uc.total_reactions, 2) AS reaction_ratio
    FROM ranked r
    JOIN user_counts uc
        ON r.user_id = uc.user_id
    WHERE r.rn = 1
)

SELECT
    user_id,
    dominant_reaction,
    reaction_ratio
FROM dominant
WHERE total_reactions >= 5
  AND reaction_ratio >= 0.60
ORDER BY
    reaction_ratio DESC,
    user_id ASC;
    