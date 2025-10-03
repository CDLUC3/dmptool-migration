AUDIT (
  name assert_row_count,
  dialect mysql
);

WITH dst_count AS (
  SELECT count(*) as count FROM @this_model
),
src_count AS (
  SELECT count(*) as count FROM dmp.@dmp_table
)

SELECT
  s.count as src_rows,
  d.count as dst_rows
FROM src_count AS s, dst_count AS d
WHERE s.count <> d.count;