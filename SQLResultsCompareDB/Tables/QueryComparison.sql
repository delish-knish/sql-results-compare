CREATE TABLE [dbo].[QueryComparison] (
    [QueryComparisonId]            INT           IDENTITY (1, 1) NOT NULL,
    [BaselineQueryId]              INT           NOT NULL,
    [ComparisonQueryId]            INT           NOT NULL,
    [ComparisonDescription]        VARCHAR (255) CONSTRAINT [DF_QueryComparison_ComparisonDescription] DEFAULT ('No description given.') NOT NULL,
    [EnabledInd]                   BIT           CONSTRAINT [DF_QueryComparison_EnabledInd] DEFAULT ((1)) NOT NULL,
    [QueryComparisonSubcategoryId] INT           NOT NULL,
    [SELECTTemplate]               VARCHAR (MAX) NOT NULL,
    [ORDERBYColumns]               VARCHAR (MAX) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_QueryComparison_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedUser]                  VARCHAR (100) CONSTRAINT [DF_QueryComparison_CreatedUser] DEFAULT (suser_sname()) NOT NULL,
    [LastUpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_QueryComparison_LastUpdatedDate] DEFAULT (getdate()) NOT NULL,
    [LastUpdatedUser]              VARCHAR (100) CONSTRAINT [DF_QueryComparison_LastUpdatedUser] DEFAULT (suser_sname()) NOT NULL,
    CONSTRAINT [PK_QueryComparison] PRIMARY KEY CLUSTERED ([QueryComparisonId] ASC),
    CONSTRAINT [FK_QueryComparison_QueryBaseline] FOREIGN KEY ([BaselineQueryId]) REFERENCES [dbo].[Query] ([QueryId]),
    CONSTRAINT [FK_QueryComparison_QueryComparison] FOREIGN KEY ([ComparisonQueryId]) REFERENCES [dbo].[Query] ([QueryId]),
    CONSTRAINT [FK_QueryComparison_QueryComparisonSubcategory] FOREIGN KEY ([QueryComparisonSubcategoryId]) REFERENCES [dbo].[QueryComparisonSubcategory] ([QueryComparisonSubcategoryId]),
    CONSTRAINT [UK_QueryComparison_BaselineQueryId_ComparisonQueryId] UNIQUE NONCLUSTERED ([BaselineQueryId] ASC, [ComparisonQueryId] ASC)
);

