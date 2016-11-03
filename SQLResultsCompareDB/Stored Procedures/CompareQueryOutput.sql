CREATE PROCEDURE [dbo].[CreateQueryOutput] @QueryComparisonCategoryName    VARCHAR(50),
                                                  @QueryComparisonSubcategoryName VARCHAR(50) = NULL,--leave NULL if all subcategories are to be included
                                                  @QueryFilter                    VARCHAR(MAX),
                                                  @BCPArguments                   VARCHAR(1000) = '-t , -c -T',
                                                  @QueryOutputDir                 VARCHAR(MAX) = 'C:\QueryComparison\',
                                                  @BCPServerName                  VARCHAR(250) = 'localhost',
                                                  @ComparisonCount                INT OUT
AS
    SET NOCOUNT ON;

    --Prepare the log table for a new execution
    TRUNCATE TABLE QueryComparisonFileOutput;

    DECLARE @QueryComparisonId                INT,
            @BaselineFileName                 NVARCHAR(50),
            @BaselineQuery                    NVARCHAR(MAX),
            @BaselineServerIsMSSQLServerInd   BIT,
            @BaselineServerProviderName       NVARCHAR(128),
            @BaselineServerDataSource         NVARCHAR(4000),
            @BaselineServerProviderString     NVARCHAR(4000),
            @BaselineServerUsername           NVARCHAR(100),
            @BaselineServerPassword           NVARCHAR(100),
            @ComparisonFileName               NVARCHAR(50),
            @ComparisonQuery                  NVARCHAR(MAX),
            @ComparisonServerIsMSSQLServerInd BIT,
            @ComparisonServerProviderName     NVARCHAR(128),
            @ComparisonServerDataSource       NVARCHAR(4000),
            @ComparisonServerProviderString   NVARCHAR(4000),
            @ComparisonServerUsername         NVARCHAR(100),
            @ComparisonServerPassword         NVARCHAR(100),
            @SELECTTemplate                   NVARCHAR(MAX),
            @ORDERBYColumns                   NVARCHAR(MAX);

    SET @ComparisonCount = 0;

    --Create a cursor for query comparisons
    DECLARE ComparisonCursor CURSOR FAST_FORWARD FOR
      SELECT QueryComparisonId,
             REPLACE(bq.QueryName, ' ', '') + '.txt' AS BaselineFileName,
             bq.Query,
             bqrs.IsMSSQLServerInd,
             bqrs.ProviderName,
             bqrs.DataSource,
             bqrs.ProviderString,
             bqrs.Username,
             bqrs.[Password],
             REPLACE(cq.QueryName, ' ', '') + '.txt' AS BaselineFileName,
             cq.Query,
             cqrs.IsMSSQLServerInd,
             cqrs.ProviderName,
             cqrs.DataSource,
             cqrs.ProviderString,
             cqrs.Username,
             cqrs.[Password],
             qc.SELECTTemplate,
             qc.ORDERBYColumns
      FROM   [dbo].QueryComparison qc
             JOIN [dbo].[QueryComparisonSubcategory] qcs
               ON qc.QueryComparisonSubcategoryId = qcs.QueryComparisonSubcategoryId
             JOIN [dbo].[QueryComparisonCategory] qcc
               ON qcs.QueryComparisonCategoryId = qcc.QueryComparisonCategoryId
             JOIN [dbo].[Query] bq
               ON qc.BaselineQueryId = bq.QueryId
             LEFT JOIN [dbo].[RemoteServer] bqrs
                    ON bq.RemoteServerId = bqrs.RemoteServerId
             JOIN Query cq
               ON qc.ComparisonQueryId = cq.QueryId
             LEFT JOIN [dbo].[RemoteServer] cqrs
                    ON cq.RemoteServerId = cqrs.RemoteServerId
      WHERE  ( qcc.QueryComparisonCategoryName = @QueryComparisonCategoryName
                OR @QueryComparisonCategoryName IS NULL )
             AND ( qcs.QueryComparisonSubcategoryName = @QueryComparisonSubcategoryName
                    OR @QueryComparisonSubcategoryName IS NULL )
             AND qc.EnabledInd = 1
             AND qcc.EnabledInd = 1
             AND qcs.EnabledInd = 1;

    OPEN ComparisonCursor;

    FETCH NEXT FROM ComparisonCursor INTO @QueryComparisonId,
                                          @BaselineFileName,
                                          @BaselineQuery,
                                          @BaselineServerIsMSSQLServerInd,
                                          @BaselineServerProviderName,
                                          @BaselineServerDataSource,
                                          @BaselineServerProviderString,
                                          @BaselineServerUsername,
                                          @BaselineServerPassword,
                                          @ComparisonFileName,
                                          @ComparisonQuery,
                                          @ComparisonServerIsMSSQLServerInd,
                                          @ComparisonServerProviderName,
                                          @ComparisonServerDataSource,
                                          @ComparisonServerProviderString,
                                          @ComparisonServerUsername,
                                          @ComparisonServerPassword,
                                          @SELECTTemplate,
                                          @ORDERBYColumns;

    WHILE @@FETCH_STATUS = 0
      BEGIN
          DECLARE @QueryCount TINYINT = 0

          --There are two queries to execute. The first pass is the baseline and the second is the comparison
          WHILE @QueryCount < 2
            BEGIN
                DECLARE @Query                  NVARCHAR(MAX) = IIF(@QueryCount = 0, @BaselineQuery, @ComparisonQuery),
                        @ServerIsMSSQLServerInd BIT = IIF(@QueryCount = 0, @BaselineServerIsMSSQLServerInd, @ComparisonServerIsMSSQLServerInd),
                        @ServerProviderName     NVARCHAR(128) = IIF(@QueryCount = 0, @BaselineServerProviderName, @ComparisonServerProviderName),
                        @ServerDataSource       NVARCHAR(4000) = IIF(@QueryCount = 0, @BaselineServerDataSource, @ComparisonServerDataSource),
                        @ServerProviderString   NVARCHAR(4000) = IIF(@QueryCount = 0, @BaselineServerProviderString, @ComparisonServerProviderString),
                        @ServerUsername         NVARCHAR(100) = IIF(@QueryCount = 0, @BaselineServerUsername, @ComparisonServerUsername),
                        @ServerPassword         NVARCHAR(100) = IIF(@QueryCount = 0, @BaselineServerPassword, @ComparisonServerPassword),
                        @FileName               NVARCHAR(50) = IIF(@QueryCount = 0, @BaselineFileName, @ComparisonFileName);

                --Create outer SELECT clause based on metadata
                DECLARE @SQLOuterSELECT NVARCHAR(MAX) = ( 'SELECT * ' );

                --Create outer WHERE clause based on metadata
                DECLARE @SQLOuterWHERE NVARCHAR(MAX) = IIF(NULLIF(RTRIM(LTRIM(@QueryFilter)), '') IS NOT NULL, 'WHERE ' + @QueryFilter, '');

                --Create SQL statement to be executed
                DECLARE @SQLStatement NVARCHAR(MAX) = ( @SQLOuterSELECT + ' FROM (' + @Query + ') t '
                    + @SQLOuterWHERE + ' ORDER BY '
                    + @ORDERBYColumns );

                --Drop temp table if it already exists
                IF OBJECT_ID('tempdb.dbo.##Temp') IS NOT NULL
                  DROP TABLE ##Temp;

                --Create temp table with structure based on @SELECTTemplate
                DECLARE @TempTableStructureSQL NVARCHAR(MAX) = 'SELECT * INTO ##Temp FROM ('
                  + @SELECTTemplate + ') t'; --Using global temp table so that BCP session will have access

                EXEC master.dbo.sp_executesql
                  @TempTableStructureSQL;

				--TODO: Enhance to be able to skip the linked server/temp table process if the target query server is a SQL Server by executing the query directly through BCP.

                --Create the temp linked server
                DECLARE @TempLinkedServerName NVARCHAR(100) = N'TempCompare';

                EXEC master.dbo.sp_addlinkedserver @server = @TempLinkedServerName, @srvproduct=N'', @provider=@ServerProviderName, @datasrc=@ServerDataSource, @provstr=@ServerProviderString;
                EXEC master.dbo.sp_serveroption @server=N'TempCompare', @optname=N'rpc', @optvalue=N'true';
                EXEC master.dbo.sp_serveroption @server=N'TempCompare', @optname=N'rpc out', @optvalue=N'true';

                IF @ServerUsername IS NOT NULL
                  EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=@TempLinkedServerName, @useself=N'False', @locallogin=NULL, @rmtuser=@ServerUsername, @rmtpassword=@ServerPassword;

                INSERT INTO ##Temp
                EXEC (@SQLStatement) AT TempCompare;

                EXEC master.dbo.SP_DROPSERVER @server=N'TempCompare', @droplogins='droplogins';

                DECLARE @BCPCommand VARCHAR(8000);

                SET @BCPCommand = 'bcp "SELECT * FROM ##Temp'
                                  + '" queryout "' + @QueryOutputDir + @FileName
                                  + '" ' + @BCPArguments + ' -S ' + @BCPServerName

                EXEC xp_cmdshell @BCPCommand;

                --Drop temp table if it already exists
                IF OBJECT_ID('tempdb.dbo.##Temp') IS NOT NULL
                  DROP TABLE ##Temp;

                SET @QueryCount = @QueryCount + 1
            END

          --Log the two files so that we can reference them later for the actual diff/compare
          INSERT INTO QueryComparisonFileOutput
                      (QueryComparisonId,
                       BaselineFileName,
                       ComparisonFileName)
          VALUES      (@QueryComparisonId,
                       @QueryOutputDir + @BaselineFileName,
                       @QueryOutputDir + @ComparisonFileName);

          SET @ComparisonCount = @ComparisonCount + 1;

          FETCH NEXT FROM ComparisonCursor INTO @QueryComparisonId,
                                                @BaselineFileName,
                                                @BaselineQuery,
                                                @BaselineServerIsMSSQLServerInd,
                                                @BaselineServerProviderName,
                                                @BaselineServerDataSource,
                                                @BaselineServerProviderString,
                                                @BaselineServerUsername,
                                                @BaselineServerPassword,
                                                @ComparisonFileName,
                                                @ComparisonQuery,
                                                @ComparisonServerIsMSSQLServerInd,
                                                @ComparisonServerProviderName,
                                                @ComparisonServerDataSource,
                                                @ComparisonServerProviderString,
                                                @ComparisonServerUsername,
                                                @ComparisonServerPassword,
                                                @SELECTTemplate,
                                                @ORDERBYColumns;
      END

    CLOSE ComparisonCursor;

    DEALLOCATE ComparisonCursor;

    RETURN 0 
