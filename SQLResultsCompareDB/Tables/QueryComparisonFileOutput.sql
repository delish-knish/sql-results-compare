CREATE TABLE [dbo].[QueryComparisonFileOutput] (
    [QueryComparisonFileOutputId] INT           IDENTITY (1, 1) NOT NULL,
    [QueryComparisonId]           INT           NOT NULL,
    [BaselineFileName]            VARCHAR (250) NOT NULL,
    [ComparisonFileName]          VARCHAR (250) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_QueryComparisonFileOutput_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedUser]                 VARCHAR (100) CONSTRAINT [DF_QueryComparisonFileOutput_CreatedUser] DEFAULT (suser_sname()) NOT NULL,
    CONSTRAINT [PK_QueryComparisonFileOutput] PRIMARY KEY CLUSTERED ([QueryComparisonFileOutputId] ASC),
    CONSTRAINT [UK_QueryComparisonFileOutput_QueryComparisonId] UNIQUE NONCLUSTERED ([QueryComparisonId] ASC)
);

