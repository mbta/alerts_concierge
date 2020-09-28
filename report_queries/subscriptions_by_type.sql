-- Get the number of subscriptions for each mode and accessibility
SELECT type,
  count(distinct(user_id))
FROM subscriptions
GROUP BY type;
