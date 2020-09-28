-- Get the number of subscriptions for each Commuter Rail line
SELECT route,
  count(distinct(user_id))
FROM subscriptions
WHERE type = 'cr'
GROUP BY route;
