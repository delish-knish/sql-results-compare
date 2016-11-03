CREATE PROCEDURE [dbo].[GetFilePairs]
AS
  BEGIN
      SELECT
        o.BaselineFileName
       ,o.ComparisonFileName
       ,c.ComparisonDescription
      FROM
        QueryComparisonFileOutput o
        JOIN QueryComparison c
          ON o.QueryComparisonId = c.QueryComparisonId
  END 
